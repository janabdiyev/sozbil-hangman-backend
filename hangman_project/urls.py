from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
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
