from django.db import transaction, connection
from django.utils import timezone

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from decimal import Decimal, ROUND_HALF_UP
import json, time, uuid
from .models import Incidents, ConsumerUsers
from .serializers import ComplaintSerializer, ComplaintCreateSerializer
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse



from .models import (
    Products,
    Users,
    Suppliers,
    Consumers,
    SupplierStaffRoles,
    SupplierStaff,
    ConsumerUsers,
    SupplierConsumerLinks,
    Units,
    StockLevels,
    Prices,
    Orders,
    OrderItems,

)
from .serializers import (
    ProductSerializer,
    ProductCreateUpdateSerializer,
    SupplierRegisterSerializer,
    ConsumerRegisterSerializer,
    LoginSerializer,
    LinkRequestCreateSerializer,
    ConsumerLinkSerializer,
    SupplierIncomingLinkSerializer,
    OrderCreateSerializer,
    OrderSerializer,
    SupplierPublicSerializer,
    SupplierStaffSerializer,      
    SupplierStaffCreateSerializer,
)


# ---------- helper: RLS ----------

def _set_rls_user(user_id: int):
    """
    Устанавливаем scp.current_user_id для RLS в Postgres.
    """
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT set_config('scp.current_user_id', %s, false);",
            [str(user_id)],
        )


def _get_int_user_id(request):
    user_id = request.headers.get("X-User-Id") or request.query_params.get("user_id")
    if not user_id:
        return None, Response(
            {"detail": "X-User-Id header or ?user_id= is required"},
            status=status.HTTP_401_UNAUTHORIZED,
        )
    try:
        return int(user_id), None
    except ValueError:
        return None, Response(
            {"detail": "user_id must be integer"},
            status=status.HTTP_400_BAD_REQUEST,
        )


# ---------- PRODUCTS ----------

class ProductListView(APIView):
    """
    GET  /api/products/           – каталог по RLS (consumer / supplier)
    POST /api/products/           – создать продукт (supplier)
    """

    def get(self, request):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)
        staff = (
            SupplierStaff.objects
            .filter(user_id=int_user_id, is_active=True)
            .select_related("supplier")
            .first()
        )
        if staff:
            # Supplier видит только свои товары
            qs = (
                Products.objects
                .filter(supplier=staff.supplier, is_active=True)
                .order_by("id")
            )
        else:
            # 2) Иначе пробуем как consumer
            cu = (
                ConsumerUsers.objects
                .filter(user_id=int_user_id, is_active=True)
                .select_related("consumer")
                .first()
            )

            if cu:
                consumer = cu.consumer
                # Берём всех suppliers с accepted-линком
                supplier_ids = SupplierConsumerLinks.objects.filter(
                    consumer=consumer,
                    status="accepted",
                ).values_list("supplier_id", flat=True)

                qs = (
                    Products.objects
                    .filter(supplier_id__in=supplier_ids, is_active=True)
                    .order_by("id")
                )
            else:
                # Если пользователь вообще не привязан – пустой каталог
                qs = Products.objects.none()

        serializer = ProductSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request):
        
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        serializer = ProductCreateUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        staff = (
            SupplierStaff.objects.filter(user_id=int_user_id, is_active=True)
            .select_related("supplier")
            .first()
        )
        if not staff:
            return Response(
                {"detail": "User is not an active supplier staff"},
                status=status.HTTP_403_FORBIDDEN,
            )

        supplier = staff.supplier
        if Products.objects.filter(supplier=supplier, sku=data["sku"]).exists():
            return Response(
                {"detail": f"Product with SKU '{data['sku']}' already exists."},
                status=status.HTTP_400_BAD_REQUEST
            )
        unit_code = data["unit_code"]
        unit, _ = Units.objects.get_or_create(
            code=unit_code,
            defaults={"name": unit_code},
        )

        now = timezone.now()
        image_url_safe = data.get("image_url") or ""
        with transaction.atomic():
            product = Products.objects.create(
                supplier=supplier,
                sku=data["sku"],
                name=data["name"],
                description=data.get("description", ""),
                unit=unit,
                is_active=True,
                created_at=now,
                image_url=image_url_safe,
            )

            # Price
            Prices.objects.create(
                product=product,
                currency="KZT",  # можно вынести в SRS / настройки
                amount=data["price"],
                valid_from=now.date(),
            )

            # Stock
            StockLevels.objects.create(
                product=product,
                quantity=data["stock"],
                updated_at=now,
            )

            # discount / delivery_time пока не сохраняем в БД (заглушка),
            # можно расширить схему позже.

        out = ProductSerializer(product)
        return Response(out.data, status=status.HTTP_201_CREATED)


