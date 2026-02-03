from django.http import JsonResponse, HttpResponse
from django.shortcuts import get_object_or_404
from django.views.decorators.http import require_http_methods
from django.conf import settings
import random
import os
from .models import GameCategory, HangmanWord


@require_http_methods(["GET"])
def index(request):
    """Homepage for SözBil"""
    html = """
    <!DOCTYPE html>
    <html lang="tk">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SözBil - Türkmen Dili Oýuny</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                line-height: 1.6;
            }
            h1 { color: #333; }
            .app-icon { font-size: 60px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <div class="app-icon">📚</div>
        <h1>SözBil</h1>
        <p>Türkmen dilinde söz tapmaja oýuny</p>
        <p>Türkmen dilini öwreniň we söz baýlygyňyzy artdyryň!</p>
        <hr>
        <p><small>© 2026 Can Abdiyev</small></p>
    </body>
    </html>
    """
    return HttpResponse(html, content_type='text/html')


@require_http_methods(["GET"])
def api_random_word_all(request):
    """Get a random word from ALL active categories"""

    # Get all active words
    words = list(HangmanWord.objects.filter(
        is_active=True,
        category__is_active=True
    ).values('word', 'hint', 'difficulty'))

    if not words:
        return JsonResponse({'error': 'No words available'}, status=404)

    # Return random word
    word = random.choice(words)
    return JsonResponse(word)


@require_http_methods(["GET"])
def api_stats(request):
    """Get overall game statistics"""
    total_words = HangmanWord.objects.filter(is_active=True).count()

    words_by_difficulty = {
        'easy': HangmanWord.objects.filter(is_active=True, difficulty='easy').count(),
        'medium': HangmanWord.objects.filter(is_active=True, difficulty='medium').count(),
        'hard': HangmanWord.objects.filter(is_active=True, difficulty='hard').count(),
    }

    return JsonResponse({
        'total_words': total_words,
        'words_by_difficulty': words_by_difficulty
    })


@require_http_methods(["GET"])
def health_check(request):
    """Health check endpoint for monitoring"""
    return JsonResponse({'status': 'ok', 'service': 'Hangman API'})


@require_http_methods(["GET"])
def privacy_policy(request):
    """Serve privacy policy HTML"""
    # Go up one directory from BASE_DIR (which is hangman_project/) to project root
    project_root = settings.BASE_DIR.parent
    file_path = os.path.join(project_root, 'privacy_policy.html')

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return HttpResponse(content, content_type='text/html')
    except FileNotFoundError:
        return JsonResponse({
            'error': 'Privacy policy not found',
            'looking_for': file_path
        }, status=404)


@require_http_methods(["GET"])
def support_page(request):
    """Serve support HTML"""
    # Go up one directory from BASE_DIR (which is hangman_project/) to project root
    project_root = settings.BASE_DIR.parent
    file_path = os.path.join(project_root, 'support.html')

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return HttpResponse(content, content_type='text/html')
    except FileNotFoundError:
        return JsonResponse({
            'error': 'Support page not found',
            'looking_for': file_path
        }, status=404)
