CREATE SCHEMA IF NOT EXISTS scp;
SET search_path TO scp, public;

CREATE OR REPLACE FUNCTION scp.current_user_id()
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
    SELECT current_setting('scp.current_user_id')::bigint;
$$;

-- ENUM-types

CREATE TYPE link_status AS ENUM ('pending', 'accepted', 'blocked');

CREATE TYPE order_status AS ENUM (
    'draft',
    'submitted',
    'accepted',
    'rejected',
    'in_progress',
    'completed',
    'cancelled'
);

CREATE TYPE incident_status AS ENUM ('open', 'in_progress', 'resolved');

CREATE TYPE attachment_type AS ENUM ('none', 'image', 'audio', 'doc');

CREATE TABLE supplier_staff_roles (
    id          bigserial PRIMARY KEY,
    code        text UNIQUE NOT NULL,    -- 'owner', 'manager', 'sales'
    name        text NOT NULL
);

INSERT INTO supplier_staff_roles (code, name) VALUES
('owner',  'Owner'),
('manager','Manager'),
('sales',  'Sales')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE users (
    id              bigserial PRIMARY KEY,
    email           text UNIQUE NOT NULL,
    password_hash   text NOT NULL,
    full_name       text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    is_active       boolean NOT NULL DEFAULT true
);

CREATE TABLE suppliers (
    id              bigserial PRIMARY KEY,
    name            text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    is_active       boolean NOT NULL DEFAULT true,
    deleted_at      timestamptz
);

CREATE TABLE consumers (
    id              bigserial PRIMARY KEY,
    name            text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    is_active       boolean NOT NULL DEFAULT true
);

CREATE TABLE supplier_staff (
    id              bigserial PRIMARY KEY,
    supplier_id     bigint NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    user_id         bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id         bigint NOT NULL REFERENCES supplier_staff_roles(id),
    is_active       boolean NOT NULL DEFAULT true,
    UNIQUE (supplier_id, user_id)
);

CREATE TABLE consumer_users (
    id              bigserial PRIMARY KEY,
    consumer_id     bigint NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,
    user_id         bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_active       boolean NOT NULL DEFAULT true,
    UNIQUE (consumer_id, user_id)
);


CREATE TABLE supplier_consumer_links (
    id              bigserial PRIMARY KEY,
    supplier_id     bigint NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    consumer_id     bigint NOT NULL REFERENCES consumers(id) ON DELETE CASCADE,
    status          link_status NOT NULL DEFAULT 'pending',
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (supplier_id, consumer_id)
);


CREATE TABLE units (
    id          bigserial PRIMARY KEY,
    code        text UNIQUE NOT NULL,   -- 'kg', 'pcs', 'l', ...
    name        text NOT NULL
);

CREATE TABLE products (
    id              bigserial PRIMARY KEY,
    supplier_id     bigint NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    sku             text NOT NULL,
    name            text NOT NULL,
    description     text,
    unit_id         bigint NOT NULL REFERENCES units(id),
    is_active       boolean NOT NULL DEFAULT true,
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (supplier_id, sku)
);

CREATE TABLE prices (
    id              bigserial PRIMARY KEY,
    product_id      bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    currency        text NOT NULL DEFAULT 'KZT',
    amount          numeric(12,2) NOT NULL,
    valid_from      date NOT NULL DEFAULT current_date,
    valid_to        date
);

CREATE TABLE stock_levels (
    id              bigserial PRIMARY KEY,
    product_id      bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity        numeric(14,3) NOT NULL,
    updated_at      timestamptz NOT NULL DEFAULT now()
);


CREATE TABLE orders (
    id              bigserial PRIMARY KEY,
    supplier_id     bigint NOT NULL REFERENCES suppliers(id),
    consumer_id     bigint NOT NULL REFERENCES consumers(id),
    status          order_status NOT NULL DEFAULT 'submitted',
    total_amount    numeric(14,2),
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL REFERENCES users(id),
    archived_at     timestamptz      -- для read-only после N лет
);

CREATE TABLE order_items (
    id              bigserial PRIMARY KEY,
    order_id        bigint NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      bigint NOT NULL REFERENCES products(id),
    quantity        numeric(14,3) NOT NULL,
    unit_price      numeric(12,2) NOT NULL,
    line_total      numeric(14,2) NOT NULL
);


