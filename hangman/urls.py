from django.urls import path
from . import views, platform

app_name = 'hangman'

urlpatterns = [
    path('api/platform/session/', platform.platform_session),
    path('api/platform/games/', platform.game_catalog),
    path('api/platform/launch/', platform.game_launch),
    path('api/platform/rewards/', platform.rewards),
    path('api/platform/rewards/<int:reward_id>/claim/', platform.claim_reward),
    path('api/platform/rewards/<int:reward_id>/ack/', platform.ack_reward),
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
