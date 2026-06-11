from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0002_platform_upgrade'),
    ]

    operations = [
        migrations.CreateModel(
            name='ChatMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('message', models.TextField(max_length=500)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('player', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='chat_messages',
                    to='hangman.player',
                )),
            ],
            options={
                'verbose_name_plural': 'Chat Messages',
                'ordering': ['-created_at'],
            },
        ),
    ]
