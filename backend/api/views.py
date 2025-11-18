from django.db import transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db import connection
from django.utils import timezone 

from .models import (
    Products,
    Users,
    Suppliers,
    Consumers,
    SupplierStaffRoles,
    SupplierStaff,
    ConsumerUsers,
    SupplierConsumerLinks, 
)
from .serializers import (
    ProductSerializer,
    SupplierRegisterSerializer,
    ConsumerRegisterSerializer,
    LoginSerializer,
    LinkRequestCreateSerializer,      
    ConsumerLinkSerializer,     
    SupplierIncomingLinkSerializer,
)


class ProductListView(APIView):
    def get(self, request):
        user_id = request.headers.get("X-User-Id") or request.query_params.get("user_id")
        if not user_id:
            return Response({"detail": "X-User-Id header or ?user_id= needed"}, status=status.HTTP_401_UNAUTHORIZED)

        try:
            int_user_id = int(user_id)
        except ValueError:
            return Response({"detail": "user_id must be integer"}, status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute("SELECT set_config('scp.current_user_id', %s, false);", [str(int_user_id)])

        qs = Products.objects.all().order_by("id")
        serializer = ProductSerializer(qs, many=True)
        return Response(serializer.data)


class SupplierRegisterView(APIView):
    """
    user
    supplier
    supplier_staff with 'owner'
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
    user
    consumer
    consumer_users
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
    email 
    check password
    give user_id + проверка, что такой supplier/consumer-аккаунт существует
    """

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        login_as = data.get("login_as")  # 'supplier' / 'consumer' / None

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
class LinkRequestCreateView(APIView):
    """
    POST /api/links/request/

    Создаёт (или переоткрывает) link consumer -> supplier
    со статусом 'pending'.
    """

    def post(self, request):
        serializer = LinkRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        consumer_id = data["consumer_id"]
        supplier_id = data["supplier_id"]

        # проверим, что такие supplier/consumer вообще есть
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

        # если линк уже был, но, например, был отклонён/заблокирован — можно переоткрыть
        if not created and link.status in ["rejected", "blocked"]:
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

    Список всех линков для данного consumer'а.
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

    Список запросов для supplier'а (и уже принятые тоже, если нужно).
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

    Подтверждение link request со стороны supplier'а.
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

    Для новых запросов = "заблокировать" (blocked),
    чтобы потребитель не мог ещё раз заспамить запросами.
    """

    def post(self, request, pk: int):
        try:
            link = SupplierConsumerLinks.objects.get(pk=pk)
        except SupplierConsumerLinks.DoesNotExist:
            return Response(
                {"detail": "Link not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            if link.status == "pending":
                link.status = "blocked"
            else:
                link.status = "removed"

            link.save(update_fields=["status"])
        except DataError as e:
            return Response(
                {"detail": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({"detail": "blocked"}, status=status.HTTP_200_OK)