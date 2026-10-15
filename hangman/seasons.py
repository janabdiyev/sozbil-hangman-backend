"""Platform v2 (2026-10-14): seasons ("Ýol" pass) and live events.

- A season runs one calendar month (UTC), lining up with the monthly
  leaderboard. If admin hasn't created one, it is generated automatically
  with a theme from the Turkmen calendar, so the feature never goes dark.
- Season XP comes only from score submissions the server sees (a win is
  WIN_XP × event multipliers, a loss LOSS_XP), so it can't be farmed by
  editing the app.
- Free track for everyone; premium track for subscribers. NOTE: the server
  has no receipt validation yet, so it trusts the app's `premium` flag, the
  same trust level as the rest of the subscription today.
- "Game of the week" runs automatically (2× season XP for one game, rotating
  by ISO week) unless admin schedules a different one.
"""
from datetime import datetime, timedelta, timezone as dt_timezone

from django.db import transaction
from django.db.models import Count
from django.utils import timezone
from rest_framework.decorators import api_view
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from .accounts import grant_gems, grant_cosmetic
from .models import Player, Season, SeasonProgress, LiveEvent, EventClaim, GameSession
from .platform import require_player

WIN_XP = 10
LOSS_XP = 3
TIERS = 30
XP_PER_TIER = 50

# Rotates through games that submit scores (Bazar and Lands of Hanlyk don't).
GAME_OF_WEEK_ROTATION = ['jellad', 'krosword', 'mina', 'yatkeslik', 'soz_zynjyry',
                         'puzzle', 'tilki', 'zehin', 'suysurme', 'smash_rings', 'hanlyk']

THEME_BY_MONTH = {1: 'newyear', 3: 'nowruz', 4: 'horse', 5: 'carpet', 8: 'melon',
                  9: 'independence', 12: 'newyear'}
THEME_TITLES = {
    'classic': {'tk': 'Sözbil möwsümi', 'en': 'Sözbil season', 'ru': 'Сезон Sözbil', 'tr': 'Sözbil sezonu'},
    'nowruz': {'tk': 'Nowruz möwsümi', 'en': 'Nowruz season', 'ru': 'Сезон Новруз', 'tr': 'Nevruz sezonu'},
    'horse': {'tk': 'Ahalteke möwsümi', 'en': 'Akhal-Teke season', 'ru': 'Сезон ахалтекинца', 'tr': 'Ahalteke sezonu'},
    'carpet': {'tk': 'Haly möwsümi', 'en': 'Carpet season', 'ru': 'Сезон ковра', 'tr': 'Halı sezonu'},
    'melon': {'tk': 'Gawun möwsümi', 'en': 'Melon season', 'ru': 'Сезон дыни', 'tr': 'Kavun sezonu'},
    'independence': {'tk': 'Garaşsyzlyk möwsümi', 'en': 'Independence season',
                     'ru': 'Сезон Независимости', 'tr': 'Bağımsızlık sezonu'},
    'newyear': {'tk': 'Täze ýyl möwsümi', 'en': 'New Year season', 'ru': 'Новогодний сезон', 'tr': 'Yılbaşı sezonu'},
}


def default_tiers(theme):
    tiers = []
    for t in range(1, TIERS + 1):
        big = t % 5 == 0
        free = {'gems': 3 if big else 1}
        premium = {'gems': 6 if big else 2}
        if t == 20:
            premium['frame'] = theme          # premium gets the season frame early
        if t == TIERS:
            free['frame'] = theme             # everyone who finishes gets it
            premium['frame'] = 'gold'
        tiers.append({'tier': t, 'free': free, 'premium': premium})
    return tiers


def month_bounds(now):
    start = now.astimezone(dt_timezone.utc).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    return start, (start + timedelta(days=32)).replace(day=1)


def current_season(now=None):
    now = now or timezone.now()
    season = Season.objects.filter(starts_at__lte=now, ends_at__gt=now).order_by('-starts_at').first()
    if season:
        return season
    start, end = month_bounds(now)
    theme = THEME_BY_MONTH.get(start.month, 'classic')
    season, _ = Season.objects.get_or_create(
        key=f'{start.year}-{start.month:02d}',
        defaults={'theme': theme, 'title': THEME_TITLES[theme], 'starts_at': start, 'ends_at': end,
                  'xp_per_tier': XP_PER_TIER, 'tiers': default_tiers(theme)})
    return season


