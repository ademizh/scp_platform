# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models
from django.utils import timezone

class AuthGroup(models.Model):
    name = models.CharField(unique=True, max_length=150)

    class Meta:
        managed = False
        db_table = 'auth_group'


class AuthGroupPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)
    permission = models.ForeignKey('AuthPermission', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_group_permissions'
        unique_together = (('group', 'permission'),)


class AuthPermission(models.Model):
    name = models.CharField(max_length=255)
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING)
    codename = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'auth_permission'
        unique_together = (('content_type', 'codename'),)


class AuthUser(models.Model):
    password = models.CharField(max_length=128)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.BooleanField()
    username = models.CharField(unique=True, max_length=150)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)
    email = models.CharField(max_length=254)
    is_staff = models.BooleanField()
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    
    class Meta:
        managed = False
        db_table = 'auth_user'


class AuthUserGroups(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_groups'
        unique_together = (('user', 'group'),)


class AuthUserUserPermissions(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    permission = models.ForeignKey(AuthPermission, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_user_permissions'
        unique_together = (('user', 'permission'),)


class ChatParticipants(models.Model):
    id = models.BigAutoField(primary_key=True)
    chat = models.ForeignKey('Chats', models.DO_NOTHING)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    role = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'chat_participants'
        unique_together = (('chat', 'user'),)


class Chats(models.Model):
    id = models.BigAutoField(primary_key=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'chats'


class ConsumerUsers(models.Model):
    id = models.BigAutoField(primary_key=True)
    consumer = models.ForeignKey('Consumers', models.DO_NOTHING)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    is_active = models.BooleanField()

    class Meta:
        managed = False
        db_table = 'consumer_users'
        unique_together = (('consumer', 'user'),)


class Consumers(models.Model):
    id = models.BigAutoField(primary_key=True)
    name = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)   # 👈 пригодится для регистрации потребителя
    is_active = models.BooleanField(default=True)

    class Meta:
        managed = False
        db_table = 'consumers'


class DjangoAdminLog(models.Model):
    action_time = models.DateTimeField()
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.CharField(max_length=200)
    action_flag = models.SmallIntegerField()
    change_message = models.TextField()
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING, blank=True, null=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'django_admin_log'


class DjangoContentType(models.Model):
    app_label = models.CharField(max_length=100)
    model = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'django_content_type'
        unique_together = (('app_label', 'model'),)


class DjangoMigrations(models.Model):
    id = models.BigAutoField(primary_key=True)
    app = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    applied = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_migrations'


class DjangoSession(models.Model):
    session_key = models.CharField(primary_key=True, max_length=40)
    session_data = models.TextField()
    expire_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_session'


class Incidents(models.Model):
    id = models.BigAutoField(primary_key=True)
    order = models.ForeignKey('Orders', models.DO_NOTHING)
    supplier = models.ForeignKey('Suppliers', models.DO_NOTHING)
    consumer = models.ForeignKey(Consumers, models.DO_NOTHING)
    status = models.TextField()  # This field type is a guess.
    created_at = models.DateTimeField()
    created_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='created_by')
    assigned_to = models.ForeignKey('Users', models.DO_NOTHING, db_column='assigned_to', related_name='incidents_assigned_to_set', blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    archived_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)


    class Meta:
        managed = False
        db_table = 'incidents'


class Messages(models.Model):
    id = models.BigAutoField(primary_key=True)
    chat = models.ForeignKey(Chats, models.DO_NOTHING)
    sender = models.ForeignKey('Users', models.DO_NOTHING)
    text = models.TextField(blank=True, null=True)
    file_url = models.TextField(blank=True, null=True)
    attachment_type = models.TextField()  # This field type is a guess.
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'messages'


class OrderItems(models.Model):
    id = models.BigAutoField(primary_key=True)
    order = models.ForeignKey('Orders', models.DO_NOTHING)
    product = models.ForeignKey('Products', models.DO_NOTHING)
    quantity = models.DecimalField(max_digits=14, decimal_places=3)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    line_total = models.DecimalField(max_digits=14, decimal_places=2)

    class Meta:
        managed = False
        db_table = 'order_items'


class Orders(models.Model):
    id = models.BigAutoField(primary_key=True)
    supplier = models.ForeignKey('Suppliers', models.DO_NOTHING)
    consumer = models.ForeignKey(Consumers, models.DO_NOTHING)
    status = models.TextField()  # This field type is a guess.
    total_amount = models.DecimalField(max_digits=14, decimal_places=2, blank=True, null=True)
    created_at = models.DateTimeField()
    created_by = models.ForeignKey('Users', models.DO_NOTHING, db_column='created_by')
    archived_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'orders'


class Prices(models.Model):
    id = models.BigAutoField(primary_key=True)
    product = models.ForeignKey('Products', models.DO_NOTHING)
    currency = models.TextField()
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    valid_from = models.DateField()
    valid_to = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'prices'


class Products(models.Model):
    id = models.BigAutoField(primary_key=True)
    supplier = models.ForeignKey('Suppliers', models.DO_NOTHING)
    sku = models.TextField()
    name = models.TextField()
    description = models.TextField(blank=True, null=True)
    unit = models.ForeignKey('Units', models.DO_NOTHING)
    is_active = models.BooleanField()
    created_at = models.DateTimeField()
    #image_url = models.TextField(blank=True, null=True)
    class Meta:
        managed = False
        db_table = 'products'
        unique_together = (('supplier', 'sku'),)


class StockLevels(models.Model):
    id = models.BigAutoField(primary_key=True)
    product = models.ForeignKey(Products, models.DO_NOTHING)
    quantity = models.DecimalField(max_digits=14, decimal_places=3)
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'stock_levels'


class SupplierConsumerLinks(models.Model):
    id = models.BigAutoField(primary_key=True)
    supplier = models.ForeignKey('Suppliers', models.DO_NOTHING)
    consumer = models.ForeignKey(Consumers, models.DO_NOTHING)
    status = models.TextField()  # This field type is a guess.
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'supplier_consumer_links'
        unique_together = (('supplier', 'consumer'),)


class SupplierStaff(models.Model):
    id = models.BigAutoField(primary_key=True)
    supplier = models.ForeignKey('Suppliers', models.DO_NOTHING)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    role = models.ForeignKey('SupplierStaffRoles', models.DO_NOTHING)
    is_active = models.BooleanField()

    class Meta:
        managed = False
        db_table = 'supplier_staff'
        unique_together = (('supplier', 'user'),)


class SupplierStaffRoles(models.Model):
    id = models.BigAutoField(primary_key=True)
    code = models.TextField(unique=True)
    name = models.TextField()

    class Meta:
        managed = False
        db_table = 'supplier_staff_roles'


class Suppliers(models.Model):
    id = models.BigAutoField(primary_key=True)
    name = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)
    is_active = models.BooleanField(default=True)
    deleted_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'suppliers'


class Units(models.Model):
    id = models.BigAutoField(primary_key=True)
    code = models.TextField(unique=True)
    name = models.TextField()

    class Meta:
        managed = False
        db_table = 'units'


class Users(models.Model):
    id = models.BigAutoField(primary_key=True)
    email = models.TextField(unique=True)
    password_hash = models.TextField()
    full_name = models.TextField()
    created_at = models.DateTimeField(default=timezone.now) 
    is_active = models.BooleanField(default=True) 

    class Meta:
        managed = False
        db_table = 'users'

# backend/api/models.py

# ... other models (Users, Products, Orders, etc.) ...

# DELETE the class Complaint(...) entirely!

# KEEP this new class:
class Incidents(models.Model):
    id = models.BigAutoField(primary_key=True)

    order = models.ForeignKey(Orders, on_delete=models.CASCADE, related_name="incidents") # Note related_name
    supplier = models.ForeignKey(Suppliers, on_delete=models.CASCADE)
    consumer = models.ForeignKey(Consumers, on_delete=models.CASCADE)
    
    description = models.TextField()
    status = models.TextField(default='open') 
    created_at = models.DateTimeField(default=timezone.now)

    created_by = models.ForeignKey(
        Users, 
        on_delete=models.DO_NOTHING, 
        related_name='created_incidents',
        db_column='created_by'  # <--- Tells Django the actual column name
    )

    # 🟢 FIX: Add db_column='assigned_to' (Likely same issue here)
    assigned_to = models.ForeignKey(
        Users, 
        on_delete=models.DO_NOTHING, 
        null=True, 
        blank=True,
        db_column='assigned_to' # <--- Tells Django the actual column name
    )
    class Meta:
        managed = False
        db_table = 'incidents'