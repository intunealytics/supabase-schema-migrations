-- Create orders table
CREATE TABLE orders (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id uuid NOT NULL,
    customer_id uuid NOT NULL REFERENCES customers(id),
    order_number varchar(50) NOT NULL,
    order_date timestamptz DEFAULT CURRENT_TIMESTAMP,
    status varchar(50) DEFAULT 'draft',
    shipping_address_id uuid REFERENCES addresses(id),
    billing_address_id uuid REFERENCES addresses(id),
    currency_code varchar(3) DEFAULT 'USD',
    subtotal decimal(15,2) DEFAULT 0,
    tax_total decimal(15,2) DEFAULT 0,
    shipping_total decimal(15,2) DEFAULT 0,
    discount_total decimal(15,2) DEFAULT 0,
    total decimal(15,2) DEFAULT 0,
    notes text,
    internal_notes text,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, order_number)
);

-- Create order_lines table
CREATE TABLE order_lines (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id uuid NOT NULL REFERENCES orders(id),
    product_id uuid NOT NULL REFERENCES products(id),
    quantity decimal(15,2) NOT NULL,
    unit_price decimal(15,2) NOT NULL,
    tax_rate decimal(5,2) DEFAULT 0,
    tax_amount decimal(15,2) DEFAULT 0,
    discount_amount decimal(15,2) DEFAULT 0,
    subtotal decimal(15,2) DEFAULT 0,
    total decimal(15,2) DEFAULT 0,
    notes text,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create inventory_transactions table
CREATE TABLE inventory_transactions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id uuid NOT NULL,
    product_id uuid NOT NULL REFERENCES products(id),
    order_line_id uuid REFERENCES order_lines(id),
    transaction_type varchar(50) NOT NULL, -- 'receipt', 'shipment', 'adjustment'
    quantity decimal(15,2) NOT NULL,
    reference_number varchar(100),
    notes text,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create inventory_snapshots table for historical tracking
CREATE TABLE inventory_snapshots (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid NOT NULL REFERENCES products(id),
    quantity_on_hand decimal(15,2) NOT NULL,
    quantity_reserved decimal(15,2) DEFAULT 0,
    quantity_available decimal(15,2) GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    snapshot_date timestamptz DEFAULT CURRENT_TIMESTAMP,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Add useful indexes
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_lines_product ON order_lines(product_id);
CREATE INDEX idx_inventory_transactions_product ON inventory_transactions(product_id);
CREATE INDEX idx_inventory_snapshots_product_date ON inventory_snapshots(product_id, snapshot_date);

-- Create triggers
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_order_lines_updated_at
    BEFORE UPDATE ON order_lines
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_transactions_updated_at
    BEFORE UPDATE ON inventory_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_snapshots ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view orders in their organization"
    ON orders FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations 
        WHERE organization_id = orders.organization_id
    ));

CREATE POLICY "Users can view order lines in their organization"
    ON order_lines FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = order_lines.order_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations
            WHERE organization_id = orders.organization_id
        )
    ));

CREATE POLICY "Users can view inventory transactions in their organization"
    ON inventory_transactions FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations 
        WHERE organization_id = inventory_transactions.organization_id
    ));

-- Add helper functions
CREATE OR REPLACE FUNCTION calculate_order_totals()
    RETURNS TRIGGER AS $$
BEGIN
    -- Calculate line totals
    NEW.subtotal = NEW.quantity * NEW.unit_price;
    NEW.tax_amount = NEW.subtotal * (NEW.tax_rate / 100);
    NEW.total = NEW.subtotal + NEW.tax_amount - NEW.discount_amount;
    
    -- Update order totals
    UPDATE orders
    SET 
        subtotal = (
            SELECT COALESCE(SUM(subtotal), 0)
            FROM order_lines
            WHERE order_id = NEW.order_id
        ),
        tax_total = (
            SELECT COALESCE(SUM(tax_amount), 0)
            FROM order_lines
            WHERE order_id = NEW.order_id
        ),
        total = (
            SELECT COALESCE(SUM(total), 0)
            FROM order_lines
            WHERE order_id = NEW.order_id
        )
    WHERE id = NEW.order_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_order_line_totals
    BEFORE INSERT OR UPDATE ON order_lines
    FOR EACH ROW
    EXECUTE FUNCTION calculate_order_totals();

-- Add version
INSERT INTO schema_versions (version_id, description)
VALUES (6, 'Add order management and enhanced inventory tracking');
