SET search_path TO scp, public;

INSERT INTO supplier_staff_roles (code, name) VALUES
('owner',  'Owner'),
('manager','Manager'),
('sales',  'Sales')
ON CONFLICT (code) DO NOTHING;


INSERT INTO users (email, password_hash, full_name) VALUES
('owner@example.com',    'hash_owner',    'Supplier Owner'),
('sales@example.com',    'hash_sales',    'Supplier Sales'),
('consumer@example.com', 'hash_consumer', 'Consumer User');


INSERT INTO suppliers (name)
VALUES ('Acme Supplier');

INSERT INTO consumers (name)
VALUES ('Best Consumer');

INSERT INTO supplier_staff (supplier_id, user_id, role_id, is_active)
VALUES
(
    (SELECT id FROM suppliers WHERE name = 'Acme Supplier'),
    (SELECT id FROM users     WHERE email = 'owner@example.com'),
    (SELECT id FROM supplier_staff_roles WHERE code = 'owner'),
    true
),
(
    (SELECT id FROM suppliers WHERE name = 'Acme Supplier'),
    (SELECT id FROM users     WHERE email = 'sales@example.com'),
    (SELECT id FROM supplier_staff_roles WHERE code = 'sales'),
    true
);

INSERT INTO consumer_users (consumer_id, user_id, is_active)
VALUES (
    (SELECT id FROM consumers WHERE name = 'Best Consumer'),
    (SELECT id FROM users     WHERE email = 'consumer@example.com'),
    true
);

INSERT INTO supplier_consumer_links (supplier_id, consumer_id, status)
VALUES (
    (SELECT id FROM suppliers WHERE name = 'Acme Supplier'),
    (SELECT id FROM consumers WHERE name = 'Best Consumer'),
    'accepted'
);

INSERT INTO units (code, name)
VALUES ('pcs', 'Pieces')
ON CONFLICT (code) DO NOTHING;

INSERT INTO products (supplier_id, sku, name, description, unit_id, is_active)
VALUES (
    (SELECT id FROM suppliers WHERE name = 'Acme Supplier'),
    'SKU-001',
    'Demo Product',
    'Demo product for RLS testing',
    (SELECT id FROM units WHERE code = 'pcs'),
    true
);

INSERT INTO prices (product_id, currency, amount, valid_from)
VALUES (
    (SELECT id FROM products WHERE sku = 'SKU-001'
                               AND supplier_id = (SELECT id FROM suppliers WHERE name = 'Acme Supplier')),
    'KZT',
    1000.00,
    current_date
);

INSERT INTO stock_levels (product_id, quantity)
VALUES (
    (SELECT id FROM products WHERE sku = 'SKU-001'
                               AND supplier_id = (SELECT id FROM suppliers WHERE name = 'Acme Supplier')),
    50
);

INSERT INTO orders (supplier_id, consumer_id, status, total_amount, created_by)
VALUES (
    (SELECT id FROM suppliers WHERE name = 'Acme Supplier'),
    (SELECT id FROM consumers WHERE name = 'Best Consumer'),
    'submitted',
    1000.00,
    (SELECT id FROM users WHERE email = 'consumer@example.com')
);

INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
VALUES (
    (SELECT id FROM orders
     WHERE supplier_id = (SELECT id FROM suppliers WHERE name = 'Acme Supplier')
       AND consumer_id = (SELECT id FROM consumers WHERE name = 'Best Consumer')
     ORDER BY id LIMIT 1),
    (SELECT id FROM products WHERE sku = 'SKU-001'
                               AND supplier_id = (SELECT id FROM suppliers WHERE name = 'Acme Supplier')),
    1,
    1000.00,
    1000.00
);


INSERT INTO chats DEFAULT VALUES;

INSERT INTO chat_participants (chat_id, user_id, role)
VALUES
(
    (SELECT id FROM chats ORDER BY id DESC LIMIT 1),
    (SELECT id FROM users WHERE email = 'owner@example.com'),
    'supplier_owner'
),
(
    (SELECT id FROM chats ORDER BY id DESC LIMIT 1),
    (SELECT id FROM users WHERE email = 'consumer@example.com'),
    'consumer_user'
);


INSERT INTO messages (chat_id, sender_id, text, attachment_type)
VALUES (
    (SELECT id FROM chats ORDER BY id DESC LIMIT 1),
    (SELECT id FROM users WHERE email = 'consumer@example.com'),
    'Hello, I want to discuss my order',
    'none'
);

INSERT INTO incidents (order_id, supplier_id, consumer_id, status, created_by, assigned_to, description)
VALUES (
    (SELECT id FROM orders
     WHERE supplier_id = (SELECT id FROM suppliers WHERE name = 'Acme Supplier')
       AND consumer_id = (SELECT id FROM consumers WHERE name = 'Best Consumer')
     ORDER BY id LIMIT 1),
    (SELECT id FROM suppliers WHERE name = 'Acme Supplier'),
    (SELECT id FROM consumers WHERE name = 'Best Consumer'),
    'open',
    (SELECT id FROM users WHERE email = 'consumer@example.com'),
    (SELECT id FROM users WHERE email = 'sales@example.com'),
    'Customer complains about delayed delivery'
);

