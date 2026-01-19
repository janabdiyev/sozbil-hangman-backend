from django.urls import path
from . import views

app_name = 'hangman'

urlpatterns = [
    path('api/word/', views.api_random_word_all, name='api_random_word_all'),
    path('api/stats/', views.api_stats, name='api_stats'),
    path('health/', views.health_check, name='health_check'),
    path('privacy-policy.html', views.privacy_policy, name='privacy_policy'),
    path('support.html', views.support_page, name='support_page'),

]
