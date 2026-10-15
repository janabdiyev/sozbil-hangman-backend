from django.db import models
import uuid


class HangmanWord(models.Model):
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]

    # 6-language rollout (2026-07): Turkmen is the original/default language — every
    # word seeded before this field existed is 'tk' (see migration 0009). English/
    # Russian/Turkish word pools were added via migrations 0010/0011/0012, and
    # Azerbaijani/Uzbek were added via 0014/0015 (0013 just widened this field's
    # choices). Filtered via ?lang= on /api/word/ and /api/words/ (defaults to 'tk'
    # when omitted, so the legacy Android app and Söz Zynjyry — which don't pass this
    # param — keep seeing exactly the Turkmen words they always have; Krosword now
    # passes a real value too, see krosword_screen.dart).
    LANGUAGE_CHOICES = [
        ('tk', 'Turkmen'),
        ('en', 'English'),
        ('ru', 'Russian'),
        ('tr', 'Turkish'),
        ('az', 'Azerbaijani'),
        ('uz', 'Uzbek'),
    ]

    word = models.CharField(max_length=100, help_text='Word to guess (uppercase)')
    hint = models.CharField(max_length=200, blank=True)
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    language = models.CharField(
        max_length=5, choices=LANGUAGE_CHOICES, default='tk', db_index=True,
        help_text='UI language this word belongs to',
    )
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
    location = models.CharField(max_length=100, blank=True, help_text='Legacy location')
    country_code = models.CharField(max_length=2, blank=True, db_index=True)
    platform_token_hash = models.CharField(max_length=128, blank=True)
    avatar_key = models.CharField(max_length=20, choices=AVATAR_CHOICES, default='eagle')
    xp = models.IntegerField(default=0)
    coins = models.IntegerField(default=0)
    level = models.CharField(max_length=20, choices=LEVEL_CHOICES, default='baslangyc')
    streak_days = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_active = models.DateField(null=True, blank=True)
    last_streak_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    # Platform v2 (2026-10-14)
    gems = models.IntegerField(default=0)
    gems_imported = models.BooleanField(default=False)
    frame_key = models.CharField(max_length=30, blank=True)
    friend_code = models.CharField(max_length=8, blank=True, db_index=True)
    chat_hidden = models.BooleanField(default=False, help_text='Moderation: hide this player from chat')

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
        ('mina', 'Mina Oýny'),
        ('smash_rings', 'Şar Oýny'),
        # 2026-10-14: the app has submitted these since they launched, but
        # they were missing here, so every Hanlyk/Tilki score got HTTP 400 and
        # never counted for XP, streaks or the leaderboard.
        ('hanlyk', 'Hanlyk'),
        ('tilki', 'Tilki'),
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
    country_code = models.CharField(max_length=2, blank=True, db_index=True)
    message = models.TextField(max_length=500)
    created_at = models.DateTimeField(auto_now_add=True)
    hidden = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Chat Messages'

    def __str__(self):
        return f'{self.player.display_name}: {self.message[:50]}'


class CompetitionPeriod(models.Model):
    kind = models.CharField(max_length=7)
    start = models.DateTimeField()
    end = models.DateTimeField()
    settled_at = models.DateTimeField(null=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['kind', 'start'], name='unique_competition_period')]


class CompetitionReward(models.Model):
    period = models.ForeignKey(CompetitionPeriod, on_delete=models.CASCADE)
    player = models.ForeignKey(Player, on_delete=models.CASCADE)
    rank = models.PositiveSmallIntegerField()
    score = models.PositiveIntegerField()
    gems = models.PositiveIntegerField()
    coins = models.PositiveIntegerField()
    claimed_at = models.DateTimeField(null=True)
    acknowledged_at = models.DateTimeField(null=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['period', 'player'], name='unique_competition_reward')]


class GameLaunch(models.Model):
    # A launch ID makes retries safe without changing any game implementation.
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    game_type = models.CharField(max_length=24, db_index=True)
    player = models.ForeignKey(Player, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)


class GamePlayBaseline(models.Model):
    game_type = models.CharField(max_length=24, primary_key=True)
    count = models.PositiveBigIntegerField(default=0)


# ════════════════════════════════════════════════════════════════════════════
#  Platform v2 (2026-10-14): accounts, cloud save, gem wallet, seasons, live
#  events, social. Everything below is additive — no existing table changes
#  except three new Player columns (gems, frame_key, friend_code).
# ════════════════════════════════════════════════════════════════════════════

class DeviceCredential(models.Model):
    """One per signed-in device. The legacy Player.platform_token_hash keeps
    working for the device that enrolled first; a restored account on a new
    phone gets a row here instead, so two phones can share one player."""
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='devices')
    token_hash = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used = models.DateTimeField(null=True, blank=True)


