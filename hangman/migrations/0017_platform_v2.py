# Platform v2 (2026-10-14): accounts, cloud save, gems, seasons, events, social.
# Hand-trimmed: makemigrations also proposed unrelated drift (AlterField on old
# ids, DeleteModel GameCategory). Those were removed on purpose; see
# sozbil_flutter/docs/PLATFORM_UPDATE.md. Do not re-add them here.

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("hangman", "0016_platform_periods_countries"),
    ]

    operations = [
        migrations.CreateModel(
            name="Challenge",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("code", models.CharField(max_length=12, unique=True)),
                ("game_type", models.CharField(max_length=24)),
                ("score", models.PositiveIntegerField()),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("expires_at", models.DateTimeField()),
            ],
        ),
        migrations.CreateModel(
            name="ChallengeResult",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("score", models.PositiveIntegerField()),
                ("beat", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "challenge",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="results",
                        to="hangman.challenge",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="ChatReport",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("reason", models.CharField(blank=True, max_length=30)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="CloudSave",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("namespace", models.CharField(max_length=40)),
                ("data", models.TextField()),
                ("version", models.PositiveIntegerField(default=1)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.CreateModel(
            name="Cosmetic",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("key", models.CharField(max_length=30)),
                ("source", models.CharField(blank=True, max_length=30)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="DeviceCredential",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("token_hash", models.CharField(max_length=64, unique=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("last_used", models.DateTimeField(blank=True, null=True)),
            ],
        ),
        migrations.CreateModel(
            name="EventClaim",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="Friendship",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="GemTransaction",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("delta", models.IntegerField()),
                ("balance_after", models.IntegerField()),
                ("reason", models.CharField(max_length=40)),
                ("ref", models.CharField(max_length=80)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="LiveEvent",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "kind",
                    models.CharField(
                        choices=[
                            (
                                "game_of_week",
                                "Game of the week (XP multiplier for one game)",
                            ),
                            ("double_xp", "Season XP multiplier for every game"),
                            (
                                "community_goal",
                                "Community goal (wins counted together)",
                            ),
                            ("announcement", "Announcement only"),
                        ],
                        max_length=20,
                    ),
                ),
                (
                    "game_type",
                    models.CharField(
                        blank=True, help_text="Blank = all games", max_length=24
                    ),
                ),
                (
                    "country_code",
                    models.CharField(
                        blank=True, help_text="Blank = everyone", max_length=2
                    ),
                ),
                ("title", models.JSONField(default=dict)),
                ("body", models.JSONField(blank=True, default=dict)),
                ("xp_multiplier", models.FloatField(default=1.0)),
                ("goal_target", models.PositiveIntegerField(default=0)),
                ("reward_gems", models.PositiveIntegerField(default=0)),
                ("starts_at", models.DateTimeField()),
                ("ends_at", models.DateTimeField()),
                ("is_active", models.BooleanField(default=True)),
            ],
            options={
                "ordering": ["starts_at"],
            },
        ),
        migrations.CreateModel(
            name="PlayerBlock",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="PlayerIdentity",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "provider",
                    models.CharField(
                        choices=[("apple", "Apple"), ("google", "Google")],
                        max_length=10,
                    ),
                ),
                ("subject", models.CharField(max_length=255)),
                ("email", models.CharField(blank=True, max_length=255)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name="Season",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("key", models.CharField(max_length=40, unique=True)),
                ("theme", models.CharField(default="classic", max_length=30)),
                (
                    "title",
                    models.JSONField(
                        default=dict,
                        help_text='{"tk": ..., "en": ..., "ru": ..., "tr": ...}',
                    ),
                ),
                ("starts_at", models.DateTimeField()),
                ("ends_at", models.DateTimeField()),
                ("xp_per_tier", models.PositiveIntegerField(default=50)),
                (
                    "tiers",
                    models.JSONField(
                        default=list,
                        help_text='[{"tier":1,"free":{"gems":2},"premium":{"gems":5,"frame":"carpet"}}, ...]',
                    ),
                ),
            ],
            options={
                "ordering": ["-starts_at"],
            },
        ),
        migrations.CreateModel(
            name="SeasonProgress",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("xp", models.PositiveIntegerField(default=0)),
                ("claimed_free", models.JSONField(default=list)),
                ("claimed_premium", models.JSONField(default=list)),
            ],
        ),
        migrations.AddField(
            model_name="chatmessage",
            name="hidden",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="player",
            name="chat_hidden",
            field=models.BooleanField(
                default=False, help_text="Moderation: hide this player from chat"
            ),
        ),
        migrations.AddField(
            model_name="player",
            name="frame_key",
            field=models.CharField(blank=True, max_length=30),
        ),
        migrations.AddField(
            model_name="player",
            name="friend_code",
            field=models.CharField(blank=True, db_index=True, max_length=8),
        ),
        migrations.AddField(
            model_name="player",
            name="gems",
            field=models.IntegerField(default=0),
        ),
        migrations.AddField(
            model_name="player",
            name="gems_imported",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="seasonprogress",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="season_progress",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="seasonprogress",
            name="season",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="progress",
                to="hangman.season",
            ),
        ),
        migrations.AddField(
            model_name="playeridentity",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="identities",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="playerblock",
            name="blocked",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="blocked_by",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="playerblock",
            name="blocker",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="blocks_made",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="gemtransaction",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="gem_transactions",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="friendship",
            name="friend",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="+",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="friendship",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="friendships",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="eventclaim",
            name="event",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE, to="hangman.liveevent"
            ),
        ),
        migrations.AddField(
            model_name="eventclaim",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE, to="hangman.player"
            ),
        ),
        migrations.AddField(
            model_name="devicecredential",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="devices",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="cosmetic",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="cosmetics",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="cloudsave",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="saves",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="chatreport",
            name="message",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="reports",
                to="hangman.chatmessage",
            ),
        ),
        migrations.AddField(
            model_name="chatreport",
            name="reporter",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="chat_reports",
                to="hangman.player",
            ),
        ),
        migrations.AddField(
            model_name="challengeresult",
            name="player",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE, to="hangman.player"
            ),
        ),
        migrations.AddField(
            model_name="challenge",
            name="creator",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="challenges",
                to="hangman.player",
            ),
        ),
        migrations.AddConstraint(
            model_name="seasonprogress",
            constraint=models.UniqueConstraint(
                fields=("season", "player"), name="uniq_season_player"
            ),
        ),
        migrations.AddConstraint(
            model_name="playeridentity",
            constraint=models.UniqueConstraint(
                fields=("provider", "subject"), name="uniq_identity"
            ),
        ),
        migrations.AddConstraint(
            model_name="playeridentity",
            constraint=models.UniqueConstraint(
                fields=("player", "provider"), name="uniq_player_provider"
            ),
        ),
        migrations.AddConstraint(
            model_name="playerblock",
            constraint=models.UniqueConstraint(
                fields=("blocker", "blocked"), name="uniq_block"
            ),
        ),
        migrations.AddIndex(
            model_name="gemtransaction",
            index=models.Index(
                fields=["player", "created_at"], name="hangman_gem_player__884fc5_idx"
            ),
        ),
        migrations.AddConstraint(
            model_name="gemtransaction",
            constraint=models.UniqueConstraint(
                fields=("player", "ref"), name="uniq_gem_ref"
            ),
        ),
        migrations.AddConstraint(
            model_name="friendship",
            constraint=models.UniqueConstraint(
                fields=("player", "friend"), name="uniq_friend"
            ),
        ),
        migrations.AddConstraint(
            model_name="eventclaim",
            constraint=models.UniqueConstraint(
                fields=("event", "player"), name="uniq_event_claim"
            ),
        ),
        migrations.AddConstraint(
            model_name="cosmetic",
            constraint=models.UniqueConstraint(
                fields=("player", "key"), name="uniq_cosmetic"
            ),
        ),
        migrations.AddConstraint(
            model_name="cloudsave",
            constraint=models.UniqueConstraint(
                fields=("player", "namespace"), name="uniq_save"
            ),
        ),
        migrations.AddConstraint(
            model_name="chatreport",
            constraint=models.UniqueConstraint(
                fields=("message", "reporter"), name="uniq_report"
            ),
        ),
        migrations.AddConstraint(
            model_name="challengeresult",
            constraint=models.UniqueConstraint(
                fields=("challenge", "player"), name="uniq_challenge_result"
            ),
        ),
        # Hanlyk + Tilki scores were rejected by these choices (HTTP 400).
        migrations.AlterField(
            model_name='gamesession',
            name='game_type',
            field=models.CharField(choices=[('jellad', 'Jellad'), ('gunluk_soz', 'Günlük Söz'), ('krosword', 'Krosword'), ('suysurme', 'Süýşürme'), ('yatkeslik', 'Ýatkeşlik'), ('nanogram', 'Nanogram'), ('zehin', 'Zehin Oýunlary'), ('puzzle', 'Puzzle'), ('soz_zynjyry', 'Söz Zynjyry'), ('mina', 'Mina Oýny'), ('smash_rings', 'Şar Oýny'), ('hanlyk', 'Hanlyk'), ('tilki', 'Tilki')], max_length=20),
        ),
    ]
