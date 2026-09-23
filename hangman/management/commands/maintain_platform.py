from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from hangman.models import ChatMessage
from hangman.platform import settle

class Command(BaseCommand):
    help = 'Settle finished weekly/monthly prizes and purge expired chat. Safe to repeat.'
    def handle(self, *args, **options):
        settle()
        count, _ = ChatMessage.objects.filter(created_at__lte=timezone.now() - timedelta(days=7)).delete()
        self.stdout.write(f'Periods settled; expired chat rows deleted: {count}')
