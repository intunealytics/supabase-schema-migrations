-- Create address table
CREATE TABLE addresses (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id uuid NOT NULL,
    line1 varchar(255),
    line2 varchar(255),
    city varchar(100),
    state varchar(100),
    postal_code varchar(20),
    country varchar(100),
    type varchar(50), -- shipping, billing, etc.
    is_default boolean DEFAULT false,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create customers table
CREATE TABLE customers (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id uuid NOT NULL,
    name varchar(255) NOT NULL,
    company_name varchar(255),
    email varchar(255),
    phone varchar(50),
    status varchar(50) DEFAULT 'active',
    notes text,
    default_billing_address_id uuid REFERENCES addresses(id),
    default_shipping_address_id uuid REFERENCES addresses(id),
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create customer_addresses junction table
CREATE TABLE customer_addresses (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id uuid NOT NULL REFERENCES customers(id),
    address_id uuid NOT NULL REFERENCES addresses(id),
    is_default boolean DEFAULT false,
    address_type varchar(50), -- shipping, billing
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(customer_id, address_id)
);

-- Create triggers
CREATE TRIGGER update_addresses_updated_at
    BEFORE UPDATE ON addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customer_addresses_updated_at
    BEFORE UPDATE ON customer_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view addresses in their organization"
    ON addresses FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations 
        WHERE organization_id = addresses.organization_id
    ));

CREATE POLICY "Users can view customers in their organization"
    ON customers FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations 
        WHERE organization_id = customers.organization_id
    ));

CREATE POLICY "Users can view customer addresses in their organization"
    ON customer_addresses FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM customers
        WHERE customers.id = customer_addresses.customer_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations
            WHERE organization_id = customers.organization_id
        )
    ));

-- Add version
INSERT INTO schema_versions (version_id, description)
VALUES (4, 'Add customer and address tables');
