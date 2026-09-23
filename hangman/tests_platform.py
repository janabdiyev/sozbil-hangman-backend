from datetime import datetime, timedelta, timezone as tz
from uuid import uuid4
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from .models import Player, GameSession, ChatMessage, CompetitionPeriod, CompetitionReward, GameLaunch
from .platform import bounds, ensure_periods, settle

class PlatformTests(TestCase):
    def setUp(self):
        self.player = Player.objects.create(display_name='Same name', country_code='TM')
        self.other = Player.objects.create(display_name='Same name', country_code='TR')
        self.client = APIClient()
        self.token = 'a' * 48
        self.client.post('/api/platform/session/', {'player_uuid': str(self.player.uuid), 'token': self.token})
        self.player.refresh_from_db()
        self.client.credentials(HTTP_X_PLAYER_UUID=str(self.player.uuid), HTTP_X_PLATFORM_TOKEN=self.token)

    def session(self, player, score, at):
        session = GameSession.objects.create(player=player, game_type='jellad', won=True, score=score)
        GameSession.objects.filter(pk=session.pk).update(played_at=at)
        return session

    def test_calendar_boundaries(self):
        instant = datetime(2026, 3, 1, 0, 0, tzinfo=tz.utc)
        self.assertEqual(bounds('weekly', instant)[0].isoformat(), '2026-02-23T00:00:00+00:00')
        self.assertEqual(bounds('monthly', instant)[1].isoformat(), '2026-04-01T00:00:00+00:00')
        self.assertEqual(bounds('monthly', instant - timedelta(seconds=1))[0].day, 1)
        self.assertEqual(bounds('monthly', datetime(2026,12,31,tzinfo=tz.utc))[1].year,2027)

    def test_leaderboard_only_top_ten_and_no_identity_or_population(self):
        start, end = bounds('weekly')
        self.session(self.player, 9000, start - timedelta(microseconds=1))
        for i in range(12):
            p = Player.objects.create(display_name=f'P{i}')
            self.session(p, 100, start + timedelta(seconds=1))
        response = self.client.get('/api/leaderboard/?filter=weekly')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 10)
        self.assertNotIn('uuid', response.data[0])
        self.assertNotIn('Same name', [r['display_name'] for r in response.data])
        self.assertEqual([r['prize_gems'] for r in response.data], [10,7,7,5,5,5,5,5,5,5])
        self.assertEqual(self.client.get('/api/leaderboard/?filter=alltime').status_code,400)
        self.assertNotIn('total_players', self.client.get('/api/stats/').data)

    def test_chat_scoped_expiring_and_immutable_room(self):
        fresh = ChatMessage.objects.create(player=self.player, country_code='TM',message='hello')
        old = ChatMessage.objects.create(player=self.player, country_code='TM',message='old')
        ChatMessage.objects.filter(pk=old.pk).update(created_at=timezone.now()-timedelta(days=7))
        foreign = ChatMessage.objects.create(player=self.other,country_code='TR',message='foreign')
        response = self.client.get('/api/chat/?country_code=TR&location=TR')
        self.assertEqual([r['id'] for r in response.data], [fresh.pk])
        self.assertTrue(response.data[0]['is_me'])
        self.assertFalse(ChatMessage.objects.filter(pk=old.pk).exists())
        self.assertTrue(ChatMessage.objects.filter(pk=foreign.pk).exists())
        self.assertEqual(self.client.get('/api/chat/?before_id=bad').status_code,400)
        self.player.country_code = 'TR'; self.player.save()
        response = self.client.get('/api/chat/')
        self.assertEqual([r['id'] for r in response.data],[foreign.pk])
        self.assertFalse(response.data[0]['is_me'])

    def test_chat_requires_credential_and_selected_country(self):
        anon = APIClient()
        self.assertIn(anon.get('/api/chat/').status_code,[401,403])
        self.assertIn(anon.post('/api/chat/',{'player_uuid':str(self.player.uuid),'message':'fake'}).status_code,[401,403])
        self.player.country_code='';self.player.save()
        self.assertEqual(self.client.get('/api/chat/').status_code,403)
        self.assertEqual(self.client.post('/api/chat/',{'message':'hello'}).status_code,403)

    def test_new_messages_not_truncated_by_global_activity(self):
        ChatMessage.objects.bulk_create([ChatMessage(player=self.player,country_code='TM',message=str(i)) for i in range(75)])
        response = self.client.post('/api/chat/',{'message':'new','country_code':'TR'})
        self.assertEqual(response.status_code,201)
        self.assertEqual(response.data['country_code'],'TM')
        self.assertEqual(ChatMessage.objects.count(),76)
        page = self.client.get('/api/chat/').data
        previous = self.client.get('/api/chat/',{'before_id':page[0]['id']}).data
        self.assertEqual(len(page)+len(previous),76)

    def test_country_validation_and_protected_update(self):
        url=f'/api/player/{self.player.uuid}/'
        self.assertEqual(self.client.put(url,{'country_code':'Ankara'}).status_code,400)
        self.assertEqual(self.client.put(url,{'country_code':'tr'}).status_code,200)
        self.assertIn(APIClient().put(url,{'country_code':'RU'}).status_code,[401,403])

    def test_settlement_is_idempotent_and_half_open(self):
        now=datetime(2026,9,14,tzinfo=tz.utc)
        start=now-timedelta(days=7)
        period=CompetitionPeriod.objects.create(kind='weekly',start=start,end=now)
        self.session(self.player,100,start)
        self.session(self.other,200,now)
        settle(now);settle(now)
        awards=CompetitionReward.objects.filter(period=period)
        self.assertEqual(awards.count(),1)
        self.assertEqual(awards.get().player,self.player)
        self.assertEqual((awards.get().gems,awards.get().coins),(10,1000))

    def test_reward_claim_retry_ack_and_ownership(self):
        start,end=bounds('weekly')
        period,_=CompetitionPeriod.objects.get_or_create(kind='weekly',start=start,defaults={'end':end})
        reward=CompetitionReward.objects.create(period=period,player=self.player,rank=1,score=100,gems=10,coins=1000)
        url=f'/api/platform/rewards/{reward.pk}/claim/'
        self.assertEqual(self.client.post(url).data,self.client.post(url).data)
        self.assertEqual(self.client.post(f'/api/platform/rewards/{reward.pk}/ack/').status_code,200)
        self.assertEqual(self.client.post(url).status_code,400)
        self.assertEqual(self.client.get('/api/platform/rewards/').data,[])
        other=CompetitionReward.objects.create(period=period,player=self.other,rank=2,score=90,gems=7,coins=700)
        self.assertEqual(self.client.post(f'/api/platform/rewards/{other.pk}/claim/').status_code,400)

    def test_launch_retry_is_counted_once(self):
        data={'launch_id':str(uuid4()),'game_type':'bazar'}
        self.assertEqual(self.client.post('/api/platform/launch/',data).status_code,200)
        self.client.post('/api/platform/launch/',data)
        self.assertEqual(GameLaunch.objects.count(),1)
        catalog=self.client.get('/api/platform/games/').data
        self.assertEqual(next(g['play_count'] for g in catalog if g['game_type']=='bazar'),1)

    def test_device_enrollment_cannot_be_replaced(self):
        response=APIClient().post('/api/platform/session/',{'player_uuid':str(self.player.uuid),'token':'b'*48})
        self.assertIn(response.status_code,[401,403])
