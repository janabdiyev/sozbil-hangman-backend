from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0008_gamesession_game_types'),
    ]

    operations = [
        migrations.AddField(
            model_name='hangmanword',
            name='language',
            field=models.CharField(
                choices=[('tk', 'Turkmen'), ('en', 'English'), ('ru', 'Russian'), ('tr', 'Turkish')],
                db_index=True,
                default='tk',
                help_text='UI language this word belongs to',
                max_length=5,
            ),
        ),
    ]