def week_bounds(now):
    start = now.astimezone(dt_timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    start -= timedelta(days=start.weekday())
    return start, start + timedelta(days=7)


def active_events(now=None, country=''):
    """Stored events + the automatic game of the week (as a plain dict)."""
    now = now or timezone.now()
    events = list(LiveEvent.objects.filter(is_active=True, starts_at__lte=now, ends_at__gt=now))
    events = [e for e in events if not e.country_code or e.country_code == country]
    out = [event_json(e) for e in events]
    if not any(e.kind == 'game_of_week' for e in events):
        start, end = week_bounds(now)
        game = GAME_OF_WEEK_ROTATION[start.isocalendar()[1] % len(GAME_OF_WEEK_ROTATION)]
        out.append({'id': None, 'kind': 'game_of_week', 'game_type': game, 'xp_multiplier': 2.0,
                    'title': {'tk': 'Hepdäniň oýny', 'en': 'Game of the week',
                              'ru': 'Игра недели', 'tr': 'Haftanın oyunu'},
                    'body': {'tk': 'Bu oýunda möwsüm XP iki esse!', 'en': 'Double season XP in this game!',
                             'ru': 'Двойной опыт сезона в этой игре!', 'tr': 'Bu oyunda sezon XP iki kat!'},
                    'starts_at': start, 'ends_at': end, 'auto': True})
    return out


def event_json(e, player=None):
    data = {'id': e.pk, 'kind': e.kind, 'game_type': e.game_type, 'xp_multiplier': e.xp_multiplier,
            'title': e.title, 'body': e.body, 'starts_at': e.starts_at, 'ends_at': e.ends_at,
            'country_code': e.country_code, 'auto': False}
    if e.kind == 'community_goal':
        data.update({'goal_target': e.goal_target, 'goal_progress': goal_progress(e),
                     'reward_gems': e.reward_gems})
        if player is not None:
            data['claimed'] = EventClaim.objects.filter(event=e, player=player).exists()
    return data


def goal_progress(event):
    qs = GameSession.objects.filter(won=True, played_at__gte=event.starts_at, played_at__lt=event.ends_at)
    if event.game_type:
        qs = qs.filter(game_type=event.game_type)
    if event.country_code:
        qs = qs.filter(player__country_code=event.country_code)
    return qs.count()


def xp_multiplier(game_type, country, now=None):
    mult = 1.0
    for e in active_events(now, country):
        if e['kind'] in ('game_of_week', 'double_xp') and (not e['game_type'] or e['game_type'] == game_type):
            mult *= float(e['xp_multiplier'] or 1)
    return min(mult, 5.0)


def award_season_xp(player, game_type, won):
    """Called from api_submit_score inside its transaction."""
    season = current_season()
    gained = round((WIN_XP if won else LOSS_XP) * xp_multiplier(game_type, player.country_code))
    progress, _ = SeasonProgress.objects.select_for_update().get_or_create(season=season, player=player)
    progress.xp += gained
    progress.save(update_fields=['xp'])
    return gained, progress.xp


def season_json(season, progress):
    tier = min(TIERS, progress.xp // max(1, season.xp_per_tier)) if progress else 0
    return {'key': season.key, 'theme': season.theme, 'title': season.title,
            'starts_at': season.starts_at, 'ends_at': season.ends_at,
            'xp_per_tier': season.xp_per_tier, 'xp': progress.xp if progress else 0,
            'tier': tier, 'tiers': season.tiers,
            'claimed_free': progress.claimed_free if progress else [],
            'claimed_premium': progress.claimed_premium if progress else [],
            'win_xp': WIN_XP, 'loss_xp': LOSS_XP}


@api_view(['GET'])
def season(request):
    player = require_player(request)
    s = current_season()
    progress, _ = SeasonProgress.objects.get_or_create(season=s, player=player)
    return Response(season_json(s, progress))


@api_view(['POST'])
def season_claim(request):
    player = require_player(request)
    try:
        tier = int(request.data.get('tier'))
    except (TypeError, ValueError):
        raise ValidationError({'tier': 'Required.'})
    track = request.data.get('track', 'free')
    if track not in ('free', 'premium'):
        raise ValidationError({'track': 'free or premium'})
    if track == 'premium' and request.data.get('premium') is not True:
        raise ValidationError({'premium': 'Premium track needs Sözbil Premium.'})
    s = current_season()
    with transaction.atomic():
        player = Player.objects.select_for_update().get(pk=player.pk)
        progress, _ = SeasonProgress.objects.select_for_update().get_or_create(season=s, player=player)
        reached = progress.xp // max(1, s.xp_per_tier)
        if tier < 1 or tier > reached:
            raise ValidationError({'tier': 'Not reached yet.'})
        claimed = progress.claimed_free if track == 'free' else progress.claimed_premium
        if tier not in claimed:
            reward = next((t.get(track, {}) for t in s.tiers if t.get('tier') == tier), {})
            if reward.get('gems'):
                grant_gems(player, int(reward['gems']), 'srv:season', f'srv:season:{s.key}:{track}:{tier}')
            if reward.get('frame'):
                grant_cosmetic(player, reward['frame'], f'season:{s.key}')
            claimed.append(tier)
            progress.save()
    return Response({**season_json(s, progress), 'gems': player.gems})


@api_view(['GET'])
def events(request):
    player = require_player(request)
    now = timezone.now()
    stored = LiveEvent.objects.filter(is_active=True, ends_at__gt=now, starts_at__lte=now + timedelta(days=7))
    stored = [e for e in stored if not e.country_code or e.country_code == player.country_code]
    out = [event_json(e, player) for e in stored]
    out += [e for e in active_events(now, player.country_code) if e.get('auto')]
    return Response(sorted(out, key=lambda e: e['starts_at']))


@api_view(['POST'])
def event_claim(request, event_id):
    player = require_player(request)
    event = LiveEvent.objects.filter(pk=event_id, kind='community_goal', is_active=True).first()
    if event is None or (event.country_code and event.country_code != player.country_code):
        raise ValidationError('Event unavailable.')
    if goal_progress(event) < event.goal_target:
        raise ValidationError('Goal not reached yet.')
    if not GameSession.objects.filter(player=player, won=True, played_at__gte=event.starts_at,
                                      played_at__lt=event.ends_at).exists():
        raise ValidationError('Win at least one game during the event to share the reward.')
    with transaction.atomic():
        player = Player.objects.select_for_update().get(pk=player.pk)
        _, created = EventClaim.objects.get_or_create(event=event, player=player)
        if created:
            grant_gems(player, event.reward_gems, 'srv:event', f'srv:event:{event.pk}')
    return Response({'claimed': True, 'gems': player.gems})
