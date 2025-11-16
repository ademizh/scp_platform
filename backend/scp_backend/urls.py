from django.contrib import admin
from django.urls import path
from api.views import (
    ProductListView,
    SupplierRegisterView,
    ConsumerRegisterView,
    LoginView,
)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/products/", ProductListView.as_view()),

    path("api/auth/register-supplier/", SupplierRegisterView.as_view()),
    path("api/auth/register-consumer/", ConsumerRegisterView.as_view()),
    path("api/auth/login/", LoginView.as_view()),
]