class PlayerIdentity(models.Model):
    PROVIDERS = [('apple', 'Apple'), ('google', 'Google')]
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='identities')
    provider = models.CharField(max_length=10, choices=PROVIDERS)
    subject = models.CharField(max_length=255)
    email = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['provider', 'subject'], name='uniq_identity'),
            models.UniqueConstraint(fields=['player', 'provider'], name='uniq_player_provider'),
        ]


class CloudSave(models.Model):
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='saves')
    namespace = models.CharField(max_length=40)
    data = models.TextField()
    version = models.PositiveIntegerField(default=1)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['player', 'namespace'], name='uniq_save')]


class GemTransaction(models.Model):
    """Append-only gem ledger. `ref` is a client/server idempotency key, so a
    retried request can never apply twice."""
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='gem_transactions')
    delta = models.IntegerField()
    balance_after = models.IntegerField()
    reason = models.CharField(max_length=40)
    ref = models.CharField(max_length=80)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['player', 'ref'], name='uniq_gem_ref')]
        indexes = [models.Index(fields=['player', 'created_at'])]


class Cosmetic(models.Model):
    """A profile frame (or later: other cosmetics) a player owns."""
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='cosmetics')
    key = models.CharField(max_length=30)
    source = models.CharField(max_length=30, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['player', 'key'], name='uniq_cosmetic')]


class Season(models.Model):
    """A 4-week-ish season. If none is active one is generated automatically
    for the current calendar month (see seasons.current_season), so the
    feature runs without admin work; create one in admin to customise."""
    key = models.CharField(max_length=40, unique=True)
    theme = models.CharField(max_length=30, default='classic')
    title = models.JSONField(default=dict, help_text='{"tk": ..., "en": ..., "ru": ..., "tr": ...}')
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    xp_per_tier = models.PositiveIntegerField(default=50)
    tiers = models.JSONField(default=list, help_text='[{"tier":1,"free":{"gems":2},"premium":{"gems":5,"frame":"carpet"}}, ...]')

    class Meta:
        ordering = ['-starts_at']

    def __str__(self):
        return self.key


class SeasonProgress(models.Model):
    season = models.ForeignKey(Season, on_delete=models.CASCADE, related_name='progress')
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='season_progress')
    xp = models.PositiveIntegerField(default=0)
    claimed_free = models.JSONField(default=list)
    claimed_premium = models.JSONField(default=list)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['season', 'player'], name='uniq_season_player')]


class LiveEvent(models.Model):
    KINDS = [
        ('game_of_week', 'Game of the week (XP multiplier for one game)'),
        ('double_xp', 'Season XP multiplier for every game'),
        ('community_goal', 'Community goal (wins counted together)'),
        ('announcement', 'Announcement only'),
    ]
    kind = models.CharField(max_length=20, choices=KINDS)
    game_type = models.CharField(max_length=24, blank=True, help_text='Blank = all games')
    country_code = models.CharField(max_length=2, blank=True, help_text='Blank = everyone')
    title = models.JSONField(default=dict)
    body = models.JSONField(default=dict, blank=True)
    xp_multiplier = models.FloatField(default=1.0)
    goal_target = models.PositiveIntegerField(default=0)
    reward_gems = models.PositiveIntegerField(default=0)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['starts_at']


class EventClaim(models.Model):
    event = models.ForeignKey(LiveEvent, on_delete=models.CASCADE)
    player = models.ForeignKey(Player, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['event', 'player'], name='uniq_event_claim')]


class ChatReport(models.Model):
    message = models.ForeignKey(ChatMessage, on_delete=models.CASCADE, related_name='reports')
    reporter = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='chat_reports')
    reason = models.CharField(max_length=30, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['message', 'reporter'], name='uniq_report')]


class PlayerBlock(models.Model):
    blocker = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='blocks_made')
    blocked = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='blocked_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['blocker', 'blocked'], name='uniq_block')]


class Friendship(models.Model):
    """Stored once per direction, so 'my friends' is a single indexed query."""
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='friendships')
    friend = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='+')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['player', 'friend'], name='uniq_friend')]


class Challenge(models.Model):
    code = models.CharField(max_length=12, unique=True)
    creator = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='challenges')
    game_type = models.CharField(max_length=24)
    score = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()


class ChallengeResult(models.Model):
    challenge = models.ForeignKey(Challenge, on_delete=models.CASCADE, related_name='results')
    player = models.ForeignKey(Player, on_delete=models.CASCADE)
    score = models.PositiveIntegerField()
    beat = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['challenge', 'player'], name='uniq_challenge_result')]
