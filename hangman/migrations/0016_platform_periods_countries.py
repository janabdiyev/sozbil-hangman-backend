from datetime import timedelta
import uuid
from django.db import migrations, models
import django.db.models.deletion


def initialize_platform(apps, schema_editor):
    from django.utils import timezone
    from django.db.models import Count
    Period = apps.get_model('hangman', 'CompetitionPeriod')
    Baseline = apps.get_model('hangman', 'GamePlayBaseline')
    Session = apps.get_model('hangman', 'GameSession')
    now = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
    week, month = now - timedelta(days=now.weekday()), now.replace(day=1)
    for kind, start, end in [
        ('weekly', week, week + timedelta(days=7)),
        ('monthly', month, (month + timedelta(days=32)).replace(day=1)),
    ]:
        Period.objects.get_or_create(kind=kind, start=start, defaults={'end': end})
    # Snapshot existing recorded plays once; future counts come from launches.
    for row in Session.objects.values('game_type').annotate(n=Count('pk')):
        Baseline.objects.get_or_create(game_type=row['game_type'], defaults={'count': row['n']})


class Migration(migrations.Migration):
    dependencies = [('hangman', '0015_seed_words_uz')]
    operations = [
        migrations.AddField('player', 'country_code', models.CharField(max_length=2, blank=True, db_index=True)),
        migrations.AddField('player', 'platform_token_hash', models.CharField(max_length=128, blank=True)),
        migrations.AddField('chatmessage', 'country_code', models.CharField(max_length=2, blank=True, db_index=True)),
        migrations.AlterField('player', 'location', models.CharField(max_length=100, blank=True, help_text='Legacy location')),
        migrations.CreateModel(name='CompetitionPeriod', fields=[
            ('id', models.BigAutoField(primary_key=True, serialize=False, auto_created=True, verbose_name='ID')),
            ('kind', models.CharField(max_length=7)),
            ('start', models.DateTimeField()),
            ('end', models.DateTimeField()),
            ('settled_at', models.DateTimeField(null=True)),
        ]),
        migrations.CreateModel(name='CompetitionReward', fields=[
            ('id', models.BigAutoField(primary_key=True, serialize=False, auto_created=True, verbose_name='ID')),
            ('rank', models.PositiveSmallIntegerField()),
            ('score', models.PositiveIntegerField()),
            ('gems', models.PositiveIntegerField()),
            ('coins', models.PositiveIntegerField()),
            ('claimed_at', models.DateTimeField(null=True)),
            ('acknowledged_at', models.DateTimeField(null=True)),
            ('period', models.ForeignKey(to='hangman.competitionperiod', on_delete=django.db.models.deletion.CASCADE)),
            ('player', models.ForeignKey(to='hangman.player', on_delete=django.db.models.deletion.CASCADE)),
        ]),
        migrations.CreateModel(name='GameLaunch', fields=[
            ('id', models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False, serialize=False)),
            ('game_type', models.CharField(max_length=24, db_index=True)),
            ('created_at', models.DateTimeField(auto_now_add=True)),
            ('player', models.ForeignKey(to='hangman.player', on_delete=django.db.models.deletion.CASCADE)),
        ]),
        migrations.CreateModel(name='GamePlayBaseline', fields=[
            ('game_type', models.CharField(max_length=24, primary_key=True, serialize=False)),
            ('count', models.PositiveBigIntegerField(default=0)),
        ]),
        migrations.AddConstraint('competitionperiod', models.UniqueConstraint(fields=['kind', 'start'], name='unique_competition_period')),
        migrations.AddConstraint('competitionreward', models.UniqueConstraint(fields=['period', 'player'], name='unique_competition_reward')),
        migrations.RunPython(initialize_platform, migrations.RunPython.noop),
    ]
