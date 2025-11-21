from django.contrib import admin
from django.urls import path

from api.views import (
    ProductListView,
    ProductDetailView,
    SupplierRegisterView,
    ConsumerRegisterView,
    LoginView,
    LinkRequestCreateView,
    ConsumerLinksListView,
    SupplierIncomingLinksView,
    LinkApproveView,
    LinkRejectView,
    OrderListCreateView,
    OrderAcceptView,
    OrderRejectView,
    SupplierDirectoryView,
    SupplierStaffListCreateView,    
    SupplierStaffDeactivateView, 
)

urlpatterns = [
    path("admin/", admin.site.urls),

    # PRODUCTS
    path("api/products/", ProductListView.as_view()),
    path("api/products/<int:pk>/", ProductDetailView.as_view()),

    # AUTH
    path("api/auth/register-supplier/", SupplierRegisterView.as_view()),
    path("api/auth/register-consumer/", ConsumerRegisterView.as_view()),
    path("api/auth/login/", LoginView.as_view()),

    # LINK REQUESTS
    path("api/links/request/", LinkRequestCreateView.as_view()),
    path("api/links/consumer/<int:consumer_id>/", ConsumerLinksListView.as_view()),
    path("api/links/supplier/<int:supplier_id>/", SupplierIncomingLinksView.as_view()),
    path("api/links/<int:pk>/approve/", LinkApproveView.as_view()),
    path("api/links/<int:pk>/reject/", LinkRejectView.as_view()),

    # ORDERS
    path("api/orders/", OrderListCreateView.as_view()),
    path("api/orders/<int:pk>/accept/", OrderAcceptView.as_view()),
    path("api/orders/<int:pk>/reject/", OrderRejectView.as_view()),
    path("api/suppliers/directory/", SupplierDirectoryView.as_view()),
    path("api/suppliers/<int:supplier_id>/staff/", SupplierStaffListCreateView.as_view()),
    path("api/suppliers/staff/<int:pk>/deactivate/", SupplierStaffDeactivateView.as_view()),


]
