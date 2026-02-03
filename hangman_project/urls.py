from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse
import os


def app_ads_txt(request):
    # Try multiple possible locations
    possible_paths = [
        # hangman_project/app-ads.txt
        os.path.join(settings.BASE_DIR, 'app-ads.txt'),
        os.path.join(settings.BASE_DIR.parent, 'app-ads.txt'),  # project root
        '/opt/render/project/src/app-ads.txt',  # Render absolute path
    ]

    for file_path in possible_paths:
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    return HttpResponse(f.read(), content_type="text/plain; charset=utf-8")
            except Exception as e:
                continue

    return HttpResponse("app-ads.txt not found", status=404, content_type="text/plain")


urlpatterns = [
    path('app-ads.txt', app_ads_txt),
    path('admin/', admin.site.urls),
    path('', include('hangman.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL,
                          document_root=settings.MEDIA_ROOT)

# Customize admin site
admin.site.site_header = "Hangman Game Admin"
admin.site.site_title = "Hangman Admin"
admin.site.index_title = "Manage Categories & Words"
