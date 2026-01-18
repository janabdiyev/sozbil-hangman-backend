from django.contrib import admin
from .models import GameCategory, HangmanWord

@admin.register(GameCategory)
class GameCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'word_count', 'order_position', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}
    ordering = ['order_position', 'name']
    list_editable = ['order_position', 'is_active']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'description', 'icon_image')
        }),
        ('Settings', {
            'fields': ('order_position', 'is_active')
        }),
    )


@admin.register(HangmanWord)
class HangmanWordAdmin(admin.ModelAdmin):
    list_display = ['word', 'category', 'difficulty', 'hint_preview', 'is_active', 'created_at']
    list_filter = ['category', 'difficulty', 'is_active', 'created_at']
    search_fields = ['word', 'hint']
    ordering = ['category', 'word']
    list_editable = ['difficulty', 'is_active']
    
    fieldsets = (
        ('Word Information', {
            'fields': ('category', 'word', 'hint')
        }),
        ('Settings', {
            'fields': ('difficulty', 'is_active')
        }),
    )
    
    def hint_preview(self, obj):
        """Show first 50 chars of hint"""
        if obj.hint:
            return obj.hint[:50] + '...' if len(obj.hint) > 50 else obj.hint
        return '-'
    hint_preview.short_description = 'Hint'
    
    actions = ['make_easy', 'make_medium', 'make_hard', 'activate_words', 'deactivate_words']
    
    def make_easy(self, request, queryset):
        queryset.update(difficulty='easy')
        self.message_user(request, f'{queryset.count()} words marked as Easy')
    make_easy.short_description = 'Mark as Easy'
    
    def make_medium(self, request, queryset):
        queryset.update(difficulty='medium')
        self.message_user(request, f'{queryset.count()} words marked as Medium')
    make_medium.short_description = 'Mark as Medium'
    
    def make_hard(self, request, queryset):
        queryset.update(difficulty='hard')
        self.message_user(request, f'{queryset.count()} words marked as Hard')
    make_hard.short_description = 'Mark as Hard'
    
    def activate_words(self, request, queryset):
        queryset.update(is_active=True)
        self.message_user(request, f'{queryset.count()} words activated')
    activate_words.short_description = 'Activate selected words'
    
    def deactivate_words(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f'{queryset.count()} words deactivated')
    deactivate_words.short_description = 'Deactivate selected words'
