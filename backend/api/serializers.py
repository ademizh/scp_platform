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
    Units,
    StockLevels,
    Prices,
    Orders,
    OrderItems,
)


# ---------- PRODUCTS ----------

class ProductSerializer(serializers.ModelSerializer):
    """
    DTO для каталога:
    - unit_code: kg / liter / pack
    - unit_name: человекочитаемое имя
    - price: текущая цена (из Prices)
    - stock: остаток (из StockLevels)
    - discount / delivery_time: логические поля из SRS
    """
    supplier_name = serializers.CharField(source="supplier.name", read_only=True)
    unit_code = serializers.CharField(source="unit.code", read_only=True)
    unit_name = serializers.CharField(source="unit.name", read_only=True)
    price = serializers.SerializerMethodField()
    stock = serializers.SerializerMethodField()
    discount = serializers.SerializerMethodField()
    delivery_time = serializers.SerializerMethodField()

    class Meta:
        model = Products
        fields = [
            "id",
            "supplier_id",
            "supplier_name",
            "sku",
            "name",
            "description",
            "unit_code",
            "unit_name",
            "price",
            "discount",
            "stock",
            "delivery_time",
        ]

    def get_price(self, obj):
        price = (
            Prices.objects.filter(product=obj)
            .order_by("-valid_from")
            .first()
        )
        return float(price.amount) if price else None

    def get_stock(self, obj):
        stock = (
            StockLevels.objects.filter(product=obj)
            .order_by("-updated_at")
            .first()
        )
        return float(stock.quantity) if stock else 0.0

    def get_discount(self, obj):
        # В БД отдельного поля нет, поэтому пока возвращаем 0.
        # Можно будет заменить, когда добавите колонку / таблицу для скидок.
        return 0.0

    def get_delivery_time(self, obj):
        # Аналогично скидке – логическое поле из SRS, пока заглушка.
        # Например, можно будет хранить в отдельной таблице.
        return None

class SupplierStaffSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source="user.full_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    role_code = serializers.CharField(source="role.code", read_only=True)
    role_name = serializers.CharField(source="role.name", read_only=True)

    class Meta:
        model = SupplierStaff
        fields = [
            "id",
            "supplier",
            "user",
            "full_name",
            "email",
            "role_code",
            "role_name",
            "is_active",
        ]


class SupplierStaffCreateSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=4)
    # мы создаём только manager / sales – owner создаётся при регистрации supplier
    role_code = serializers.ChoiceField(choices=["manager", "sales"])

    def validate_email(self, value):
        if Users.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists")
        return value

class ProductCreateUpdateSerializer(serializers.Serializer):
    """
    Для создания/обновления товара через API (CRUD).
    Используем unit_code (kg, liter, pack), а не raw unit_id.
    """

    sku = serializers.CharField(max_length=255)
    name = serializers.CharField(max_length=255)
    description = serializers.CharField(max_length=2000, allow_blank=True, required=False)
    unit_code = serializers.ChoiceField(choices=["kg", "liter", "pack"])
    price = serializers.DecimalField(max_digits=12, decimal_places=2)
    stock = serializers.DecimalField(max_digits=14, decimal_places=3)
    discount = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        required=False,
        default=0,
    )
    delivery_time = serializers.IntegerField(required=False, allow_null=True)


# ---------- AUTH / USERS ----------

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
        choices=["supplier", "consumer", "sales"],
        required=False,
        allow_null=True,
    )


# ---------- LINKS (Supplier–Consumer) ----------

class LinkRequestCreateSerializer(serializers.Serializer):
    consumer_id = serializers.IntegerField()
    supplier_id = serializers.IntegerField()


class ConsumerLinkSerializer(serializers.ModelSerializer):
    """
    Для consumer'а:
    id, supplier_id, supplier_name, status.
    """

    supplier_name = serializers.CharField(source="supplier.name", read_only=True)

    class Meta:
        model = SupplierConsumerLinks
        fields = ["id", "supplier_id", "supplier_name", "status"]


class SupplierIncomingLinkSerializer(serializers.ModelSerializer):
    """
    Для supplier'а:
    id, consumer_id, consumer_name, status.
    """

    consumer_name = serializers.CharField(source="consumer.name", read_only=True)

    class Meta:
        model = SupplierConsumerLinks
        fields = ["id", "consumer_id", "consumer_name", "status"]


# ---------- ORDERS ----------

class OrderItemInputSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    quantity = serializers.DecimalField(max_digits=14, decimal_places=3)


class OrderCreateSerializer(serializers.Serializer):
    """
    Тело запроса: создание заказа из корзины.
    items: [{product_id, quantity}, ...]
    """

    items = OrderItemInputSerializer(many=True)


class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)
    unit_code = serializers.CharField(source="product.unit.code", read_only=True)

    class Meta:
        model = OrderItems
        fields = [
            "id",
            "product_id",
            "product_name",
            "unit_code",
            "quantity",
            "unit_price",
            "line_total",
        ]


class OrderSerializer(serializers.ModelSerializer):
    supplier_name = serializers.CharField(source="supplier.name", read_only=True)
    consumer_name = serializers.CharField(source="consumer.name", read_only=True)
    items = OrderItemSerializer(source="orderitems_set", many=True, read_only=True)

    class Meta:
        model = Orders
        fields = [
            "id",
            "supplier_id",
            "supplier_name",
            "consumer_id",
            "consumer_name",
            "status",
            "total_amount",
            "created_at",
            "items",
        ]
        
class SupplierPublicSerializer(serializers.ModelSerializer):
    """Для списка поставщиков в поиске (Directory)"""
    class Meta:
        model = Suppliers
        fields = ['id', 'name', 'is_active']

from .models import (
    Orders, OrderItems, Suppliers, Products, Complaint  # ← ADD HERE
)
class ComplaintSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = "__all__"

class ComplaintCreateSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    message = serializers.CharField()


