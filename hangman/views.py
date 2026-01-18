from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.views.decorators.http import require_http_methods
from django.http import FileResponse
from django.conf import settings
import random
import os
from .models import GameCategory, HangmanWord


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
    file_path = os.path.join(settings.BASE_DIR, 'privacy_policy.html')
    if os.path.exists(file_path):
        return FileResponse(open(file_path, 'rb'), content_type='text/html')
    return JsonResponse({'error': 'Privacy policy not found'}, status=404)
