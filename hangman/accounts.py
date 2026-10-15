"""Platform v2 (2026-10-14): accounts, cloud save, gem wallet, cosmetics.

Design notes
- Guest play stays the default. A player *links* Apple/Google to the
  device-UUID player they already have; nothing about scoring changes.
- On a new phone, `restore` exchanges a verified ID token for a fresh
  per-device credential (DeviceCredential) on the linked player.
- Gems are server-authoritative from v2 on. The app keeps an offline cache
  and an op journal; `wallet_sync` applies the journal idempotently.
- Hanlyk *coins* stay a device-local battle currency (Can, 2026-10-14).
"""
import hashlib
import json
import secrets
from datetime import timedelta

from django.db import IntegrityError, transaction
from django.db.models import Sum
from django.http import HttpResponseRedirect
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from .identity import verify_id_token
from .models import (Player, PlayerIdentity, DeviceCredential, CloudSave,
                     GemTransaction, Cosmetic)
from .platform import require_player

FRIEND_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'  # no 0/O/1/I

# Frames that can be bought with gems. Season-only frames are granted by tiers.
SHOP_FRAMES = {'silver': 30, 'gold': 80, 'ruby': 150, 'emerald': 150}
SEASON_FRAMES = {'classic', 'nowruz', 'horse', 'carpet', 'melon', 'independence', 'newyear'}
ALL_FRAMES = set(SHOP_FRAMES) | SEASON_FRAMES

# Client-reported gem earnings (daily quests, Hanlyk battle wins, rewarded
# ads) can't be verified server-side. Cap them per UTC day so a tampered
# client can't mint unlimited gems. Server grants (prizes, season tiers,
# events) are not capped.
CLIENT_EARN_DAILY_CAP = 300
IMPORT_CAP = 3000
SAVE_MAX_BYTES = 1_000_000


# ── helpers ──────────────────────────────────────────────────────────────────

def ensure_friend_code(player):
    if player.friend_code:
        return player.friend_code
    for _ in range(20):
        code = ''.join(secrets.choice(FRIEND_CODE_ALPHABET) for _ in range(6))
        if not Player.objects.filter(friend_code=code).exists():
            Player.objects.filter(pk=player.pk, friend_code='').update(friend_code=code)
            player.refresh_from_db(fields=['friend_code'])
            return player.friend_code
    raise ValidationError('Could not allocate a friend code.')


def grant_gems(player, amount, reason, ref):
    """Server-side gem change. Idempotent on (player, ref). Must be called
    inside a transaction that holds a row lock on `player`. Returns the
    applied delta (0 if `ref` was already used)."""
    if amount == 0 or GemTransaction.objects.filter(player=player, ref=ref).exists():
        return 0
    new_balance = max(0, player.gems + amount)
    applied = new_balance - player.gems
    player.gems = new_balance
    player.save(update_fields=['gems'])
    GemTransaction.objects.create(player=player, delta=applied, balance_after=new_balance,
                                  reason=reason[:40], ref=ref[:80])
    return applied


def grant_cosmetic(player, key, source):
    if key not in ALL_FRAMES:
        return False
    _, created = Cosmetic.objects.get_or_create(player=player, key=key, defaults={'source': source})
    return created


def account_json(player):
    return {
        'identities': [{'provider': i.provider, 'email': i.email}
                       for i in player.identities.all().order_by('provider')],
        'friend_code': ensure_friend_code(player),
        'gems': player.gems,
        'frame_key': player.frame_key,
    }


def _new_device_token(request):
    token = request.data.get('token', '')
    if not isinstance(token, str) or not 32 <= len(token) <= 128:
        raise ValidationError('Invalid device credential.')
    return token


# ── accounts ─────────────────────────────────────────────────────────────────

@api_view(['GET'])
def account(request):
    return Response(account_json(require_player(request)))


