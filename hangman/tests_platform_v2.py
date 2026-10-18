"""Platform v2 tests: accounts, cloud save, gems, seasons, events, social."""
from datetime import timedelta
from unittest import mock

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (Player, GameSession, ChatMessage, CompetitionPeriod, CompetitionReward,
                     LiveEvent, GemTransaction, PlayerIdentity)


class Base(TestCase):
    def enroll(self, name='P', country='TM'):
        p = Player.objects.create(display_name=name, country_code=country)
        c = APIClient()
        token = (name * 48)[:48]
        c.post('/api/platform/session/', {'player_uuid': str(p.uuid), 'token': token}, format='json')
        c.credentials(HTTP_X_PLAYER_UUID=str(p.uuid), HTTP_X_PLATFORM_TOKEN=token)
        return p, c


VERIFY = 'hangman.accounts.verify_id_token'


class AccountTests(Base):
    def test_link_restore_on_new_device_and_conflict(self):
        p, c = self.enroll('A')
        with mock.patch(VERIFY, return_value=('sub-1', 'a@x.com')):
            r = c.post('/api/platform/auth/link/', {'provider': 'google', 'id_token': 'x' * 30}, format='json')
            self.assertEqual(r.status_code, 200)
            self.assertEqual(r.data['identities'][0]['provider'], 'google')
            # new phone restores with its own credential
            fresh = APIClient()
            r = fresh.post('/api/platform/auth/restore/', {'provider': 'google', 'id_token': 'x' * 30,
                                                           'token': 'n' * 40}, format='json')
            self.assertEqual(r.status_code, 200)
            self.assertEqual(r.data['player']['uuid'], str(p.uuid))
            # the app re-runs its enrolment handshake with the new token
            self.assertEqual(fresh.post('/api/platform/session/', {'player_uuid': str(p.uuid), 'token': 'n' * 40},
                                        format='json').status_code, 200)
            self.assertEqual(fresh.post('/api/platform/session/', {'player_uuid': str(p.uuid), 'token': 'q' * 40},
                                        format='json').status_code, 403)
            fresh.credentials(HTTP_X_PLAYER_UUID=str(p.uuid), HTTP_X_PLATFORM_TOKEN='n' * 40)
            self.assertEqual(fresh.get('/api/platform/account/').status_code, 200)
            # the original phone keeps working too
            self.assertEqual(c.get('/api/platform/account/').status_code, 200)
            # a different player trying to link the same Google account → 409
            q, qc = self.enroll('B')
            r = qc.post('/api/platform/auth/link/', {'provider': 'google', 'id_token': 'x' * 30}, format='json')
            self.assertEqual(r.status_code, 409)
            self.assertEqual(r.data['error'], 'identity_in_use')
        with mock.patch(VERIFY, return_value=('nobody', '')):
            r = APIClient().post('/api/platform/auth/restore/', {'provider': 'apple', 'id_token': 'x' * 30,
                                                                 'token': 'm' * 40}, format='json')
            self.assertEqual(r.status_code, 404)

    def test_wrong_device_token_rejected(self):
        p, c = self.enroll('A')
        bad = APIClient()
        bad.credentials(HTTP_X_PLAYER_UUID=str(p.uuid), HTTP_X_PLATFORM_TOKEN='z' * 40)
        self.assertEqual(bad.get('/api/platform/account/').status_code, 403)

    def test_delete_account(self):
        p, c = self.enroll('A')
        self.assertEqual(c.post('/api/platform/account/delete/', {}, format='json').status_code, 400)
        self.assertEqual(c.post('/api/platform/account/delete/', {'confirm': 'DELETE'}, format='json').status_code, 200)
        self.assertFalse(Player.objects.filter(pk=p.pk).exists())


class SaveTests(Base):
    def test_versions_and_conflict(self):
        p, c = self.enroll('A')
        r = c.put('/api/platform/saves/prefs/', {'data': '{"a":1}'}, format='json')
        self.assertEqual(r.data['version'], 1)
        r = c.put('/api/platform/saves/prefs/', {'data': '{"a":2}', 'base_version': 1}, format='json')
        self.assertEqual(r.data['version'], 2)
        r = c.put('/api/platform/saves/prefs/', {'data': '{"a":3}', 'base_version': 1}, format='json')
        self.assertEqual(r.status_code, 409)
        self.assertEqual(r.data['data'], '{"a":2}')
        self.assertEqual(c.get('/api/platform/saves/prefs/').data['data'], '{"a":2}')
        self.assertEqual(c.get('/api/platform/saves/bad ns/').status_code, 400)


