from django.db import models

class GameCategory(models.Model):
    """Categories for organizing hangman words"""
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    icon_image = models.ImageField(upload_to='categories/', blank=True, null=True)
    order_position = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order_position', 'name']
        verbose_name_plural = "Game Categories"

    def __str__(self):
        return self.name

    def word_count(self):
        return self.words.filter(is_active=True).count()
    word_count.short_description = 'Active Words'


class HangmanWord(models.Model):
    """Words for hangman game"""
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]

    category = models.ForeignKey(GameCategory, on_delete=models.CASCADE, related_name='words')
    word = models.CharField(max_length=100, help_text="Word to guess (uppercase)")
    hint = models.CharField(max_length=200, blank=True, help_text="Hint for the player")
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['category', 'word']
        verbose_name_plural = "Hangman Words"

    def __str__(self):
        return f"{self.word} ({self.category.name})"

    def save(self, *args, **kwargs):
        # Auto-uppercase the word
        self.word = self.word.upper()
        super().save(*args, **kwargs)
