from rest_framework import serializers
from .models import (
    HangmanWord, Player, GameSession, DailyWord,
    PuzzleImage, ExternalApp, Achievement, PlayerAchievement, ChatMessage
)


class WordSerializer(serializers.ModelSerializer):
    class Meta:
        model = HangmanWord
        fields = ['id', 'word', 'hint', 'difficulty']


class PuzzleImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = PuzzleImage
        fields = ['id', 'title', 'image_url', 'game_type', 'difficulty']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return None


class ExternalAppSerializer(serializers.ModelSerializer):
    logo_url = serializers.SerializerMethodField()

    class Meta:
        model = ExternalApp
        fields = ['id', 'name', 'description', 'logo_url', 'ios_url', 'android_url']

    def get_logo_url(self, obj):
        request = self.context.get('request')
        if obj.logo and request:
            return request.build_absolute_uri(obj.logo.url)
        return None


class AchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = ['id', 'name', 'name_tk', 'description_tk', 'icon',
                  'condition_type', 'condition_value', 'xp_reward']


class PlayerAchievementSerializer(serializers.ModelSerializer):
    achievement = AchievementSerializer(read_only=True)

    class Meta:
        model = PlayerAchievement
        fields = ['achievement', 'earned_at']


class PlayerSerializer(serializers.ModelSerializer):
    achievements = PlayerAchievementSerializer(many=True, read_only=True)
    level_display = serializers.SerializerMethodField()
    avatar_emoji = serializers.SerializerMethodField()

    class Meta:
        model = Player
        fields = [
            'uuid', 'display_name', 'location', 'avatar_key', 'avatar_emoji',
            'xp', 'level', 'level_display', 'streak_days', 'longest_streak',
            'last_active', 'created_at', 'achievements'
        ]
        read_only_fields = ['uuid', 'xp', 'level', 'streak_days', 'longest_streak', 'created_at']

    def get_level_display(self, obj):
        return dict(Player.LEVEL_CHOICES).get(obj.level, obj.level)

    def get_avatar_emoji(self, obj):
        return dict(Player.AVATAR_CHOICES).get(obj.avatar_key, '🦅')


class PlayerCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Player
        fields = ['uuid', 'display_name', 'location', 'avatar_key']

    def validate_uuid(self, value):
        if Player.objects.filter(uuid=value).exists():
            raise serializers.ValidationError('Player with this UUID already exists.')
        return value


class PlayerUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Player
        fields = ['display_name', 'location', 'avatar_key']


class GameSessionCreateSerializer(serializers.Serializer):
    player_uuid = serializers.UUIDField()
    game_type = serializers.ChoiceField(choices=GameSession.GAME_TYPE_CHOICES)
    word_id = serializers.IntegerField(required=False, allow_null=True)
    won = serializers.BooleanField()
    wrong_guesses = serializers.IntegerField(min_value=0, max_value=6)


class LeaderboardEntrySerializer(serializers.Serializer):
    rank = serializers.IntegerField()
    uuid = serializers.UUIDField()
    display_name = serializers.CharField()
    location = serializers.CharField()
    avatar_key = serializers.CharField()
    avatar_emoji = serializers.CharField()
    total_score = serializers.IntegerField()
    games_won = serializers.IntegerField()
    streak_days = serializers.IntegerField()
    level = serializers.CharField()


class DailyWordSerializer(serializers.ModelSerializer):
    word = WordSerializer(read_only=True)

    class Meta:
        model = DailyWord
        fields = ['date', 'word']


class ChatMessageSerializer(serializers.ModelSerializer):
    display_name = serializers.CharField(source='player.display_name', read_only=True)
    avatar_key = serializers.CharField(source='player.avatar_key', read_only=True)
    avatar_emoji = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = ['id', 'display_name', 'avatar_key', 'avatar_emoji', 'message', 'created_at']

    def get_avatar_emoji(self, obj):
        return dict(Player.AVATAR_CHOICES).get(obj.player.avatar_key, '🦅')


class ChatMessageCreateSerializer(serializers.Serializer):
    player_uuid = serializers.UUIDField()
    message = serializers.CharField(max_length=500, allow_blank=False)
