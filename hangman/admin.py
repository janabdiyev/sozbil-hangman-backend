from django.contrib import admin
from django.utils.html import format_html
from .models import (
    HangmanWord, PuzzleImage, ExternalApp,
    Player, GameSession, DailyWord, Achievement, PlayerAchievement, ChatMessage
)


@admin.register(HangmanWord)
class HangmanWordAdmin(admin.ModelAdmin):
    list_display = ['word', 'language', 'difficulty', 'hint_preview', 'is_active', 'created_at']
    list_filter = ['language', 'difficulty', 'is_active']
    search_fields = ['word', 'hint']
    ordering = ['language', 'word']
    list_editable = ['difficulty', 'is_active']

    fieldsets = (
        ('Word', {'fields': ('word', 'hint', 'language')}),
        ('Settings', {'fields': ('difficulty', 'is_active')}),
    )

    def hint_preview(self, obj):
        return obj.hint[:60] + '...' if obj.hint and len(obj.hint) > 60 else obj.hint or '—'
    hint_preview.short_description = 'Hint'

    actions = ['make_easy', 'make_medium', 'make_hard', 'activate', 'deactivate']

    def make_easy(self, request, qs): qs.update(difficulty='easy')
    make_easy.short_description = 'Mark as Easy'

    def make_medium(self, request, qs): qs.update(difficulty='medium')
    make_medium.short_description = 'Mark as Medium'

    def make_hard(self, request, qs): qs.update(difficulty='hard')
    make_hard.short_description = 'Mark as Hard'

    def activate(self, request, qs): qs.update(is_active=True)
    activate.short_description = 'Activate'

    def deactivate(self, request, qs): qs.update(is_active=False)
    deactivate.short_description = 'Deactivate'


@admin.register(PuzzleImage)
class PuzzleImageAdmin(admin.ModelAdmin):
    list_display = ['title', 'game_type', 'difficulty', 'image_preview', 'is_active']
    list_filter = ['game_type', 'difficulty', 'is_active']
    search_fields = ['title']
    list_editable = ['difficulty', 'is_active']

    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="height:40px;border-radius:4px;">', obj.image.url)
        return '—'
    image_preview.short_description = 'Preview'


@admin.register(ExternalApp)
class ExternalAppAdmin(admin.ModelAdmin):
    list_display = ['name', 'logo_preview', 'ios_url', 'android_url', 'order_position', 'is_active']
    list_editable = ['order_position', 'is_active']

    def logo_preview(self, obj):
        if obj.logo:
            return format_html('<img src="{}" style="height:40px;border-radius:4px;">', obj.logo.url)
        return '—'
    logo_preview.short_description = 'Logo'


@admin.register(Player)
class PlayerAdmin(admin.ModelAdmin):
    list_display = ['display_name', 'location', 'avatar_key', 'xp', 'level',
                    'streak_days', 'last_active', 'created_at']
    list_filter = ['level']
    search_fields = ['display_name', 'location']
    ordering = ['-xp']
    readonly_fields = ['uuid', 'xp', 'level', 'streak_days', 'longest_streak',
                       'last_active', 'last_streak_date', 'created_at']


@admin.register(GameSession)
class GameSessionAdmin(admin.ModelAdmin):
    list_display = ['player', 'game_type', 'word', 'won', 'wrong_guesses', 'score', 'played_at']
    list_filter = ['game_type', 'won', 'played_at']
    search_fields = ['player__display_name']
    ordering = ['-played_at']
    readonly_fields = ['player', 'game_type', 'word', 'won', 'wrong_guesses', 'score', 'played_at']


@admin.register(DailyWord)
class DailyWordAdmin(admin.ModelAdmin):
    list_display = ['date', 'word']
    ordering = ['-date']
    date_hierarchy = 'date'


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ['icon', 'name', 'name_tk', 'condition_type', 'condition_value', 'xp_reward', 'is_active']
    list_editable = ['xp_reward', 'is_active']
    list_filter = ['condition_type', 'is_active']


@admin.register(PlayerAchievement)
class PlayerAchievementAdmin(admin.ModelAdmin):
    list_display = ['player', 'achievement', 'earned_at']
    list_filter = ['achievement']
    ordering = ['-earned_at']


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ['player', 'message_preview', 'created_at']
    list_filter = ['created_at']
    search_fields = ['player__display_name', 'message']
    ordering = ['-created_at']
    readonly_fields = ['player', 'message', 'created_at']

    def message_preview(self, obj):
        return obj.message[:80] + '...' if len(obj.message) > 80 else obj.message
    message_preview.short_description = 'Message'


admin.site.site_header = 'Sözbil Platform Admin'
admin.site.site_title = 'Sözbil Admin'
admin.site.index_title = 'Platform Management'
