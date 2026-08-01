from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0007_player_coins'),
    ]

    operations = [
        migrations.AlterField(
            model_name='gamesession',
            name='game_type',
            field=models.CharField(
                max_length=20,
                choices=[
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
                ],
            ),
        ),
    ]