class WalletTests(Base):
    def test_import_once_idempotent_ops_cap_and_clamp(self):
        p, c = self.enroll('A')
        r = c.post('/api/platform/wallet/sync/', {'import_balance': 40, 'ops': [
            {'delta': 5, 'reason': 'quest', 'ref': 'r1'}, {'delta': -10, 'reason': 'ability', 'ref': 'r2'}]},
            format='json')
        self.assertEqual(r.data['gems'], 35)
        self.assertEqual(sorted(r.data['settled']), ['r1', 'r2'])
        # retry is a no-op; second import ignored
        r = c.post('/api/platform/wallet/sync/', {'import_balance': 999, 'ops': [
            {'delta': 5, 'reason': 'quest', 'ref': 'r1'}]}, format='json')
        self.assertEqual(r.data['gems'], 35)
        # client earnings capped per day
        r = c.post('/api/platform/wallet/sync/', {'ops': [{'delta': 1000, 'reason': 'x', 'ref': 'big'}]}, format='json')
        self.assertEqual(r.data['gems'], 35 + 295)
        # spends clamp at zero
        r = c.post('/api/platform/wallet/sync/', {'ops': [{'delta': -9999, 'reason': 'x', 'ref': 'spend'}]}, format='json')
        self.assertEqual(r.data['gems'], 0)
        # clients cannot forge server reasons
        r = c.post('/api/platform/wallet/sync/', {'ops': [{'delta': 50, 'reason': 'srv:prize', 'ref': 'f'}]}, format='json')
        self.assertEqual(r.data['gems'], 0)

    def test_buy_and_equip_frame(self):
        p, c = self.enroll('A')
        self.assertEqual(c.post('/api/platform/cosmetics/buy/', {'key': 'silver'}, format='json').status_code, 402)
        Player.objects.filter(pk=p.pk).update(gems=100)
        r = c.post('/api/platform/cosmetics/buy/', {'key': 'silver'}, format='json')
        self.assertEqual(r.data['gems'], 70)
        self.assertEqual(c.post('/api/platform/cosmetics/equip/', {'key': 'gold'}, format='json').status_code, 400)
        c.post('/api/platform/cosmetics/equip/', {'key': 'silver'}, format='json')
        self.assertEqual(Player.objects.get(pk=p.pk).frame_key, 'silver')

    def test_prize_claim_credits_server_gems(self):
        p, c = self.enroll('A')
        now = timezone.now()
        period = CompetitionPeriod.objects.create(kind='weekly', start=now - timedelta(days=8),
                                                  end=now - timedelta(days=1), settled_at=now)
        reward = CompetitionReward.objects.create(period=period, player=p, rank=1, score=10, gems=10, coins=1000)
        r = c.post(f'/api/platform/rewards/{reward.pk}/claim/', {}, format='json')
        self.assertTrue(r.data['gems_credited'])
        c.post(f'/api/platform/rewards/{reward.pk}/claim/', {}, format='json')
        self.assertEqual(Player.objects.get(pk=p.pk).gems, 10)


class SeasonTests(Base):
    def submit(self, p, game='jellad', won=True):
        return APIClient().post('/api/score/', {'player_uuid': str(p.uuid), 'game_type': game,
                                                'won': won, 'wrong_guesses': 0}, format='json')

    def test_xp_tiers_claims_and_game_of_week(self):
        p, c = self.enroll('A')
        r = c.get('/api/platform/season/')
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.data['tiers']), 30)
        events = c.get('/api/platform/events/').data
        gotw = next(e for e in events if e['kind'] == 'game_of_week')
        other = 'jellad' if gotw['game_type'] != 'jellad' else 'mina'
        self.assertEqual(self.submit(p, other).data['season_xp_gained'], 10)
        self.assertEqual(self.submit(p, gotw['game_type']).data['season_xp_gained'], 20)
        self.assertEqual(self.submit(p, other, won=False).data['season_xp_gained'], 3)
        for _ in range(3):
            self.submit(p, other)
        self.assertEqual(c.get('/api/platform/season/').data['tier'], 1)  # 63 xp
        r = c.post('/api/platform/season/claim/', {'tier': 1, 'track': 'free'}, format='json')
        self.assertEqual(r.data['gems'], 1)
        c.post('/api/platform/season/claim/', {'tier': 1, 'track': 'free'}, format='json')
        self.assertEqual(Player.objects.get(pk=p.pk).gems, 1)
        self.assertEqual(c.post('/api/platform/season/claim/', {'tier': 2, 'track': 'free'}, format='json').status_code, 400)
        self.assertEqual(c.post('/api/platform/season/claim/', {'tier': 1, 'track': 'premium'}, format='json').status_code, 400)
        r = c.post('/api/platform/season/claim/', {'tier': 1, 'track': 'premium', 'premium': True}, format='json')
        self.assertEqual(r.data['gems'], 3)

    def test_hanlyk_and_tilki_scores_accepted(self):
        p, c = self.enroll('A')
        for game in ('hanlyk', 'tilki'):
            self.assertEqual(self.submit(p, game).status_code, 201)

    def test_kerpic_and_halycy_scores_accepted(self):
        p, c = self.enroll('A')
        for game in ('kerpic', 'halycy'):
            self.assertEqual(self.submit(p, game).status_code, 201)
        order = [g['game_type'] for g in c.get('/api/platform/games/').data]
        self.assertEqual(order[-2:], ['kerpic', 'halycy'])

    def test_community_goal(self):
        p, c = self.enroll('A')
        now = timezone.now()
        ev = LiveEvent.objects.create(kind='community_goal', title={'en': 'Goal'}, goal_target=2, reward_gems=5,
                                      starts_at=now - timedelta(hours=1), ends_at=now + timedelta(days=1))
        self.assertEqual(c.post(f'/api/platform/events/{ev.pk}/claim/', {}, format='json').status_code, 400)
        GameSession.objects.create(player=p, game_type='mina', won=True, score=10)
        GameSession.objects.create(player=p, game_type='mina', won=True, score=10)
        self.assertEqual(c.post(f'/api/platform/events/{ev.pk}/claim/', {}, format='json').data['gems'], 5)
        c.post(f'/api/platform/events/{ev.pk}/claim/', {}, format='json')
        self.assertEqual(Player.objects.get(pk=p.pk).gems, 5)


