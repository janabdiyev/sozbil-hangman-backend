from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import FileResponse
from django.views.generic import View
import os

class PrivacyPolicyView(View):
    def get(self, request):
        file_path = os.path.join(settings.BASE_DIR, 'privacy_policy.html')
        return FileResponse(open(file_path, 'rb'), content_type='text/html')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('privacy-policy/', PrivacyPolicyView.as_view(), name='privacy_policy'),
    path('', include('hangman.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Customize admin site
admin.site.site_header = "Hangman Game Admin"
admin.site.site_title = "Hangman Admin"
admin.site.index_title = "Manage Categories & Words"