@api_view(['POST'])
def auth_link(request):
    """Link Apple/Google to the calling device's player."""
    player = require_player(request)
    provider = request.data.get('provider')
    subject, email = verify_id_token(provider, request.data.get('id_token'))
    existing = PlayerIdentity.objects.filter(provider=provider, subject=subject).select_related('player').first()
    if existing and existing.player_id != player.pk:
        # The account already belongs to another Sözbil player — usually the
        # same person's old phone. The app offers "switch to that account",
        # which is `auth_restore`.
        return Response({'error': 'identity_in_use',
                         'other_display_name': existing.player.display_name,
                         'other_xp': existing.player.xp}, status=409)
    if not existing:
        try:
            PlayerIdentity.objects.create(player=player, provider=provider, subject=subject, email=email)
        except IntegrityError:
            raise ValidationError('This player already has a linked account of that kind.')
    return Response(account_json(player))


@api_view(['POST'])
def auth_restore(request):
    """New phone: verified ID token → a device credential for the linked
    player. Unauthenticated by design (the ID token IS the proof)."""
    provider = request.data.get('provider')
    subject, _ = verify_id_token(provider, request.data.get('id_token'))
    token = _new_device_token(request)
    identity = PlayerIdentity.objects.filter(provider=provider, subject=subject).select_related('player').first()
    if identity is None:
        return Response({'error': 'no_account'}, status=404)
    player = identity.player
    DeviceCredential.objects.create(player=player, token_hash=hashlib.sha256(token.encode()).hexdigest(),
                                    last_used=timezone.now())
    from .serializers import PlayerSerializer
    return Response({'player': PlayerSerializer(player).data, **account_json(player)})


@api_view(['POST'])
def auth_unlink(request):
    player = require_player(request)
    PlayerIdentity.objects.filter(player=player, provider=request.data.get('provider')).delete()
    return Response(account_json(player))


@api_view(['POST'])
def account_delete(request):
    """In-app account deletion (App Store guideline 5.1.1(v)). Deletes the
    player and everything that cascades from it: sessions, chat, saves,
    gems, friendships, identities."""
    player = require_player(request)
    if request.data.get('confirm') != 'DELETE':
        raise ValidationError({'confirm': 'Send confirm=DELETE.'})
    player.delete()
    return Response({'deleted': True})


@csrf_exempt
def apple_android_callback(request):
    """Sign in with Apple on Android posts its result here (the Services ID's
    return URL); we bounce it back into the app, as sign_in_with_apple
    documents. Set the Services ID return URL to
    https://<backend>/api/platform/auth/apple-callback/"""
    from urllib.parse import urlencode
    body = urlencode(request.POST.dict() if request.method == 'POST' else request.GET.dict())
    package = 'com.sozbil.app'
    response = HttpResponseRedirect(f'intent://callback?{body}#Intent;package={package};scheme=signinwithapple;end')
    response.allowed_schemes = ['intent']
    return response


# ── cloud save ───────────────────────────────────────────────────────────────

def _valid_namespace(ns):
    if not ns or len(ns) > 40 or not all(c.isalnum() or c in '_-' for c in ns):
        raise ValidationError({'namespace': 'Invalid namespace.'})
    return ns


@api_view(['GET'])
def saves(request):
    player = require_player(request)
    return Response([{'namespace': s.namespace, 'version': s.version, 'updated_at': s.updated_at,
                      'bytes': len(s.data)} for s in player.saves.all()])


@api_view(['GET', 'PUT'])
def save_detail(request, namespace):
    player = require_player(request)
    _valid_namespace(namespace)
    if request.method == 'GET':
        save = CloudSave.objects.filter(player=player, namespace=namespace).first()
        if save is None:
            return Response({'error': 'not_found'}, status=404)
        return Response({'namespace': namespace, 'version': save.version,
                         'updated_at': save.updated_at, 'data': save.data})
    data = request.data.get('data')
    if not isinstance(data, str):
        data = json.dumps(data)
    if len(data.encode()) > SAVE_MAX_BYTES:
        raise ValidationError({'data': 'Save is too large.'})
    base = request.data.get('base_version')
    with transaction.atomic():
        save = CloudSave.objects.select_for_update().filter(player=player, namespace=namespace).first()
        if save is None:
            save = CloudSave.objects.create(player=player, namespace=namespace, data=data, version=1)
        else:
            # Optimistic concurrency: a phone that hasn't seen the latest
            # version gets 409 + the current save and decides what to keep.
            if base is not None and int(base) != save.version:
                return Response({'error': 'conflict', 'version': save.version,
                                 'updated_at': save.updated_at, 'data': save.data}, status=409)
            save.data = data
            save.version += 1
            save.save()
    return Response({'namespace': namespace, 'version': save.version, 'updated_at': save.updated_at})