class SocialTests(Base):
    def test_report_hides_after_three_and_block_filters(self):
        author, ac = self.enroll('Au')
        msg = ChatMessage.objects.create(player=author, country_code='TM', message='bad')
        viewers = [self.enroll(f'V{i}') for i in range(3)]
        self.assertEqual(ac.post(f'/api/chat/{msg.pk}/report/', {}, format='json').status_code, 400)
        for i, (v, vc) in enumerate(viewers):
            vc.post(f'/api/chat/{msg.pk}/report/', {'reason': 'abuse'}, format='json')
            vc.post(f'/api/chat/{msg.pk}/report/', {'reason': 'abuse'}, format='json')  # duplicate ignored
        msg.refresh_from_db()
        self.assertTrue(msg.hidden)
        self.assertEqual(viewers[0][1].get('/api/chat/').data, [])
        self.assertEqual(len(ac.get('/api/chat/').data), 1)  # author still sees own
        # block
        ok = ChatMessage.objects.create(player=author, country_code='TM', message='hi')
        v, vc = self.enroll('W')
        self.assertEqual(len(vc.get('/api/chat/').data), 1)
        vc.post(f'/api/chat/{ok.pk}/block/', {}, format='json')
        self.assertEqual(vc.get('/api/chat/').data, [])
        blocks = vc.get('/api/platform/blocks/').data
        self.assertEqual(blocks[0]['display_name'], 'Au')
        vc.post(f"/api/platform/blocks/{blocks[0]['id']}/remove/", {}, format='json')
        self.assertEqual(len(vc.get('/api/chat/').data), 1)

    def test_profanity_masked(self):
        p, c = self.enroll('A')
        r = c.post('/api/chat/', {'message': 'what the fuck'}, format='json')
        self.assertEqual(r.data['message'], 'what the f***')

    def test_friends_and_friends_board_and_game_board(self):
        a, ac = self.enroll('A')
        b, bc = self.enroll('B')
        x, xc = self.enroll('X')
        code = bc.get('/api/platform/friends/').data['my_code']
        self.assertEqual(len(code), 6)
        self.assertEqual(ac.post('/api/platform/friends/add/', {'code': 'ZZZZZZ'}, format='json').status_code, 404)
        ac.post('/api/platform/friends/add/', {'code': code}, format='json')
        self.assertEqual(len(bc.get('/api/platform/friends/').data['friends']), 1)  # mutual
        for pl, game, score in [(a, 'jellad', 50), (b, 'mina', 70), (x, 'jellad', 999)]:
            GameSession.objects.create(player=pl, game_type=game, won=True, score=score)
        board = ac.get('/api/leaderboard/?filter=weekly&scope=friends').data
        self.assertEqual([r['display_name'] for r in board], ['B', 'A'])
        self.assertEqual(board[0]['prize_gems'], 0)
        board = ac.get('/api/leaderboard/?filter=weekly&game=jellad').data
        self.assertEqual([r['display_name'] for r in board], ['X', 'A'])
        self.assertEqual(ac.get('/api/leaderboard/?filter=weekly&game=nope').status_code, 400)

    def test_challenge_flow_and_web_files(self):
        a, ac = self.enroll('A')
        b, bc = self.enroll('B')
        r = ac.post('/api/platform/challenges/', {'game_type': 'mina', 'score': 120}, format='json')
        code = r.data['code']
        self.assertIn('/c/' + code, r.data['url'])
        self.assertEqual(APIClient().get(f'/api/platform/challenges/{code}/').data['creator_name'], 'A')
        self.assertFalse(bc.post(f'/api/platform/challenges/{code}/result/', {'score': 100}, format='json').data['beat'])
        self.assertTrue(bc.post(f'/api/platform/challenges/{code}/result/', {'score': 150}, format='json').data['beat'])
        self.assertContains(APIClient().get(f'/c/{code}'), 'challenges you')
        self.assertEqual(APIClient().get('/.well-known/assetlinks.json').status_code, 200)
        self.assertIn('applinks', APIClient().get('/.well-known/apple-app-site-association').json())
