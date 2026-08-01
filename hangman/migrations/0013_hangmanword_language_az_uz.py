from django.db import migrations, models


class Migration(migrations.Migration):
    """Widens HangmanWord.language's choices to add Azerbaijani ('az') and Uzbek
    ('uz'), ahead of the seed migrations that populate those two pools (0014/0015).
    Django CharField choices aren't enforced at the SQLite level, so this is a
    no-op for existing data — it only matters for admin-form validation and
    makemigrations bookkeeping."""

    dependencies = [
        ('hangman', '0012_seed_words_tr'),
    ]

    operations = [
        migrations.AlterField(
            model_name='hangmanword',
            name='language',
            field=models.CharField(
                choices=[
                    ('tk', 'Turkmen'),
                    ('en', 'English'),
                    ('ru', 'Russian'),
                    ('tr', 'Turkish'),
                    ('az', 'Azerbaijani'),
                    ('uz', 'Uzbek'),
                ],
                db_index=True,
                default='tk',
                help_text='UI language this word belongs to',
                max_length=5,
            ),
        ),
    ]
