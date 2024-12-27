-- Create products table
CREATE TABLE products (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id uuid NOT NULL,
    name varchar(255) NOT NULL,
    description text,
    sku varchar(100),
    unit_price decimal(15,2),
    cost_price decimal(15,2),
    tax_code_id uuid,
    category_id uuid,
    status varchar(50) DEFAULT 'active',
    is_taxable boolean DEFAULT true,
    inventory_tracking boolean DEFAULT false,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create product_categories table
CREATE TABLE product_categories (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id uuid NOT NULL,
    name varchar(255) NOT NULL,
    description text,
    parent_id uuid REFERENCES product_categories(id),
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create product_pricing table
CREATE TABLE product_pricing (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid NOT NULL REFERENCES products(id),
    price_list_id uuid NOT NULL,
    unit_price decimal(15,2) NOT NULL,
    min_quantity int DEFAULT 1,
    start_date timestamptz,
    end_date timestamptz,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create product_inventory table
CREATE TABLE product_inventory (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id uuid NOT NULL REFERENCES products(id),
    warehouse_id uuid NOT NULL,
    quantity_on_hand int DEFAULT 0,
    reorder_point int,
    reorder_quantity int,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, warehouse_id)
);

-- Create triggers
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_categories_updated_at
    BEFORE UPDATE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_pricing_updated_at
    BEFORE UPDATE ON product_pricing
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_inventory_updated_at
    BEFORE UPDATE ON product_inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_inventory ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view products in their organization"
    ON products FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations 
        WHERE organization_id = products.organization_id
    ));

CREATE POLICY "Users can view product categories in their organization"
    ON product_categories FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations 
        WHERE organization_id = product_categories.organization_id
    ));

CREATE POLICY "Users can view product pricing in their organization"
    ON product_pricing FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM products
        WHERE products.id = product_pricing.product_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations
            WHERE organization_id = products.organization_id
        )
    ));

-- Add version
INSERT INTO schema_versions (version_id, description)
VALUES (5, 'Add product related tables');
