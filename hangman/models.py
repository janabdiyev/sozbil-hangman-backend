from django.db import models
import uuid


class HangmanWord(models.Model):
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]

    word = models.CharField(max_length=100, help_text='Word to guess (uppercase)')
    hint = models.CharField(max_length=200, blank=True)
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['word']
        verbose_name_plural = 'Hangman Words'

    def __str__(self):
        return self.word

    def save(self, *args, **kwargs):
        self.word = self.word.upper()
        super().save(*args, **kwargs)


class PuzzleImage(models.Model):
    # All image-based games (Puzzle, Süýşürme) use the unified value 'puzzle'.
    # Flutter always calls GET /api/puzzles/puzzle/ for both screens.
    GAME_TYPE_CHOICES = [
        ('puzzle', 'Puzzle / Süýşürme'),
    ]

    title = models.CharField(max_length=100)
    image = models.ImageField(upload_to='puzzle_images/')
    game_type = models.CharField(max_length=20, choices=GAME_TYPE_CHOICES, default='puzzle')
    difficulty = models.CharField(
        max_length=10,
        choices=[('easy', 'Easy'), ('medium', 'Medium'), ('hard', 'Hard')],
        default='medium'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['game_type', 'difficulty', 'title']
        verbose_name_plural = 'Puzzle Images'

    def __str__(self):
        return f'{self.title} ({self.get_game_type_display()})'


class ExternalApp(models.Model):
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=200, blank=True)
    logo = models.ImageField(upload_to='app_logos/', blank=True, null=True)
    ios_url = models.URLField(blank=True)
    android_url = models.URLField(blank=True)
    order_position = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['order_position', 'name']
        verbose_name_plural = 'External Apps'

    def __str__(self):
        return self.name


class Player(models.Model):
    AVATAR_CHOICES = [
        ('eagle', '🦅'),
        ('wolf', '🐺'),
        ('lion', '🦁'),
        ('horse', '🐎'),
        ('fox', '🦊'),
        ('owl', '🦉'),
        ('bear', '🐻'),
        ('tiger', '🐯'),
        ('dragon', '🐉'),
        ('star', '⭐'),
    ]

    LEVEL_CHOICES = [
        ('baslangyc', 'Başlangyç'),
        ('okuwcy', 'Okuwçy'),
        ('oyuncy', 'Oýunçy'),
        ('ustat', 'Ussат'),
        ('meshur', 'Meşhur'),
        ('legenda', 'Legenda'),
    ]

    uuid = models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)
    display_name = models.CharField(max_length=50)
    location = models.CharField(max_length=100, blank=True, help_text='City, country — freetext')
    avatar_key = models.CharField(max_length=20, choices=AVATAR_CHOICES, default='eagle')
    xp = models.IntegerField(default=0)
    level = models.CharField(max_length=20, choices=LEVEL_CHOICES, default='baslangyc')
    streak_days = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_active = models.DateField(null=True, blank=True)
    last_streak_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-xp']

    def __str__(self):
        return f'{self.display_name} ({self.location})'

    def get_level_for_xp(self):
        if self.xp < 100:
            return 'baslangyc'
        elif self.xp < 300:
            return 'okuwcy'
        elif self.xp < 600:
            return 'oyuncy'
        elif self.xp < 1000:
            return 'ustat'
        elif self.xp < 2000:
            return 'meshur'
        return 'legenda'

    def update_level(self):
        new_level = self.get_level_for_xp()
        if self.level != new_level:
            self.level = new_level
            self.save(update_fields=['level'])


class GameSession(models.Model):
    GAME_TYPE_CHOICES = [
        ('jellad', 'Jellad'),
        ('gunluk_soz', 'Günlük Söz'),
        ('krosword', 'Krosword'),
        ('suysurme', 'Süýşürme'),
        ('yatkeslik', 'Ýatkeşlik'),
        ('nanogram', 'Nanogram'),
        ('zehin', 'Zehin Oýunlary'),
        ('puzzle', 'Puzzle'),
        ('soz_zynjyry', 'Söz Zynjyry'),
    ]

    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='sessions')
    game_type = models.CharField(max_length=20, choices=GAME_TYPE_CHOICES)
    word = models.ForeignKey(
        HangmanWord, on_delete=models.SET_NULL, null=True, blank=True, related_name='sessions'
    )
    won = models.BooleanField(default=False)
    wrong_guesses = models.IntegerField(default=0)
    score = models.IntegerField(default=0)
    played_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-played_at']

    def __str__(self):
        result = 'Win' if self.won else 'Loss'
        return f'{self.player.display_name} — {self.game_type} — {result} — {self.score}pts'

    @staticmethod
    def calculate_score(won, wrong_guesses, difficulty):
        if not won:
            return 0
        base = 100
        accuracy_bonus = max(0, (6 - wrong_guesses) * 15)
        difficulty_bonus = {'easy': 0, 'medium': 20, 'hard': 40}.get(difficulty, 0)
        return base + accuracy_bonus + difficulty_bonus


class DailyWord(models.Model):
    word = models.ForeignKey(HangmanWord, on_delete=models.CASCADE, related_name='daily_slots')
    date = models.DateField(unique=True, db_index=True)

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f'{self.date} — {self.word.word}'


class Achievement(models.Model):
    CONDITION_CHOICES = [
        ('streak_days', 'Streak Days'),
        ('games_won', 'Games Won'),
        ('total_xp', 'Total XP'),
        ('perfect_games', 'Perfect Games (0 wrong)'),
        ('daily_wins', 'Daily Word Wins'),
    ]

    name = models.CharField(max_length=100)
    name_tk = models.CharField(max_length=100, blank=True, help_text='Turkmen name')
    description_tk = models.CharField(max_length=200, blank=True)
    icon = models.CharField(max_length=10, default='🏆', help_text='Emoji icon')
    condition_type = models.CharField(max_length=30, choices=CONDITION_CHOICES)
    condition_value = models.IntegerField()
    xp_reward = models.IntegerField(default=50)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['condition_type', 'condition_value']

    def __str__(self):
        return self.name


class PlayerAchievement(models.Model):
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='achievements')
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('player', 'achievement')

    def __str__(self):
        return f'{self.player.display_name} — {self.achievement.name}'


class ChatMessage(models.Model):
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='chat_messages')
    message = models.TextField(max_length=500)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Chat Messages'

    def __str__(self):
        return f'{self.player.display_name}: {self.message[:50]}'
