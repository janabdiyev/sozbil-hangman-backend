# 2026-11-25: adds Kükürtçöp (matchstick equations) to GameSession.game_type
# choices. Hand-written: choices only, no DB change.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("hangman", "0018_new_games"),
    ]

    operations = [
        migrations.AlterField(
            model_name='gamesession',
            name='game_type',
            field=models.CharField(choices=[('jellad', 'Jellad'), ('gunluk_soz', 'Günlük Söz'), ('krosword', 'Krosword'), ('suysurme', 'Süýşürme'), ('yatkeslik', 'Ýatkeşlik'), ('nanogram', 'Nanogram'), ('zehin', 'Zehin Oýunlary'), ('puzzle', 'Puzzle'), ('soz_zynjyry', 'Söz Zynjyry'), ('mina', 'Mina Oýny'), ('smash_rings', 'Şar Oýny'), ('hanlyk', 'Hanlyk'), ('tilki', 'Tilki'), ('kerpic', 'Kerpiç'), ('halycy', 'Halyçy'), ('kukurtcop', 'Kükürtçöp')], max_length=20),
        ),
    ]
