-- Create estimate table
CREATE TABLE estimates (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    currency_id uuid NOT NULL,
    shipping_address_id uuid,
    bill_to_address_id uuid,
    department_id uuid,
    customer_id uuid NOT NULL,
    creation_date timestamptz DEFAULT CURRENT_TIMESTAMP,
    expiration_date timestamptz,
    ship_date timestamptz,
    print_date timestamptz,
    transaction_status varchar(50),
    total_line_amount decimal(15,2),
    total_tax_amount decimal(15,2),
    total_discount decimal(15,2),
    total_amount decimal(15,2),
    notes text,
    private_note text,
    accepted_by varchar(255),
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create estimate_line table
CREATE TABLE estimate_lines (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    estimate_id uuid NOT NULL REFERENCES estimates(id),
    sales_item_id uuid NOT NULL,
    sales_item_tax_code_id uuid,
    sales_item_class_id uuid,
    sales_item_account_id uuid,
    bundle_id uuid,
    discount_tax_code_id uuid,
    discount_account_id uuid,
    discount_class_id uuid,
    sales_item_description text,
    description text,
    service_date timestamptz,
    discount_amount decimal(15,2),
    discount_account varchar(255),
    bundle_quantity int,
    quantity decimal(15,2),
    unit_price decimal(15,2),
    sales_item_quantity int,
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create estimate_line_bundle table
CREATE TABLE estimate_line_bundles (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    estimate_id uuid NOT NULL REFERENCES estimates(id),
    line_number int,
    item_id uuid NOT NULL,
    class_id uuid,
    account_id uuid,
    tax_code_id uuid,
    quantity int,
    amount decimal(15,2),
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create estimate_tax_line table
CREATE TABLE estimate_tax_lines (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    estimate_id uuid NOT NULL REFERENCES estimates(id),
    tax_rate_id uuid NOT NULL,
    tax_amount decimal(15,2),
    override_delta_amount decimal(15,2),
    tax_inclusive_amount decimal(15,2),
    created_at timestamptz DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create triggers for updated_at
CREATE TRIGGER update_estimates_updated_at
    BEFORE UPDATE ON estimates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_estimate_lines_updated_at
    BEFORE UPDATE ON estimate_lines
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_estimate_line_bundles_updated_at
    BEFORE UPDATE ON estimate_line_bundles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_estimate_tax_lines_updated_at
    BEFORE UPDATE ON estimate_tax_lines
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add version
INSERT INTO schema_versions (version_id, description)
VALUES (2, 'Add estimate tables');
