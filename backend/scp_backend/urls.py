from django.contrib import admin
from django.urls import path
from api.views import (
    ProductListView,
    SupplierRegisterView,
    ConsumerRegisterView,
    LoginView,
    LinkRequestCreateView,
    ConsumerLinksListView,
    SupplierIncomingLinksView,
    LinkApproveView,
    LinkRejectView,
)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/products/", ProductListView.as_view()),

    path("api/auth/register-supplier/", SupplierRegisterView.as_view()),
    path("api/auth/register-consumer/", ConsumerRegisterView.as_view()),
    path("api/auth/login/", LoginView.as_view()),
        # --- Link requests ---
    path("api/links/request/", LinkRequestCreateView.as_view()),
    path("api/links/consumer/<int:consumer_id>/", ConsumerLinksListView.as_view()),
    path("api/links/supplier/<int:supplier_id>/", SupplierIncomingLinksView.as_view()),
    path("api/links/<int:pk>/approve/", LinkApproveView.as_view()),
    path("api/links/<int:pk>/reject/", LinkRejectView.as_view()),

]
