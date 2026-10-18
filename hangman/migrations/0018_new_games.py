# 2026-10-17: adds the two new games (Kerpiç block puzzle, Halyçy match-3) to
# GameSession.game_type choices. Hand-written: choices only, no DB change.
# Do not let makemigrations add unrelated drift here (see 0017's note).

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("hangman", "0017_platform_v2"),
    ]

    operations = [
        migrations.AlterField(
            model_name='gamesession',
            name='game_type',
            field=models.CharField(choices=[('jellad', 'Jellad'), ('gunluk_soz', 'Günlük Söz'), ('krosword', 'Krosword'), ('suysurme', 'Süýşürme'), ('yatkeslik', 'Ýatkeşlik'), ('nanogram', 'Nanogram'), ('zehin', 'Zehin Oýunlary'), ('puzzle', 'Puzzle'), ('soz_zynjyry', 'Söz Zynjyry'), ('mina', 'Mina Oýny'), ('smash_rings', 'Şar Oýny'), ('hanlyk', 'Hanlyk'), ('tilki', 'Tilki'), ('kerpic', 'Kerpiç'), ('halycy', 'Halyçy')], max_length=20),
        ),
    ]
