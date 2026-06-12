from django.db import migrations

PARTNER_APPS = [
    {
        'name': 'Miclab',
        'description': 'Türkmen aýdymlarynyň karaoke programmasy',
        'ios_url': 'https://apps.apple.com/tr/app/miclab/id6755495875',
        'android_url': 'https://play.google.com/store/apps/details?id=com.miclab.app',
        'order_position': 1,
    },
    {
        'name': 'Dilbil',
        'description': 'Türkmen dili öwrenmek üçin programma',
        'ios_url': 'https://apps.apple.com/tr/app/dilbil/id6760611346',
        'android_url': 'https://play.google.com/store/apps/details?id=com.dilbil.app',
        'order_position': 2,
    },
]


def seed_partner_apps(apps, schema_editor):
    ExternalApp = apps.get_model('hangman', 'ExternalApp')
    for app in PARTNER_APPS:
        obj, created = ExternalApp.objects.get_or_create(
            name=app['name'],
            defaults={
                'description': app['description'],
                'ios_url': app['ios_url'],
                'android_url': app['android_url'],
                'order_position': app['order_position'],
                'is_active': True,
            },
        )
        if not created:
            # Update URLs if the record already exists
            obj.ios_url = app['ios_url']
            obj.android_url = app['android_url']
            obj.order_position = app['order_position']
            obj.is_active = True
            obj.save()


def unseed_partner_apps(apps, schema_editor):
    pass  # no-op on rollback


class Migration(migrations.Migration):

    dependencies = [
        ('hangman', '0004_seed_words'),
    ]

    operations = [
        migrations.RunPython(seed_partner_apps, reverse_code=unseed_partner_apps),
    ]
