"""Platform v2 (2026-10-14): social — chat moderation, blocking, friends,
challenge links, and the files that make https links open the app.

Chat moderation is what App Store guideline 1.2 asks of any app with
user-generated content: a filter for objectionable material, a way to
report, a way to block, and a way for the developer to act (Django admin:
ChatReport, ChatMessage.hidden, Player.chat_hidden).
"""
import json
import os
import re
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.db.models import Sum, Count
from django.http import HttpResponse, JsonResponse
from django.utils import timezone
from django.utils.html import escape
from rest_framework.decorators import api_view
from rest_framework.exceptions import ValidationError, PermissionDenied
from rest_framework.response import Response

from .accounts import ensure_friend_code, FRIEND_CODE_ALPHABET
from .models import (Player, ChatMessage, ChatReport, PlayerBlock, Friendship, Challenge,
                     ChallengeResult, GameSession)
from .platform import require_player, bounds

REPORTS_TO_HIDE = 3
PUBLIC_BASE = os.environ.get('PUBLIC_BASE_URL', 'https://sozbil-hangman-backend.onrender.com')
IOS_STORE = os.environ.get('IOS_STORE_URL', 'https://apps.apple.com/app/id0000000000')
ANDROID_STORE = 'https://play.google.com/store/apps/details?id=com.sozbil.app'

# Word roots masked in chat. Deliberately short; extend through the
# CHAT_BLOCKLIST env var (comma-separated) without a deploy of code.
_BASE_BLOCKLIST = ['хуй', 'пизд', 'ебат', 'ебан', 'бляд', 'сука', 'orospu', 'siktir', 'amına', 'amina',
                   'yarrak', 'fuck', 'shit', 'bitch', 'cunt', 'gahbe', 'jalap', 'sikdir']


def _blocklist():
    extra = [w.strip().lower() for w in os.environ.get('CHAT_BLOCKLIST', '').split(',') if w.strip()]
    return _BASE_BLOCKLIST + extra


def mask_profanity(text):
    def repl(match):
        word = match.group(0)
        return word[0] + '*' * (len(word) - 1)
    for root in _blocklist():
        text = re.sub(r'\w*' + re.escape(root) + r'\w*', repl, text, flags=re.IGNORECASE)
    return text


def blocked_ids(player):
    return set(PlayerBlock.objects.filter(blocker=player).values_list('blocked_id', flat=True))


# ── chat moderation ─────────────────────────────────────────────────────────

@api_view(['POST'])
def chat_report(request, message_id):
    player = require_player(request)
    msg = ChatMessage.objects.filter(pk=message_id).first()
    if msg is None:
        raise ValidationError('Message not found.')
    if msg.player_id == player.pk:
        raise ValidationError('You cannot report your own message.')
    ChatReport.objects.get_or_create(message=msg, reporter=player,
                                     defaults={'reason': str(request.data.get('reason', ''))[:30]})
    if msg.reports.count() >= REPORTS_TO_HIDE and not msg.hidden:
        ChatMessage.objects.filter(pk=msg.pk).update(hidden=True)
    return Response({'reported': True})


@api_view(['POST'])
def chat_block(request, message_id):
    """Block the author of a message — no player id is ever exposed."""
    player = require_player(request)
    msg = ChatMessage.objects.filter(pk=message_id).first()
    if msg is None or msg.player_id == player.pk:
        raise ValidationError('Cannot block this author.')
    PlayerBlock.objects.get_or_create(blocker=player, blocked_id=msg.player_id)
    Friendship.objects.filter(player=player, friend_id=msg.player_id).delete()
    Friendship.objects.filter(player_id=msg.player_id, friend=player).delete()
    return Response({'blocked': True})


@api_view(['GET'])
def blocks(request):
    player = require_player(request)
    rows = PlayerBlock.objects.filter(blocker=player).select_related('blocked')
    return Response([{'id': b.pk, 'display_name': b.blocked.display_name,
                      'avatar_emoji': dict(Player.AVATAR_CHOICES).get(b.blocked.avatar_key, '🦅')}
                     for b in rows])


@api_view(['POST'])
def unblock(request, block_id):
    player = require_player(request)
    PlayerBlock.objects.filter(pk=block_id, blocker=player).delete()
    return Response({'unblocked': True})


# ── friends ─────────────────────────────────────────────────────────────────

def _friend_json(friend, weekly):
    return {'id': friend.pk, 'display_name': friend.display_name,
            'avatar_emoji': dict(Player.AVATAR_CHOICES).get(friend.avatar_key, '🦅'),
            'frame_key': friend.frame_key, 'country_code': friend.country_code,
            'weekly_score': weekly.get(friend.pk, 0), 'last_active': friend.last_active}


@api_view(['GET'])
def friends(request):
    player = require_player(request)
    ids = list(Friendship.objects.filter(player=player).values_list('friend_id', flat=True))
    start, end = bounds('weekly')
    weekly = dict(GameSession.objects.filter(player_id__in=ids, won=True, played_at__gte=start, played_at__lt=end)
                  .values('player_id').annotate(s=Sum('score')).values_list('player_id', 's'))
    people = sorted(Player.objects.filter(pk__in=ids), key=lambda p: -weekly.get(p.pk, 0))
    return Response({'my_code': ensure_friend_code(player),
                     'friends': [_friend_json(p, weekly) for p in people]})


