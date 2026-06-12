from django.db import migrations, models


class Migration(migrations.Migration):
    """
    Unify PuzzleImage.game_type to the single value 'puzzle'.
    Flutter always requests GET /api/puzzles/puzzle/ for both Puzzle and Süýşürme screens.
    Any existing rows with old values (jigsaw/sliding/memory) are updated here.
    """

    dependencies = [
        ('hangman', '0005_seed_partner_apps'),
    ]

    operations = [
        migrations.AlterField(
            model_name='puzzleimage',
            name='game_type',
            field=models.CharField(
                choices=[('puzzle', 'Puzzle / Süýşürme')],
                default='puzzle',
                max_length=20,
            ),
        ),
        migrations.RunSQL(
            "UPDATE hangman_puzzleimage SET game_type = 'puzzle' WHERE game_type != 'puzzle';",
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
