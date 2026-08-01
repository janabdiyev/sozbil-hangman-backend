from django.http import HttpResponse, JsonResponse
from django.db.models import Sum, Count, Q
from django.db import transaction
from django.utils import timezone
from django.conf import settings
from django.views.decorators.http import require_http_methods
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
import random
import os
from datetime import date, timedelta

# Group chat keeps only the most recent N messages; older ones are pruned on send.
CHAT_HISTORY_LIMIT = 40

from .models import (
    HangmanWord, Player, GameSession, DailyWord,
    PuzzleImage, ExternalApp, Achievement, PlayerAchievement, ChatMessage
)
from .serializers import (
    WordSerializer, PlayerSerializer, PlayerCreateSerializer, PlayerUpdateSerializer,
    GameSessionCreateSerializer, LeaderboardEntrySerializer,
    DailyWordSerializer, PuzzleImageSerializer, ExternalAppSerializer,
    AchievementSerializer, ChatMessageSerializer, ChatMessageCreateSerializer
)


# ── Homepage ──────────────────────────────────────────────────────────────────

@require_http_methods(["GET"])
def index(request):
    html = """<!DOCTYPE html>
<html lang="tk">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sözbil Platform API</title>
    <style>
        body { font-family: -apple-system, sans-serif; max-width: 700px; margin: 60px auto; padding: 20px; color: #1a1a1a; }
        h1 { font-size: 28px; } code { background: #f4f4f4; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
        ul { line-height: 2; }
    </style>
</head>
<body>
    <h1>🎮 Sözbil Platform API</h1>
    <p>Türkmen oýun platformasynyň API hyzmaty.</p>
    <h2>Endpoints</h2>
    <ul>
        <li><code>GET  /api/word/</code> — Random word</li>
        <li><code>GET  /api/words/</code> — All active words</li>
        <li><code>GET  /api/daily/</code> — Today's daily word</li>
        <li><code>POST /api/player/register/</code> — Register player</li>
        <li><code>GET  /api/player/&lt;uuid&gt;/</code> — Player profile</li>
        <li><code>PUT  /api/player/&lt;uuid&gt;/</code> — Update player</li>
        <li><code>POST /api/score/</code> — Submit game result</li>
        <li><code>GET  /api/leaderboard/</code> — Global leaderboard</li>
        <li><code>GET  /api/leaderboard/?filter=weekly</code> — Weekly leaderboard</li>
        <li><code>GET  /api/puzzles/&lt;game_type&gt;/</code> — Puzzle images</li>
        <li><code>GET  /api/apps/</code> — External apps (Miclab, Dilbil)</li>
        <li><code>GET  /api/achievements/</code> — All achievements</li>
        <li><code>GET  /api/chat/</code> — Get latest messages</li>
        <li><code>POST /api/chat/</code> — Send message</li>
        <li><code>GET  /health/</code> — Health check</li>
    </ul>
    <hr><p><small>© 2026 Can Abdiyev · Sözbil</small></p>
</body>
</html>"""
    return HttpResponse(html, content_type='text/html')


# ── Words ─────────────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_random_word(request):
    """Legacy endpoint — kept for existing Android app compatibility.

    ?lang= is optional and defaults to 'tk' — the legacy Android app and any
    older Flutter build never send it, so they keep getting exactly the
    Turkmen words they always have. Jellad (hangman) is the only screen that
    currently sends a real value here (see the 4-language rollout note on
    HangmanWord.language in models.py).
    """
    lang = request.query_params.get('lang', 'tk')
    words = list(
        HangmanWord.objects.filter(is_active=True, language=lang)
        .values('word', 'hint', 'difficulty')
    )
    if not words:
        return Response({'error': 'No words available'}, status=status.HTTP_404_NOT_FOUND)
    return Response(random.choice(words))


@api_view(['GET'])
def api_all_words(request):
    """All active words — used by crossword generator on client.

    ?lang= defaults to 'tk' for the same backward-compatibility reason as
    api_random_word above — Krosword and Söz Zynjyry don't pass this param
    and must keep seeing only the Turkmen pool.
    """
    lang = request.query_params.get('lang', 'tk')
    words = HangmanWord.objects.filter(is_active=True, language=lang)
    serializer = WordSerializer(words, many=True)
    return Response(serializer.data)


