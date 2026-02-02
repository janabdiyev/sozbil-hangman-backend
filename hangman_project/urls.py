from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse
import os


def app_ads_txt(request):
    # app-ads.txt is located in /project/src/app-ads.txt (settings.BASE_DIR)
    file_path = os.path.join(settings.BASE_DIR, 'app-ads.txt')
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return HttpResponse(f.read(), content_type="text/plain; charset=utf-8")
    except FileNotFoundError:
        return HttpResponse("app-ads.txt not found", status=404, content_type="text/plain")


urlpatterns = [
    path('app-ads.txt', app_ads_txt),  # ✅ must be at root: /app-ads.txt
    path('admin/', admin.site.urls),
    path('', include('hangman.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Customize admin site
admin.site.site_header = "Hangman Game Admin"
admin.site.site_title = "Hangman Admin"
admin.site.index_title = "Manage Categories & Words"