CREATE TABLE chats (
    id              bigserial PRIMARY KEY,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE chat_participants (
    id              bigserial PRIMARY KEY,
    chat_id         bigint NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id         bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            text,
    UNIQUE (chat_id, user_id)
);

CREATE TABLE messages (
    id                  bigserial PRIMARY KEY,
    chat_id             bigint NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id           bigint NOT NULL REFERENCES users(id),
    text                text,
    file_url            text,
    attachment_type     attachment_type NOT NULL DEFAULT 'none',
    created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE incidents (
    id              bigserial PRIMARY KEY,
    order_id        bigint NOT NULL REFERENCES orders(id),
    supplier_id     bigint NOT NULL REFERENCES suppliers(id),
    consumer_id     bigint NOT NULL REFERENCES consumers(id),
    status          incident_status NOT NULL DEFAULT 'open',
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint NOT NULL REFERENCES users(id),
    assigned_to     bigint REFERENCES users(id),
    description     text,
    archived_at     timestamptz
);


CREATE OR REPLACE VIEW supplier_user_roles AS
SELECT
    ss.user_id,
    ss.supplier_id,
    r.code AS role_code
FROM supplier_staff ss
JOIN supplier_staff_roles r ON r.id = ss.role_id
WHERE ss.is_active = true;

--Optimization
CREATE INDEX IF NOT EXISTS idx_products_supplier_sku
    ON products (supplier_id, sku);

CREATE INDEX IF NOT EXISTS idx_products_name_search
    ON products
    USING gin (to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(description,'')));
CREATE INDEX IF NOT EXISTS idx_prices_product_id_valid_from
    ON prices (product_id, valid_from);
CREATE INDEX IF NOT EXISTS idx_stock_levels_product_id_updated_at
    ON stock_levels (product_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_supplier_consumer_status
    ON orders (supplier_id, consumer_id, status);
CREATE INDEX IF NOT EXISTS idx_incidents_supplier_status
    ON incidents (supplier_id, status);
CREATE INDEX IF NOT EXISTS idx_messages_chat_created_at
    ON messages (chat_id, created_at);


--RLS
ALTER TABLE products   ENABLE ROW LEVEL SECURITY;
ALTER TABLE products   FORCE  ROW LEVEL SECURITY;

ALTER TABLE orders     ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders     FORCE  ROW LEVEL SECURITY;

ALTER TABLE chats      ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats      FORCE  ROW LEVEL SECURITY;

ALTER TABLE messages   ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages   FORCE  ROW LEVEL SECURITY;

ALTER TABLE incidents  ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents  FORCE  ROW LEVEL SECURITY;

--staff rls
CREATE POLICY products_for_supplier_staff ON products
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM supplier_staff ss
        WHERE ss.supplier_id = products.supplier_id
          AND ss.user_id      = scp.current_user_id()
          AND ss.is_active    = true
    )
);

-- consumer with accepted link
CREATE POLICY products_for_accepted_consumers ON products
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM consumer_users cu
        JOIN supplier_consumer_links scl
          ON scl.consumer_id = cu.consumer_id
        WHERE cu.user_id      = scp.current_user_id()
          AND cu.is_active    = true
          AND scl.supplier_id = products.supplier_id
          AND scl.status      = 'accepted'
    )
);

-- see only your order
CREATE POLICY orders_for_consumer_users ON orders
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM consumer_users cu
        WHERE cu.consumer_id = orders.consumer_id
          AND cu.user_id     = scp.current_user_id()
          AND cu.is_active   = true
    )
);

CREATE POLICY orders_for_supplier_staff ON orders
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM supplier_staff ss
        WHERE ss.supplier_id = orders.supplier_id
          AND ss.user_id     = scp.current_user_id()
          AND ss.is_active   = true
    )
    AND EXISTS (
        SELECT 1
        FROM supplier_consumer_links scl
        WHERE scl.supplier_id = orders.supplier_id
          AND scl.consumer_id = orders.consumer_id
          AND scl.status      = 'accepted'
    )
);

-- archive not changed
CREATE POLICY orders_update_not_archived ON orders
FOR UPDATE
USING (archived_at IS NULL)
WITH CHECK (archived_at IS NULL);

CREATE POLICY orders_delete_not_archived ON orders
FOR DELETE
USING (archived_at IS NULL);

-- rls chats
CREATE POLICY chats_for_participants ON chats
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM chat_participants cp
        WHERE cp.chat_id = chats.id
          AND cp.user_id = scp.current_user_id()
    )
);

CREATE POLICY messages_for_participants ON messages
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM chat_participants cp
        WHERE cp.chat_id = messages.chat_id
          AND cp.user_id = scp.current_user_id()
    )
);
-- rls incidents
CREATE POLICY incidents_for_sales ON incidents
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM supplier_user_roles sur
        WHERE sur.user_id     = scp.current_user_id()
          AND sur.supplier_id = incidents.supplier_id
          AND sur.role_code   = 'sales'
    )
    AND (
        incidents.assigned_to = scp.current_user_id()
        OR incidents.created_by = scp.current_user_id()
    )
);

-- Manager/Owner
CREATE POLICY incidents_for_manager_owner ON incidents
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM supplier_user_roles sur
        WHERE sur.user_id     = scp.current_user_id()
          AND sur.supplier_id = incidents.supplier_id
          AND sur.role_code IN ('manager', 'owner')
    )
);


CREATE OR REPLACE FUNCTION deactivate_supplier_cascade()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_active = false AND OLD.is_active = true THEN
        NEW.deleted_at := now();

        UPDATE supplier_staff
        SET is_active = false
        WHERE supplier_id = NEW.id;


        UPDATE products
        SET is_active = false
        WHERE supplier_id = NEW.id;


        UPDATE supplier_consumer_links
        SET status = 'blocked'
        WHERE supplier_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_deactivate_supplier_cascade
BEFORE UPDATE OF is_active ON suppliers
FOR EACH ROW
EXECUTE FUNCTION deactivate_supplier_cascade();

