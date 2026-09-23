"""Platform features; no game scoring or rules are changed here."""
from datetime import datetime, timedelta, timezone as dt_timezone
from uuid import UUID
import hashlib
import secrets
from django.db import transaction
from django.db.models import Sum, Count
from django.utils import timezone
from rest_framework.decorators import api_view
from rest_framework.exceptions import AuthenticationFailed, PermissionDenied, ValidationError
from rest_framework.response import Response
from .models import Player, GameSession, ChatMessage, CompetitionPeriod, CompetitionReward, GameLaunch, GamePlayBaseline
from .serializers import ChatMessageSerializer, ChatMessageCreateSerializer
from .countries import COUNTRIES

# Explicit release order, separate from card order and popularity.
GAME_ORDER = ['jellad', 'soz_zynjyry', 'yatkeslik', 'krosword', 'suysurme',
              'mina', 'zehin', 'puzzle', 'smash_rings', 'hanlyk', 'tilki',
              'lands_of_hanlyk', 'bazar']
PRIZES = {1: (10, 1000), 2: (7, 700), 3: (7, 700)}


def bounds(kind, now=None):
    now = (now or timezone.now()).astimezone(dt_timezone.utc)
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    if kind == 'weekly':
        start -= timedelta(days=start.weekday())
        return start, start + timedelta(days=7)
    if kind != 'monthly':
        raise ValidationError({'filter': 'Use weekly or monthly.'})
    start = start.replace(day=1)
    end = (start + timedelta(days=32)).replace(day=1)
    return start, end


def ensure_periods(now=None, lock=False):
    for kind in ('weekly', 'monthly'):
        start, end = bounds(kind, now)
        period, _ = CompetitionPeriod.objects.get_or_create(kind=kind, start=start, defaults={'end': end})
        if lock:
            # A boundary settlement waits for all in-flight score writes.
            CompetitionPeriod.objects.select_for_update().get(pk=period.pk)


def ranked(start, end):
    return (GameSession.objects.filter(won=True, played_at__gte=start, played_at__lt=end)
            .values('player_id').annotate(total_score=Sum('score'), games_won=Count('id'))
            .filter(total_score__gt=0).order_by('-total_score', 'player_id')[:10])


def settle(now=None):
    now = now or timezone.now()
    ensure_periods(now)
    for pk in CompetitionPeriod.objects.filter(end__lte=now, settled_at__isnull=True).values_list('pk', flat=True):
        with transaction.atomic():
            period = CompetitionPeriod.objects.select_for_update().get(pk=pk)
            if period.settled_at:
                continue
            for rank, entry in enumerate(ranked(period.start, period.end), 1):
                gems, coins = PRIZES.get(rank, (5, 500))
                CompetitionReward.objects.get_or_create(period=period, player_id=entry['player_id'],
                    defaults={'rank': rank, 'score': entry['total_score'], 'gems': gems, 'coins': coins})
            period.settled_at = now
            period.save(update_fields=['settled_at'])


def require_player(request):
    try:
        player = Player.objects.get(uuid=UUID(request.headers.get('X-Player-UUID', '')))
    except (ValueError, Player.DoesNotExist):
        raise AuthenticationFailed('A registered device is required.')
    token = request.headers.get('X-Platform-Token', '')
    if not token or not secrets.compare_digest(hashlib.sha256(token.encode()).hexdigest(), player.platform_token_hash):
        raise AuthenticationFailed('Device credential is invalid.')
    return player


@api_view(['POST'])
def platform_session(request):
    # Existing passwordless installs prove possession of their stored UUID once.
    # Never return this UUID in a public leaderboard or message response.
    try:
        uid = UUID(request.data.get('player_uuid', ''))
    except (ValueError, TypeError, AttributeError):
        raise ValidationError('Invalid player UUID.')
    token = request.data.get('token', '')
    if not isinstance(token, str) or not 32 <= len(token) <= 128:
        raise ValidationError('Invalid device credential.')
    with transaction.atomic():
        try:
            player = Player.objects.select_for_update().get(uuid=uid)
        except Player.DoesNotExist:
            raise AuthenticationFailed('Register first.')
        if player.platform_token_hash:
            if not secrets.compare_digest(hashlib.sha256(token.encode()).hexdigest(), player.platform_token_hash):
                raise AuthenticationFailed('Device already enrolled.')
        else:
            player.platform_token_hash = hashlib.sha256(token.encode()).hexdigest()
            player.save(update_fields=['platform_token_hash'])
    return Response({'ready': True})