class ProductDetailView(APIView):
    """
    GET    /api/products/<id>/    – детальная инфа
    PUT    /api/products/<id>/    – обновление товара
    DELETE /api/products/<id>/    – "удаление" (деактивация)
    """

    def get_object(self, pk):
        try:
            return Products.objects.get(pk=pk)
        except Products.DoesNotExist:
            return None

    def get(self, request, pk: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response
        _set_rls_user(int_user_id)

        product = self.get_object(pk)
        if not product:
            return Response({"detail": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = ProductSerializer(product)
        return Response(serializer.data)

    def put(self, request, pk: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response
        _set_rls_user(int_user_id)

        product = self.get_object(pk)
        if not product:
            return Response({"detail": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        # проверка, что пользователь – staff этого поставщика
        staff = SupplierStaff.objects.filter(
            user_id=int_user_id,
            supplier=product.supplier,
            is_active=True,
        ).first()
        if not staff:
            return Response(
                {"detail": "You are not allowed to modify this product"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ProductCreateUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            unit = Units.objects.get(code=data["unit_code"])
        except Units.DoesNotExist:
            return Response(
                {"detail": f"Unit with code '{data['unit_code']}' not found"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        image_url_safe = data.get("image_url") or ""
        now = timezone.now()
        with transaction.atomic():
            product.sku = data["sku"]
            product.name = data["name"]
            product.description = data.get("description", "")
            product.unit = unit
            product.image_url = image_url_safe
            product.save()

            Prices.objects.create(
                product=product,
                currency="KZT",
                amount=data["price"],
                valid_from=now.date(),
            )

            StockLevels.objects.create(
                product=product,
                quantity=data["stock"],
                updated_at=now,
            )

        out = ProductSerializer(product)
        return Response(out.data)

    def delete(self, request, pk: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response
        _set_rls_user(int_user_id)

        product = self.get_object(pk)
        if not product:
            return Response({"detail": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

        staff = SupplierStaff.objects.filter(
            user_id=int_user_id,
            supplier=product.supplier,
            is_active=True,
        ).first()
        if not staff:
            return Response(
                {"detail": "You are not allowed to delete this product"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # мягкое удаление – деактивация
        product.is_active = False
        product.save(update_fields=["is_active"])
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------- AUTH ----------

class SupplierRegisterView(APIView):
    """
    user + supplier + supplier_staff (owner)
    """

    def post(self, request):
        serializer = SupplierRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        with transaction.atomic():
            user = Users.objects.create(
                email=data["email"],
                password_hash=data["password"],
                full_name=data["full_name"],
                created_at=timezone.now(),
                is_active=True,
            )

            supplier = Suppliers.objects.create(
                name=data["supplier_name"],
            )

            owner_role = SupplierStaffRoles.objects.get(code="owner")

            SupplierStaff.objects.create(
                supplier=supplier,
                user=user,
                role=owner_role,
                is_active=True,
            )

        return Response(
            {
                "user_id": user.id,
                "supplier_id": supplier.id,
                "consumer_id": None,
                "roles": ["owner", "supplier"],
                "role": "supplier",
            },
            status=status.HTTP_201_CREATED,
        )


class ConsumerRegisterView(APIView):
    """
    user + consumer + consumer_users
    """

    def post(self, request):
        serializer = ConsumerRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        with transaction.atomic():
            user = Users.objects.create(
                email=data["email"],
                password_hash=data["password"],
                full_name=data["full_name"],
                created_at=timezone.now(),
                is_active=True,
            )

            consumer = Consumers.objects.create(
                name=data["consumer_name"],
            )

            ConsumerUsers.objects.create(
                consumer=consumer,
                user=user,
                is_active=True,
            )

        return Response(
            {
                "user_id": user.id,
                "supplier_id": None,
                "consumer_id": consumer.id,
                "roles": ["consumer"],
                "role": "consumer",
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """
    email + password
    login_as: supplier / consumer
    """

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        login_as = data.get("login_as")

        try:
            user = Users.objects.get(email=data["email"])
        except Users.DoesNotExist:
            return Response({"detail": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)

        if user.password_hash != data["password"]:
            return Response({"detail": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)

        supplier_staff = SupplierStaff.objects.filter(user=user, is_active=True)
        consumer_link = ConsumerUsers.objects.filter(user=user, is_active=True).first()

        roles = []
        supplier_id = None
        consumer_id = None

        has_supplier = supplier_staff.exists()
        has_consumer = consumer_link is not None

        if has_supplier:
            roles.extend([ss.role.code for ss in supplier_staff])
            if "supplier" not in roles:
                roles.append("supplier")
            supplier_id = supplier_staff.first().supplier_id

        if has_consumer:
            consumer_id = consumer_link.consumer_id
            if "consumer" not in roles:
                roles.append("consumer")

        if login_as == "supplier" and not has_supplier:
            return Response(
                {"detail": "Supplier account with this email does not exist"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if login_as == "consumer" and not has_consumer:
            return Response(
                {"detail": "Consumer account with this email does not exist"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        effective_role = login_as
        if effective_role is None:
            if has_supplier:
                effective_role = "supplier"
            elif has_consumer:
                effective_role = "consumer"

        return Response(
            {
                "user_id": user.id,
                "roles": roles,
                "supplier_id": supplier_id,
                "consumer_id": consumer_id,
                "login_as": effective_role,
            }
        )


# ---------- LINKS (Supplier–Consumer) ----------

class LinkRequestCreateView(APIView):
    """
    POST /api/links/request/
    Создаёт (или переоткрывает) link consumer -> supplier со статусом 'pending'.
    """

    def post(self, request):
        serializer = LinkRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        consumer_id = data["consumer_id"]
        supplier_id = data["supplier_id"]

        try:
            supplier = Suppliers.objects.get(id=supplier_id, is_active=True)
        except Suppliers.DoesNotExist:
            return Response(
                {"detail": "Supplier not found"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            consumer = Consumers.objects.get(id=consumer_id, is_active=True)
        except Consumers.DoesNotExist:
            return Response(
                {"detail": "Consumer not found"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        link, created = SupplierConsumerLinks.objects.get_or_create(
            supplier=supplier,
            consumer=consumer,
            defaults={
                "status": "pending",
                "created_at": timezone.now(),
            },
        )

        if not created and link.status in ["blocked", "removed"]:
            link.status = "pending"
            link.created_at = timezone.now()
            link.save(update_fields=["status", "created_at"])

        out = ConsumerLinkSerializer(link)
        return Response(
            out.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class ConsumerLinksListView(APIView):
    """
    GET /api/links/consumer/<consumer_id>/
    """

    def get(self, request, consumer_id: int):
        links = SupplierConsumerLinks.objects.filter(
            consumer_id=consumer_id
        ).order_by("-created_at")
        out = ConsumerLinkSerializer(links, many=True)
        return Response(out.data)


class SupplierIncomingLinksView(APIView):
    """
    GET /api/links/supplier/<supplier_id>/
    """

    def get(self, request, supplier_id: int):
        links = SupplierConsumerLinks.objects.filter(
            supplier_id=supplier_id
        ).order_by("-created_at")
        out = SupplierIncomingLinkSerializer(links, many=True)
        return Response(out.data)


class LinkApproveView(APIView):
    """
    POST /api/links/<id>/approve/
    """

    def post(self, request, pk: int):
        try:
            link = SupplierConsumerLinks.objects.get(pk=pk)
        except SupplierConsumerLinks.DoesNotExist:
            return Response(
                {"detail": "Link not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        link.status = "accepted"
        link.save(update_fields=["status"])
        return Response({"detail": "approved"})


class LinkRejectView(APIView):
    """
    POST /api/links/<id>/reject/
    """

    def post(self, request, pk: int):
        try:
            link = SupplierConsumerLinks.objects.get(pk=pk)
        except SupplierConsumerLinks.DoesNotExist:
            return Response(
                {"detail": "Link not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        if link.status == "pending":
            link.status = "blocked"
        else:
            link.status = "removed"

        link.save(update_fields=["status"])
        return Response({"detail": "blocked"}, status=status.HTTP_200_OK)


# ---------- ORDERS ----------

class OrderListCreateView(APIView):
    """
    POST /api/orders/            – consumer: создание заказа из корзины
    GET  /api/orders/?role=...   – список заказов (consumer / supplier)
    """

    def post(self, request):
        """
        Consumer создаёт заказ из корзины.
        """
        # 1) Определяем int user_id из заголовка / query
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        # 2) Проставляем current_user_id для RLS
        _set_rls_user(int_user_id)

        # 3) Проверяем, что юзер — активный consumer
        consumer_user = (
            ConsumerUsers.objects
            .filter(user_id=int_user_id, is_active=True)
            .select_related("consumer")
            .first()
        )
        if not consumer_user:
            return Response(
                {"detail": "User is not an active consumer"},
                status=status.HTTP_403_FORBIDDEN,
            )
        consumer = consumer_user.consumer

        # 4) Валидируем тело запроса
        serializer = OrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        items = data["items"]
        if not items:
            return Response(
                {"detail": "Order must contain at least one item"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 5) Загружаем продукты
        product_ids = [item["product_id"] for item in items]
        products = list(Products.objects.filter(id__in=product_ids))
        products_by_id = {p.id: p for p in products}

        if len(products_by_id) != len(product_ids):
            return Response(
                {"detail": "One or more products not found"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 6) Проверяем, что все товары от ОДНОГО supplier'а
        supplier_ids = {p.supplier_id for p in products}
        if len(supplier_ids) != 1:
            return Response(
                {"detail": "All products in order must belong to the same supplier"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        supplier_id = supplier_ids.pop()
        supplier = Suppliers.objects.get(id=supplier_id)

        # 7) Проверяем, что есть accepted link между этим consumer и supplier
        link_exists = SupplierConsumerLinks.objects.filter(
            supplier=supplier,
            consumer=consumer,
            status="accepted",
        ).exists()

        if not link_exists:
            return Response(
                {"detail": "You must have an accepted supplier link to place orders"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 8) Создаём заказ и позиции внутри транзакции
        now = timezone.now()
        total_amount = Decimal("0.00")
        
        with transaction.atomic():
            # Явно записываем created_at и created_by
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO orders
                        (supplier_id, consumer_id, status, total_amount,
                         created_at, created_by)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id;
                    """,
                    [
                        supplier.id,
                        consumer.id,
                        "pending",
                        Decimal("0.00"),
                        now,
                        int_user_id,
                    ],
                )
                order_id = cursor.fetchone()[0]

            # Загружаем только что созданный объект как Django-модель
            order = Orders.objects.get(id=order_id)

            order_items = []

            for item in items:
                prod = products_by_id[item["product_id"]]
                quantity = item["quantity"]

                price = (
                    Prices.objects.filter(product=prod)
                    .order_by("-valid_from")
                    .first()
                )
                if not price:
                    raise ValueError(f"No price for product {prod.id}")

                unit_price = price.amount
                line_total = unit_price * quantity
                total_amount += line_total

                order_items.append(
                    OrderItems(
                        order=order,
                        product=prod,
                        quantity=quantity,
                        unit_price=unit_price,
                        line_total=line_total,
                    )
                )

            OrderItems.objects.bulk_create(order_items)

            # Обновляем total_amount уже после подсчёта
            order.total_amount = total_amount
            order.save(update_fields=["total_amount"])

        out = OrderSerializer(order)
        return Response(out.data, status=status.HTTP_201_CREATED)

    def get(self, request):
        """
        Список заказов:
        - role=consumer: заказы текущего потребителя
        - role=supplier: заказы текущего поставщика
        """
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        role = request.query_params.get("role", "consumer")

        if role == "consumer":
            consumer_user = (
                ConsumerUsers.objects.filter(user_id=int_user_id, is_active=True)
                .select_related("consumer")
                .first()
            )
            if not consumer_user:
                return Response(
                    {"detail": "User is not an active consumer"},
                    status=status.HTTP_403_FORBIDDEN,
                )
            consumer = consumer_user.consumer
            qs = Orders.objects.filter(consumer=consumer).order_by("-created_at")

        elif role == "supplier":
            staff = (
                SupplierStaff.objects.filter(user_id=int_user_id, is_active=True)
                .select_related("supplier")
                .first()
            )
            if not staff:
                return Response(
                    {"detail": "User is not an active supplier staff"},
                    status=status.HTTP_403_FORBIDDEN,
                )
            supplier = staff.supplier
            qs = Orders.objects.filter(supplier=supplier).order_by("-created_at")

        else:
            return Response(
                {"detail": "role must be 'consumer' or 'supplier'"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        out = OrderSerializer(qs, many=True)
        return Response(out.data)

class OrderAcceptView(APIView):
    """
    POST /api/orders/<id>/accept/ – supplier подтверждает заказ
    """

    def post(self, request, pk: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        try:
            order = Orders.objects.get(pk=pk)
        except Orders.DoesNotExist:
            return Response(
                {"detail": "Order not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        staff = SupplierStaff.objects.filter(
            user_id=int_user_id,
            supplier=order.supplier,
            is_active=True,
        ).first()

        if not staff:
            return Response(
                {"detail": "You are not allowed to accept this order"},
                status=status.HTTP_403_FORBIDDEN,
            )

        
        order.status = "accepted"
        order.save(update_fields=["status"])
        return Response({"detail": "accepted"})


class OrderRejectView(APIView):
    """
    POST /api/orders/<id>/reject/ – supplier отклоняет заказ
    """

    def post(self, request, pk: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        try:
            order = Orders.objects.get(pk=pk)
        except Orders.DoesNotExist:
            return Response(
                {"detail": "Order not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        staff = SupplierStaff.objects.filter(
            user_id=int_user_id,
            supplier=order.supplier,
            is_active=True,
        ).first()

        if not staff:
            return Response(
                {"detail": "You are not allowed to reject this order"},
                status=status.HTTP_403_FORBIDDEN,
            )

    
        order.status = "rejected"
        order.save(update_fields=["status"])
        return Response({"detail": "rejected"})
class SupplierDirectoryView(APIView):
    """
    GET /api/suppliers/directory/
    Возвращает список всех активных поставщиков для поиска.
    """
    def get(self, request):
        # Берем всех активных поставщиков
        suppliers = Suppliers.objects.filter(is_active=True)
        serializer = SupplierPublicSerializer(suppliers, many=True)
        return Response(serializer.data)
    
# ---------- SUPPLIER STAFF (User Management) ----------

class SupplierStaffListCreateView(APIView):
    """
    GET  /api/suppliers/<supplier_id>/staff/       – список активных сотрудников поставщика
    POST /api/suppliers/<supplier_id>/staff/       – создать manager/sales

    Только владелец (owner) может смотреть и создавать staff.
    """

    def _ensure_owner(self, user_id: int, supplier_id: int):
        staff = (
            SupplierStaff.objects
            .select_related("role")
            .filter(
                supplier_id=supplier_id,
                user_id=user_id,
                is_active=True,
            )
            .first()
        )
        if not staff or staff.role.code != "owner":
            return None
        return staff

    def get(self, request, supplier_id: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        owner_staff = self._ensure_owner(int_user_id, supplier_id)
        if not owner_staff:
            return Response(
                {"detail": "Only owner can view supplier staff"},
                status=status.HTTP_403_FORBIDDEN,
            )

        qs = (
            SupplierStaff.objects
            .select_related("user", "role")
            .filter(supplier_id=supplier_id, is_active=True)
        )
        serializer = SupplierStaffSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, supplier_id: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        owner_staff = self._ensure_owner(int_user_id, supplier_id)
        if not owner_staff:
            return Response(
                {"detail": "Only owner can create staff"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = SupplierStaffCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            role = SupplierStaffRoles.objects.get(code=data["role_code"])
        except SupplierStaffRoles.DoesNotExist:
            return Response(
                {"detail": "Unknown role_code"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            user = Users.objects.create(
                email=data["email"],
                password_hash=data["password"],   # как в SupplierRegisterView
                full_name=data["full_name"],
                created_at=timezone.now(),
                is_active=True,
            )

            staff = SupplierStaff.objects.create(
                supplier_id=supplier_id,
                user=user,
                role=role,
                is_active=True,
            )

        out = SupplierStaffSerializer(staff)
        return Response(out.data, status=status.HTTP_201_CREATED)

class SupplierStaffDeactivateView(APIView):
    """
    POST /api/suppliers/staff/<pk>/deactivate/

    Только owner данного поставщика может деактивировать manager/sales.
    """

    def post(self, request, pk: int):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        try:
            staff_to_remove = SupplierStaff.objects.select_related("supplier", "role").get(pk=pk)
        except SupplierStaff.DoesNotExist:
            return Response(
                {"detail": "Staff not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        # ищем запись owner по тому же supplier
        owner_staff = (
            SupplierStaff.objects
            .select_related("role")
            .filter(
                supplier=staff_to_remove.supplier,
                user_id=int_user_id,
                is_active=True,
            )
            .first()
        )

        if not owner_staff or owner_staff.role.code != "owner":
            return Response(
                {"detail": "Only owner can remove staff"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # запрещаем owner удалить сам себя, чтобы не потерять доступ
        if staff_to_remove.user_id == int_user_id:
            return Response(
                {"detail": "Owner cannot remove themselves"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        staff_to_remove.is_active = False
        staff_to_remove.save(update_fields=["is_active"])

        return Response({"detail": "Staff deactivated"})
    
import os
from django.core.files.storage import default_storage
from django.conf import settings

MESSAGES = {}

@csrf_exempt
def messages_list(request, chat_id):
    if request.method == "GET":
        return JsonResponse(list(MESSAGES.get(chat_id, [])), safe=False)

    if request.method == "POST":
        # text or file messages
        if request.FILES:
            uploaded = request.FILES["file"]
            filename = f"{uuid.uuid4()}_{uploaded.name}"
            path = os.path.join("chat_uploads", filename)

            full_path = default_storage.save(path, uploaded)
            file_url = settings.MEDIA_URL + full_path

            msg = {
                "id": str(uuid.uuid4()),
                "authorId": request.POST.get("authorId"),
                "text": None,
                "fileUrl": file_url,
                "createdAt": int(time.time() * 1000),
            }

        else:
            body = json.loads(request.body)
            msg = {
                "id": str(uuid.uuid4()),
                "authorId": body["authorId"],
                "text": body["text"],
                "fileUrl": None,
                "createdAt": int(time.time() * 1000),
            }

        MESSAGES.setdefault(chat_id, []).append(msg)
        return JsonResponse(msg)


class ComplaintCreateView(APIView):
    """
    POST /api/incidents/
    Consumer sends complaint about an order.
    """

    def post(self, request):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        consumer_user = (
            ConsumerUsers.objects.filter(user_id=int_user_id, is_active=True)
            .select_related("consumer")
            .first()
        )

        if not consumer_user:
            return Response(
                {"detail": "User is not a consumer"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ComplaintCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            order = Orders.objects.get(
                id=data["order_id"],
                consumer=consumer_user.consumer,
            )
        except Orders.DoesNotExist:
            return Response(
                {"detail": "Order not found"},
                status=status.HTTP_404_NOT_FOUND,
            )
        # 2. Create the record in 'incidents' table
        # We must provide 'supplier' and 'created_by' because they are NOT NULL in scheme.sql
        try:
            complaint = Incidents.objects.create(
                order=order,
                consumer=consumer_user.consumer,
                supplier=order.supplier,        # <--- REQUIRED: From Order
                created_by_id=int_user_id,      # <--- REQUIRED: From Token/Header
                description=data.get("description", data.get("message")),
                status="open"
            )
        except Exception as e:
            # Catch DB errors (like missing fields) and print them
            print(f"Error creating incident: {e}")
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(ComplaintSerializer(complaint).data, status=status.HTTP_201_CREATED)
class SupplierIncidentListView(APIView):
    """
    GET /api/supplier/<supplier_id>/incidents/
    """
    def get(self, request, supplier_id: int):
        # 1. Authenticate
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        # 2. Set RLS User (CRITICAL STEP)
        _set_rls_user(int_user_id)
        
        is_staff = SupplierStaff.objects.filter(
            user_id=int_user_id, 
            supplier_id=supplier_id, 
            is_active=True
        ).exists()
        
        if not is_staff:
             return Response(
                {"detail": "You are not a staff member of this supplier"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 4. Query Incidents
        # We filter by supplier_id explicitly, RLS will further filter by visibility
        incidents = Incidents.objects.filter(supplier_id=supplier_id).order_by('-created_at')
        
        # 5. Serialize
        # You can use a serializer. If you don't have one for listing, create it or reuse
        data = []
        for inc in incidents:
            data.append({
                "id": inc.id,
                "order_id": inc.order_id,
                "supplier_id": inc.supplier_id,
                "consumer_id": inc.consumer_id,
                "message": inc.description, # Map description -> message
                "status": inc.status,
                "created_at": inc.created_at.isoformat(),
                "created_by": inc.created_by_id,
                "assigned_to": inc.assigned_to_id,
            })
        return Response(data)
class ConsumerIncidentListView(APIView):
    def get(self, request):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        # Filter where created_by == current user
        incidents = Incidents.objects.filter(created_by_id=int_user_id).order_by('-created_at')
        
        data = []
        for inc in incidents:
            data.append({
                "id": inc.id,
                "order_id": inc.order_id,
                "supplier_id": inc.supplier_id,
                "consumer_id": inc.consumer_id,
                "created_by": inc.created_by_id,
                "assigned_to": inc.assigned_to_id,
                "message": inc.description,
                "status": inc.status,
                "created_at": inc.created_at.isoformat(),
            })
        return Response(data)

# ---------------------------------------------------------
# 3. UPDATE STATUS: Resolve / In Progress
# ---------------------------------------------------------
class IncidentDetailView(APIView):
    def patch(self, request, incident_id):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        try:
            incident = Incidents.objects.get(id=incident_id)
        except Incidents.DoesNotExist:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        # Update status if provided
        new_status = request.data.get("status")
        if new_status:
            # Valid statuses: 'open', 'in_progress', 'resolved'
            incident.status = new_status
            
            # If staff picks it up ('in_progress'), assign to them if NULL
            if new_status == 'in_progress' and incident.assigned_to is None:
                incident.assigned_to_id = int_user_id
                
            incident.save()

        return Response({"status": "updated"}, status=status.HTTP_200_OK)
# ... existing imports ...

class IncidentEscalateView(APIView):
    """
    POST /api/incidents/<id>/escalate/
    Unassigns the incident so a Manager can pick it up.
    """
    def post(self, request, incident_id):
        int_user_id, error_response = _get_int_user_id(request)
        if error_response:
            return error_response

        _set_rls_user(int_user_id)

        try:
            incident = Incidents.objects.get(id=incident_id)
        except Incidents.DoesNotExist:
            return Response({"detail": "Not found"}, status=status.HTTP_404_NOT_FOUND)

        # Logic: Set to 'open' and remove the assigned person
        incident.status = 'open'
        incident.assigned_to = None 
        incident.save()

        return Response({"status": "escalated"}, status=status.HTTP_200_OK)