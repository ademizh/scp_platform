from rest_framework import serializers
from .models import (
    Users,
    Suppliers,
    Consumers,
    SupplierStaffRoles,
    SupplierStaff,
    ConsumerUsers,
    Products,
)

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Products
        fields = ["id", "supplier_id", "sku", "name", "description"]


class SupplierRegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=4, write_only=True)
    full_name = serializers.CharField(max_length=255)
    supplier_name = serializers.CharField(max_length=255)

    def validate_email(self, value):
        if Users.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists")
        return value


class ConsumerRegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=4, write_only=True)
    full_name = serializers.CharField(max_length=255)
    consumer_name = serializers.CharField(max_length=255)

    def validate_email(self, value):
        if Users.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists")
        return value


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()
    login_as = serializers.ChoiceField(
        choices=["supplier", "consumer"],
        required=False,
        allow_null=True,
    )