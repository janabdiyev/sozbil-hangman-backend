from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0001_initial'),
    ]

    operations = [
        # Remove category FK from HangmanWord — make it nullable first, then remove
        migrations.AlterField(
            model_name='hangmanword',
            name='category',
            field=models.ForeignKey(
                blank=True, null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='words', to='hangman.gamecategory'
            ),
        ),

        # PuzzleImage
        migrations.CreateModel(
            name='PuzzleImage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=100)),
                ('image', models.ImageField(upload_to='puzzle_images/')),
                ('game_type', models.CharField(choices=[
                    ('jigsaw', 'Puzzle (Jigsaw)'),
                    ('sliding', 'Süýşürme (Sliding)'),
                    ('memory', 'Ýatkeşlik (Memory)'),
                ], max_length=20)),
                ('difficulty', models.CharField(choices=[
                    ('easy', 'Easy'), ('medium', 'Medium'), ('hard', 'Hard')
                ], default='medium', max_length=10)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['game_type', 'difficulty', 'title'], 'verbose_name_plural': 'Puzzle Images'},
        ),

        # ExternalApp
        migrations.CreateModel(
            name='ExternalApp',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=100)),
                ('description', models.CharField(blank=True, max_length=200)),
                ('logo', models.ImageField(blank=True, null=True, upload_to='app_logos/')),
                ('ios_url', models.URLField(blank=True)),
                ('android_url', models.URLField(blank=True)),
                ('order_position', models.IntegerField(default=0)),
                ('is_active', models.BooleanField(default=True)),
            ],
            options={'ordering': ['order_position', 'name'], 'verbose_name_plural': 'External Apps'},
        ),

        # Player
        migrations.CreateModel(
            name='Player',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('uuid', models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)),
                ('display_name', models.CharField(max_length=50)),
                ('location', models.CharField(blank=True, max_length=100)),
                ('avatar_key', models.CharField(choices=[
                    ('eagle', '🦅'), ('wolf', '🐺'), ('lion', '🦁'), ('horse', '🐎'),
                    ('fox', '🦊'), ('owl', '🦉'), ('bear', '🐻'), ('tiger', '🐯'),
                    ('dragon', '🐉'), ('star', '⭐'),
                ], default='eagle', max_length=20)),
                ('xp', models.IntegerField(default=0)),
                ('level', models.CharField(choices=[
                    ('baslangyc', 'Başlangyç'), ('okuwcy', 'Okuwçy'), ('oyuncy', 'Oýunçy'),
                    ('ustat', 'Ussат'), ('meshur', 'Meşhur'), ('legenda', 'Legenda'),
                ], default='baslangyc', max_length=20)),
                ('streak_days', models.IntegerField(default=0)),
                ('longest_streak', models.IntegerField(default=0)),
                ('last_active', models.DateField(blank=True, null=True)),
                ('last_streak_date', models.DateField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['-xp']},
        ),

        # GameSession
        migrations.CreateModel(
            name='GameSession',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('game_type', models.CharField(choices=[
                    ('jellad', 'Jellad'), ('gunluk_soz', 'Günlük Söz'), ('krosword', 'Krosword'),
                    ('suysurme', 'Süýşürme'), ('yatkeslik', 'Ýatkeşlik'), ('nanogram', 'Nanogram'),
                    ('zehin', 'Zehin Oýunlary'), ('puzzle', 'Puzzle'), ('soz_zynjyry', 'Söz Zynjyry'),
                ], max_length=20)),
                ('won', models.BooleanField(default=False)),
                ('wrong_guesses', models.IntegerField(default=0)),
                ('score', models.IntegerField(default=0)),
                ('played_at', models.DateTimeField(auto_now_add=True)),
                ('player', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='sessions', to='hangman.player')),
                ('word', models.ForeignKey(blank=True, null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='sessions', to='hangman.hangmanword')),
            ],
            options={'ordering': ['-played_at']},
        ),

        # DailyWord
        migrations.CreateModel(
            name='DailyWord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('date', models.DateField(db_index=True, unique=True)),
                ('word', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='daily_slots', to='hangman.hangmanword')),
            ],
            options={'ordering': ['-date']},
        ),

        # Achievement
        migrations.CreateModel(
            name='Achievement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=100)),
                ('name_tk', models.CharField(blank=True, max_length=100)),
                ('description_tk', models.CharField(blank=True, max_length=200)),
                ('icon', models.CharField(default='🏆', max_length=10)),
                ('condition_type', models.CharField(choices=[
                    ('streak_days', 'Streak Days'), ('games_won', 'Games Won'),
                    ('total_xp', 'Total XP'), ('perfect_games', 'Perfect Games (0 wrong)'),
                    ('daily_wins', 'Daily Word Wins'),
                ], max_length=30)),
                ('condition_value', models.IntegerField()),
                ('xp_reward', models.IntegerField(default=50)),
                ('is_active', models.BooleanField(default=True)),
            ],
            options={'ordering': ['condition_type', 'condition_value']},
        ),

        # PlayerAchievement
        migrations.CreateModel(
            name='PlayerAchievement',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('earned_at', models.DateTimeField(auto_now_add=True)),
                ('achievement', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    to='hangman.achievement')),
                ('player', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='achievements', to='hangman.player')),
            ],
            options={'unique_together': {('player', 'achievement')}},
        ),
    ]