def leaderboard_response(request):
    kind = request.query_params.get('filter', 'weekly')
    start, end = bounds(kind)
    settle()
    viewer = require_player(request) if request.headers.get('X-Platform-Token') else None
    results = []
    for rank, row in enumerate(ranked(start, end), 1):
        player = Player.objects.get(pk=row['player_id'])
        gems, coins = PRIZES.get(rank, (5, 500))
        results.append({'rank': rank, 'display_name': player.display_name,
            'is_me': viewer is not None and player.pk == viewer.pk,
            'country_code': player.country_code, 'avatar_key': player.avatar_key,
            'avatar_emoji': dict(Player.AVATAR_CHOICES).get(player.avatar_key, '🦅'),
            'total_score': row['total_score'], 'games_won': row['games_won'],
            'prize_gems': gems, 'prize_coins': coins,
            'period_start': start, 'period_end': end})
    return Response(results)


def chat_response(request):
    player = require_player(request)
    if player.country_code not in COUNTRIES:
        raise PermissionDenied('Choose your country in your profile first.')
    cutoff = timezone.now() - timedelta(days=7)
    ChatMessage.objects.filter(created_at__lte=cutoff).delete()
    if request.method == 'GET':
        qs = ChatMessage.objects.filter(country_code=player.country_code, created_at__gt=cutoff).select_related('player')
        before = request.query_params.get('before_id')
        if before:
            try:
                before = int(before)
                if before <= 0: raise ValueError()
            except ValueError:
                raise ValidationError({'before_id': 'Must be a positive integer.'})
            qs = qs.filter(id__lt=before)
        messages = list(qs.order_by('-id')[:60])
        return Response(ChatMessageSerializer(messages[::-1], many=True, context={'player_id': player.pk}).data)
    serializer = ChatMessageCreateSerializer(data={'message': request.data.get('message', ''), 'player_uuid': str(player.uuid)})
    serializer.is_valid(raise_exception=True)
    msg = ChatMessage.objects.create(player=player, country_code=player.country_code,
        message=serializer.validated_data['message'].strip())
    return Response(ChatMessageSerializer(msg, context={'player_id': player.pk}).data, status=201)


@api_view(['GET'])
def game_catalog(request):
    launches = dict(GameLaunch.objects.values('game_type').annotate(n=Count('id')).values_list('game_type', 'n'))
    baseline = dict(GamePlayBaseline.objects.values_list('game_type', 'count'))
    return Response([{'game_type': game, 'release_order': i, 'play_count': launches.get(game, 0) + baseline.get(game, 0)}
                     for i, game in enumerate(GAME_ORDER)])


@api_view(['POST'])
def game_launch(request):
    player = require_player(request)
    game = request.data.get('game_type')
    if game not in GAME_ORDER: raise ValidationError('Unknown game.')
    try:
        launch_id = UUID(request.data.get('launch_id', ''))
    except (ValueError, TypeError, AttributeError):
        raise ValidationError('Invalid launch ID.')
    GameLaunch.objects.get_or_create(id=launch_id, defaults={'player': player, 'game_type': game})
    return Response({'recorded': True})


def reward_json(reward):
    return {'id': reward.pk, 'period': reward.period.kind, 'period_start': reward.period.start,
            'rank': reward.rank, 'gems': reward.gems, 'coins': reward.coins}


@api_view(['GET'])
def rewards(request):
    player = require_player(request)
    settle()
    return Response([reward_json(r) for r in CompetitionReward.objects.filter(player=player,
        acknowledged_at__isnull=True).select_related('period').order_by('pk')])


@api_view(['POST'])
def claim_reward(request, reward_id):
    player = require_player(request)
    with transaction.atomic():
        reward = CompetitionReward.objects.select_for_update().filter(pk=reward_id, player=player).first()
        if reward is None or reward.acknowledged_at:
            raise ValidationError('Reward is unavailable.')
        if reward.claimed_at is None:
            reward.claimed_at = timezone.now()
            reward.save(update_fields=['claimed_at'])
    return Response(reward_json(reward))


@api_view(['POST'])
def ack_reward(request, reward_id):
    player = require_player(request)
    count = CompetitionReward.objects.filter(pk=reward_id, player=player,
        claimed_at__isnull=False).update(acknowledged_at=timezone.now())
    if not count: raise ValidationError('Claim the reward first.')
    return Response({'acknowledged': True})