@api_view(['POST'])
def friend_add(request):
    player = require_player(request)
    code = str(request.data.get('code', '')).strip().upper()
    other = Player.objects.filter(friend_code=code).first() if len(code) == 6 else None
    if other is None:
        return Response({'error': 'not_found'}, status=404)
    if other.pk == player.pk:
        raise ValidationError('That is your own code.')
    if PlayerBlock.objects.filter(blocker=other, blocked=player).exists():
        return Response({'error': 'not_found'}, status=404)  # don't reveal blocks
    PlayerBlock.objects.filter(blocker=player, blocked=other).delete()
    Friendship.objects.get_or_create(player=player, friend=other)
    Friendship.objects.get_or_create(player=other, friend=player)
    return Response(_friend_json(other, {}))


@api_view(['POST'])
def friend_remove(request, friend_id):
    player = require_player(request)
    Friendship.objects.filter(player=player, friend_id=friend_id).delete()
    Friendship.objects.filter(player_id=friend_id, friend=player).delete()
    return Response({'removed': True})


# ── challenges ──────────────────────────────────────────────────────────────

def challenge_url(code):
    return f'{PUBLIC_BASE}/c/{code}'


def _challenge_json(ch):
    return {'code': ch.code, 'url': challenge_url(ch.code), 'game_type': ch.game_type, 'score': ch.score,
            'creator_name': ch.creator.display_name, 'creator_friend_code': ensure_friend_code(ch.creator),
            'creator_avatar': dict(Player.AVATAR_CHOICES).get(ch.creator.avatar_key, '🦅'),
            'expires_at': ch.expires_at, 'expired': ch.expires_at <= timezone.now(),
            'attempts': ch.results.count(), 'beaten': ch.results.filter(beat=True).count()}


@api_view(['POST'])
def challenge_create(request):
    from .platform import GAME_ORDER
    player = require_player(request)
    game = request.data.get('game_type')
    if game not in GAME_ORDER:
        raise ValidationError({'game_type': 'Unknown game.'})
    try:
        score = max(0, int(request.data.get('score', 0)))
    except (TypeError, ValueError):
        raise ValidationError({'score': 'Number required.'})
    for _ in range(10):
        code = ''.join(secrets.choice(FRIEND_CODE_ALPHABET) for _ in range(8))
        if not Challenge.objects.filter(code=code).exists():
            break
    ch = Challenge.objects.create(code=code, creator=player, game_type=game, score=score,
                                  expires_at=timezone.now() + timedelta(days=7))
    return Response(_challenge_json(ch), status=201)


@api_view(['GET'])
def challenge_detail(request, code):
    ch = Challenge.objects.filter(code=code.upper()).select_related('creator').first()
    if ch is None:
        return Response({'error': 'not_found'}, status=404)
    return Response(_challenge_json(ch))


@api_view(['POST'])
def challenge_result(request, code):
    player = require_player(request)
    ch = Challenge.objects.filter(code=code.upper()).first()
    if ch is None or ch.expires_at <= timezone.now():
        raise ValidationError('Challenge expired.')
    try:
        score = max(0, int(request.data.get('score', 0)))
    except (TypeError, ValueError):
        raise ValidationError({'score': 'Number required.'})
    beat = score > ch.score
    result, created = ChallengeResult.objects.get_or_create(challenge=ch, player=player,
                                                            defaults={'score': score, 'beat': beat})
    if not created and score > result.score:
        result.score, result.beat = score, beat
        result.save()
    return Response({'beat': result.beat, 'your_score': result.score, 'target': ch.score})


# ── web: challenge landing page + app/universal link association ───────────

def challenge_page(request, code):
    ch = Challenge.objects.filter(code=code.upper()).select_related('creator').first()
    who = escape(ch.creator.display_name) if ch else 'A friend'
    score = ch.score if ch else ''
    html = f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sözbil challenge</title>
<meta property="og:title" content="{who} — Sözbil">
<meta property="og:description" content="{who}: {score}. Can you beat it?">
<style>body{{font-family:-apple-system,system-ui,sans-serif;background:#16152b;color:#fff;
text-align:center;padding:48px 20px}}a{{display:block;margin:14px auto;max-width:320px;padding:14px;
border-radius:14px;background:#5B5BD6;color:#fff;text-decoration:none;font-weight:700}}
.s{{font-size:44px;font-weight:800;margin:10px 0}}</style></head><body>
<h2>{who} challenges you!</h2><div class="s">{score}</div><p>Beat this score in Sözbil.</p>
<a href="sozbil://c/{escape(code)}">Open in Sözbil</a>
<a href="{IOS_STORE}">App Store</a><a href="{ANDROID_STORE}">Google Play</a></body></html>"""
    return HttpResponse(html)


def apple_app_site_association(request):
    """iOS universal links. Needs APPLE_TEAM_ID set on the server and the
    Associated Domains capability (applinks:<backend host>) in Xcode."""
    team = os.environ.get('APPLE_TEAM_ID', 'TEAMID')
    data = {'applinks': {'details': [{'appIDs': [f'{team}.com.sozbil.app.SozBil'],
                                      'components': [{'/': '/c/*'}]}]}}
    return JsonResponse(data)


def asset_links(request):
    """Android App Links. ANDROID_CERT_SHA256 = the SHA-256 of the Play app
    signing key (Play Console → App integrity), comma-separated if several."""
    prints = [p.strip() for p in os.environ.get('ANDROID_CERT_SHA256', '').split(',') if p.strip()]
    return JsonResponse([{'relation': ['delegate_permission/common.handle_all_urls'],
                          'target': {'namespace': 'android_app', 'package_name': 'com.sozbil.app',
                                     'sha256_cert_fingerprints': prints}}], safe=False)
