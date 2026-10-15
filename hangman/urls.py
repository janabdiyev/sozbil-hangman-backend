from django.urls import path
from . import views, platform, accounts, seasons, social

app_name = 'hangman'

urlpatterns = [
    path('api/platform/session/', platform.platform_session),
    path('api/platform/games/', platform.game_catalog),
    path('api/platform/launch/', platform.game_launch),
    path('api/platform/rewards/', platform.rewards),
    path('api/platform/rewards/<int:reward_id>/claim/', platform.claim_reward),
    path('api/platform/rewards/<int:reward_id>/ack/', platform.ack_reward),

    # Platform v2 (2026-10-14) — accounts, cloud save, gems, cosmetics
    path('api/platform/account/', accounts.account),
    path('api/platform/account/delete/', accounts.account_delete),
    path('api/platform/auth/link/', accounts.auth_link),
    path('api/platform/auth/restore/', accounts.auth_restore),
    path('api/platform/auth/unlink/', accounts.auth_unlink),
    path('api/platform/auth/apple-callback/', accounts.apple_android_callback),
    path('api/platform/saves/', accounts.saves),
    path('api/platform/saves/<str:namespace>/', accounts.save_detail),
    path('api/platform/wallet/', accounts.wallet),
    path('api/platform/wallet/sync/', accounts.wallet_sync),
    path('api/platform/cosmetics/', accounts.cosmetics),
    path('api/platform/cosmetics/buy/', accounts.cosmetics_buy),
    path('api/platform/cosmetics/equip/', accounts.cosmetics_equip),
    # seasons + live events
    path('api/platform/season/', seasons.season),
    path('api/platform/season/claim/', seasons.season_claim),
    path('api/platform/events/', seasons.events),
    path('api/platform/events/<int:event_id>/claim/', seasons.event_claim),
    # social
    path('api/chat/<int:message_id>/report/', social.chat_report),
    path('api/chat/<int:message_id>/block/', social.chat_block),
    path('api/platform/blocks/', social.blocks),
    path('api/platform/blocks/<int:block_id>/remove/', social.unblock),
    path('api/platform/friends/', social.friends),
    path('api/platform/friends/add/', social.friend_add),
    path('api/platform/friends/<int:friend_id>/remove/', social.friend_remove),
    path('api/platform/challenges/', social.challenge_create),
    path('api/platform/challenges/<str:code>/', social.challenge_detail),
    path('api/platform/challenges/<str:code>/result/', social.challenge_result),
    path('c/<str:code>', social.challenge_page),
    path('.well-known/apple-app-site-association', social.apple_app_site_association),
    path('.well-known/assetlinks.json', social.asset_links),
    path('', views.index, name='index'),

    # Legacy — keep for existing Android app
    path('api/word/', views.api_random_word, name='api_random_word'),

    # Words
    path('api/words/', views.api_all_words, name='api_all_words'),
    path('api/daily/', views.api_daily_word, name='api_daily_word'),

    # Player
    path('api/player/register/', views.api_player_register, name='api_player_register'),
    path('api/player/<uuid:player_uuid>/', views.api_player_detail, name='api_player_detail'),

    # Game
    path('api/score/', views.api_submit_score, name='api_submit_score'),

    # Leaderboard
    path('api/leaderboard/', views.api_leaderboard, name='api_leaderboard'),

    # Content
    path('api/puzzles/<str:game_type>/', views.api_puzzle_images, name='api_puzzle_images'),
    path('api/apps/', views.api_external_apps, name='api_external_apps'),
    path('api/achievements/', views.api_achievements, name='api_achievements'),

    # Chat
    path('api/chat/', views.api_chat, name='api_chat'),

    # Utility
    path('api/stats/', views.api_stats, name='api_stats'),
    path('health/', views.health_check, name='health_check'),
    path('privacy-policy.html', views.privacy_policy, name='privacy_policy'),
    path('support.html', views.support_page, name='support_page'),
    path('delete-account.html', views.delete_account_page, name='delete_account_page'),
]