# ── Daily word ────────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_daily_word(request):
    today = date.today()
    daily = DailyWord.objects.filter(date=today).select_related('word').first()

    if not daily:
        # Auto-assign one if missing
        used_ids = DailyWord.objects.values_list('word_id', flat=True)
        available = HangmanWord.objects.filter(is_active=True).exclude(id__in=used_ids)
        if not available.exists():
            available = HangmanWord.objects.filter(is_active=True)
        word = random.choice(list(available))
        daily = DailyWord.objects.create(word=word, date=today)

    serializer = DailyWordSerializer(daily)
    return Response(serializer.data)


# ── Player ────────────────────────────────────────────────────────────────────

@api_view(['POST'])
def api_player_register(request):
    serializer = PlayerCreateSerializer(data=request.data)
    if serializer.is_valid():
        player = serializer.save()
        return Response(PlayerSerializer(player).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT'])
def api_player_detail(request, player_uuid):
    try:
        player = Player.objects.prefetch_related('achievements__achievement').get(uuid=player_uuid)
    except Player.DoesNotExist:
        return Response({'error': 'Player not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        return Response(PlayerSerializer(player).data)

    serializer = PlayerUpdateSerializer(player, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(PlayerSerializer(player).data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Score submission ──────────────────────────────────────────────────────────

@api_view(['POST'])
def api_submit_score(request):
    serializer = GameSessionCreateSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data

    try:
        player = Player.objects.get(uuid=data['player_uuid'])
    except Player.DoesNotExist:
        return Response({'error': 'Player not found'}, status=status.HTTP_404_NOT_FOUND)

    word = None
    difficulty = 'medium'
    if data.get('word_id'):
        word = HangmanWord.objects.filter(id=data['word_id']).first()
        if word:
            difficulty = word.difficulty

    score = GameSession.calculate_score(data['won'], data['wrong_guesses'], difficulty)
    xp_gained = score // 10
    # Coins reward: a win is worth roughly a fifth of its score in coins (min 1).
    coins_gained = max(1, score // 5) if data['won'] else 0

    with transaction.atomic():
        session = GameSession.objects.create(
            player=player,
            game_type=data['game_type'],
            word=word,
            won=data['won'],
            wrong_guesses=data['wrong_guesses'],
            score=score,
        )

        player.xp += xp_gained
        player.coins += coins_gained
        today = date.today()

        if player.last_streak_date == today - timedelta(days=1):
            player.streak_days += 1
        elif player.last_streak_date != today:
            player.streak_days = 1 if data['won'] else 0

        if player.streak_days > player.longest_streak:
            player.longest_streak = player.streak_days

        player.last_active = today
        if data['won']:
            player.last_streak_date = today

        player.update_level()
        player.save()

        _check_and_award_achievements(player)

    return Response({
        'score': score,
        'xp_gained': xp_gained,
        'total_xp': player.xp,
        'coins_gained': coins_gained,
        'total_coins': player.coins,
        'level': player.level,
        'streak_days': player.streak_days,
    }, status=status.HTTP_201_CREATED)


def _check_and_award_achievements(player):
    """Check all active achievements and award any newly earned ones."""
    already_earned = set(
        PlayerAchievement.objects.filter(player=player)
        .values_list('achievement_id', flat=True)
    )
    achievements = Achievement.objects.filter(is_active=True).exclude(id__in=already_earned)

    for ach in achievements:
        earned = False
        if ach.condition_type == 'streak_days' and player.streak_days >= ach.condition_value:
            earned = True
        elif ach.condition_type == 'total_xp' and player.xp >= ach.condition_value:
            earned = True
        elif ach.condition_type == 'games_won':
            won_count = GameSession.objects.filter(player=player, won=True).count()
            earned = won_count >= ach.condition_value
        elif ach.condition_type == 'perfect_games':
            perfect = GameSession.objects.filter(player=player, won=True, wrong_guesses=0).count()
            earned = perfect >= ach.condition_value
        elif ach.condition_type == 'daily_wins':
            daily_wins = GameSession.objects.filter(player=player, game_type='gunluk_soz', won=True).count()
            earned = daily_wins >= ach.condition_value

        if earned:
            PlayerAchievement.objects.create(player=player, achievement=ach)
            player.xp += ach.xp_reward
            player.save(update_fields=['xp'])


# ── Leaderboard ───────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_leaderboard(request):
    filter_type = request.query_params.get('filter', 'alltime')
    location = request.query_params.get('location', '')

    sessions_qs = GameSession.objects.filter(won=True)

    if filter_type == 'weekly':
        week_start = date.today() - timedelta(days=7)
        sessions_qs = sessions_qs.filter(played_at__date__gte=week_start)

    players_qs = Player.objects.annotate(
        total_score=Sum('sessions__score', filter=Q(sessions__in=sessions_qs), default=0),
        games_won=Count('sessions', filter=Q(sessions__won=True, sessions__in=sessions_qs)),
    ).order_by('-total_score')

    if location:
        players_qs = players_qs.filter(location__icontains=location)

    avatar_map = dict(Player.AVATAR_CHOICES)
    level_map = dict(Player.LEVEL_CHOICES)

    results = []
    for rank, p in enumerate(players_qs[:100], start=1):
        results.append({
            'rank': rank,
            'uuid': str(p.uuid),
            'display_name': p.display_name,
            'location': p.location,
            'avatar_key': p.avatar_key,
            'avatar_emoji': avatar_map.get(p.avatar_key, '🦅'),
            'total_score': p.total_score or 0,
            'games_won': p.games_won or 0,
            'streak_days': p.streak_days,
            'level': level_map.get(p.level, p.level),
        })

    return Response(results)


# ── Puzzle images ─────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_puzzle_images(request, game_type):
    images = PuzzleImage.objects.filter(game_type=game_type, is_active=True)
    serializer = PuzzleImageSerializer(images, many=True, context={'request': request})
    return Response(serializer.data)


# ── External apps ─────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_external_apps(request):
    apps = ExternalApp.objects.filter(is_active=True)
    serializer = ExternalAppSerializer(apps, many=True, context={'request': request})
    return Response(serializer.data)


# ── Achievements ──────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_achievements(request):
    achievements = Achievement.objects.filter(is_active=True)
    serializer = AchievementSerializer(achievements, many=True)
    return Response(serializer.data)


# ── Utility ───────────────────────────────────────────────────────────────────

@api_view(['GET'])
def api_stats(request):
    return Response({
        'total_words': HangmanWord.objects.filter(is_active=True).count(),
        'total_players': Player.objects.count(),
        'total_sessions': GameSession.objects.count(),
    })


# ── Chat ──────────────────────────────────────────────────────────────────────

@api_view(['GET', 'POST'])
def api_chat(request):
    if request.method == 'GET':
        # Return latest 40 messages, oldest first for display
        before_id = request.query_params.get('before_id')
        qs = ChatMessage.objects.select_related('player')
        if before_id:
            qs = qs.filter(id__lt=before_id)
        messages = list(qs[:CHAT_HISTORY_LIMIT])
        messages.reverse()
        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)

    # POST — send a new message
    serializer = ChatMessageCreateSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data
    try:
        player = Player.objects.get(uuid=data['player_uuid'])
    except Player.DoesNotExist:
        return Response({'error': 'Player not found'}, status=status.HTTP_404_NOT_FOUND)

    msg = ChatMessage.objects.create(player=player, message=data['message'].strip())

    # Keep only the most recent CHAT_HISTORY_LIMIT messages; delete older ones.
    keep_ids = list(
        ChatMessage.objects.order_by('-created_at', '-id')
        .values_list('id', flat=True)[:CHAT_HISTORY_LIMIT]
    )
    ChatMessage.objects.exclude(id__in=keep_ids).delete()

    return Response(ChatMessageSerializer(msg).data, status=status.HTTP_201_CREATED)


@require_http_methods(["GET"])
def health_check(request):
    return JsonResponse({'status': 'ok', 'service': 'Sozbil Platform API'})


@require_http_methods(["GET"])
def privacy_policy(request):
    project_root = settings.BASE_DIR.parent
    file_path = os.path.join(project_root, 'privacy_policy.html')
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return HttpResponse(f.read(), content_type='text/html')
    except FileNotFoundError:
        return JsonResponse({'error': 'Privacy policy not found'}, status=404)


@require_http_methods(["GET"])
def support_page(request):
    project_root = settings.BASE_DIR.parent
    file_path = os.path.join(project_root, 'support.html')
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return HttpResponse(f.read(), content_type='text/html')
    except FileNotFoundError:
        return JsonResponse({'error': 'Support page not found'}, status=404)