# ── gem wallet ───────────────────────────────────────────────────────────────

@api_view(['GET'])
def wallet(request):
    player = require_player(request)
    return Response({'gems': player.gems, 'imported': player.gems_imported})


@api_view(['POST'])
def wallet_sync(request):
    """Apply the app's offline journal of gem changes.

    Body: {"import_balance": int|null, "ops": [{"delta": int, "reason": str, "ref": str}]}
    - import_balance is honoured once per player (first sync after the update
      moves the old device-local Hanlyk gems into the account), capped.
    - ops are idempotent on ref. Spends clamp at zero. Client earnings are
      capped per UTC day.
    Returns the authoritative balance and the refs that are now settled
    (applied now or earlier) so the app can drop them from its journal.
    """
    player = require_player(request)
    ops = request.data.get('ops') or []
    if not isinstance(ops, list) or len(ops) > 500:
        raise ValidationError({'ops': 'Expected a list (max 500).'})
    settled = []
    with transaction.atomic():
        player = Player.objects.select_for_update().get(pk=player.pk)
        imp = request.data.get('import_balance')
        if not player.gems_imported:
            if isinstance(imp, int) and imp > 0:
                grant_gems(player, min(imp, IMPORT_CAP), 'import', 'import-local-v1')
            player.gems_imported = True
            player.save(update_fields=['gems_imported'])
        day_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        earned_today = (GemTransaction.objects.filter(player=player, created_at__gte=day_start, delta__gt=0)
                        .exclude(reason__startswith='srv:').exclude(reason='import')
                        .aggregate(n=Sum('delta'))['n'] or 0)
        for op in ops:
            try:
                delta, ref = int(op['delta']), str(op['ref'])
                reason = str(op.get('reason', 'app'))[:30]
            except (KeyError, TypeError, ValueError):
                continue
            if not ref or reason.startswith('srv:'):
                continue
            if delta > 0:
                delta = max(0, min(delta, CLIENT_EARN_DAILY_CAP - earned_today))
            applied = grant_gems(player, delta, reason, 'c:' + ref) if delta else 0
            if delta == 0 and not GemTransaction.objects.filter(player=player, ref='c:' + ref).exists():
                # Record the capped/zero op so a retry stays settled.
                GemTransaction.objects.create(player=player, delta=0, balance_after=player.gems,
                                              reason=reason, ref='c:' + ref)
            if applied > 0:
                earned_today += applied
            settled.append(ref)
    return Response({'gems': player.gems, 'settled': settled})


# ── cosmetics (profile frames) ───────────────────────────────────────────────

@api_view(['GET'])
def cosmetics(request):
    player = require_player(request)
    owned = list(player.cosmetics.values_list('key', flat=True))
    return Response({'owned': owned, 'equipped': player.frame_key, 'gems': player.gems,
                     'shop': [{'key': k, 'price': v} for k, v in SHOP_FRAMES.items()],
                     'season_frames': sorted(SEASON_FRAMES)})


@api_view(['POST'])
def cosmetics_buy(request):
    player = require_player(request)
    key = request.data.get('key')
    if key not in SHOP_FRAMES:
        raise ValidationError({'key': 'Not for sale.'})
    with transaction.atomic():
        player = Player.objects.select_for_update().get(pk=player.pk)
        if Cosmetic.objects.filter(player=player, key=key).exists():
            return Response({'owned': True, 'gems': player.gems})
        if player.gems < SHOP_FRAMES[key]:
            return Response({'error': 'not_enough_gems', 'gems': player.gems}, status=402)
        grant_gems(player, -SHOP_FRAMES[key], 'srv:frame', f'srv:frame:{key}')
        grant_cosmetic(player, key, 'shop')
    return Response({'owned': True, 'gems': player.gems})


@api_view(['POST'])
def cosmetics_equip(request):
    player = require_player(request)
    key = request.data.get('key') or ''
    if key and not Cosmetic.objects.filter(player=player, key=key).exists():
        raise ValidationError({'key': 'You do not own this frame.'})
    Player.objects.filter(pk=player.pk).update(frame_key=key)
    return Response({'equipped': key})
