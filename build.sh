#!/usr/bin/env bash
set -o errexit

pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate

# Seed default achievements on first deploy
python manage.py shell -c "
from hangman.models import Achievement
if not Achievement.objects.exists():
    defaults = [
        ('7 gün yzly-yzyna', '7 Günlük', 'streak_days', 7, '🔥', 50),
        ('30 gün yzly-yzyna', '30 Günlük', 'streak_days', 30, '🏅', 200),
        ('Ilkinji ýeňiş', 'Başlangyç', 'games_won', 1, '🎯', 20),
        ('100 oýun', '100 Oýun', 'games_won', 100, '💯', 150),
        ('Kämil oýun', 'Kämil', 'perfect_games', 1, '⭐', 80),
        ('10 kämil oýun', '10 Kämil', 'perfect_games', 10, '✨', 200),
        ('500 XP', 'Ussат ýoly', 'total_xp', 500, '📚', 50),
        ('Günlük ýeňiji', 'Günlük Söz', 'daily_wins', 7, '📅', 100),
    ]
    for name_tk, name, ctype, cval, icon, xp in defaults:
        Achievement.objects.create(
            name=name, name_tk=name_tk, icon=icon,
            condition_type=ctype, condition_value=cval, xp_reward=xp
        )
    print(f'Seeded {len(defaults)} achievements.')
else:
    print('Achievements already exist, skipping seed.')
"

# Seed Miclab & Dilbil external apps on first deploy
python manage.py shell -c "
from hangman.models import ExternalApp
apps = [
    {
        'name': 'Miclab',
        'description': 'Türkmen karaoke programmasy — aydym ayt, lezzet al!',
        'ios_url': 'https://apps.apple.com/tr/app/miclab/id6755495875',
        'android_url': 'https://play.google.com/store/apps/details?id=com.miclab.app',
        'order_position': 1,
    },
    {
        'name': 'Dilbil',
        'description': 'Dil ögrenme programmasy — türkmen, iňlis we başgalar.',
        'ios_url': 'https://apps.apple.com/tr/app/dilbil/id6760611346',
        'android_url': 'https://play.google.com/store/apps/details?id=com.dilbil.app',
        'order_position': 2,
    },
]
for app_data in apps:
    obj, created = ExternalApp.objects.get_or_create(
        name=app_data['name'],
        defaults=app_data
    )
    if created:
        print(f'Created ExternalApp: {obj.name}')
    else:
        # Update URLs if already exists
        for k, v in app_data.items():
            setattr(obj, k, v)
        obj.save()
        print(f'Updated ExternalApp: {obj.name}')
"
