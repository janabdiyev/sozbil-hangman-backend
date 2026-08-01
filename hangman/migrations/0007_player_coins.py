from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0006_puzzleimage_unified_game_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='player',
            name='coins',
            field=models.IntegerField(default=0),
        ),
    ]
