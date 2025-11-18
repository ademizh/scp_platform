from rest_framework import serializers
from .models import (
    Users,
    Suppliers,
    Consumers,
    SupplierStaffRoles,
    SupplierStaff,
    ConsumerUsers,
    Products,
    SupplierConsumerLinks, 
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
class LinkRequestCreateSerializer(serializers.Serializer):
    
    consumer_id = serializers.IntegerField()
    supplier_id = serializers.IntegerField()


class ConsumerLinkSerializer(serializers.ModelSerializer):
    """
    То, что отдаём во Flutter для consumer'а:
    id, supplier_id, supplier_name, status.
    """
    supplier_name = serializers.CharField(source="supplier.name", read_only=True)

    class Meta:
        model = SupplierConsumerLinks
        fields = ["id", "supplier_id", "supplier_name", "status"]


class SupplierIncomingLinkSerializer(serializers.ModelSerializer):
    """
    То, что отдаём во Flutter для supplier'а:
    id, consumer_id, consumer_name, status.
    """
    consumer_name = serializers.CharField(source="consumer.name", read_only=True)

    class Meta:
        model = SupplierConsumerLinks
        fields = ["id", "consumer_id", "consumer_name", "status"]
