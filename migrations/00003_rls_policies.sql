-- Enable RLS on tables
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimate_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimate_line_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimate_tax_lines ENABLE ROW LEVEL SECURITY;

-- Create policies for estimates
CREATE POLICY "Users can view their own estimates"
    ON estimates FOR SELECT
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations WHERE organization_id = estimates.organization_id
    ));

CREATE POLICY "Users can insert their own estimates"
    ON estimates FOR INSERT
    WITH CHECK (auth.uid() IN (
        SELECT user_id FROM user_organizations WHERE organization_id = estimates.organization_id
    ));

CREATE POLICY "Users can update their own estimates"
    ON estimates FOR UPDATE
    USING (auth.uid() IN (
        SELECT user_id FROM user_organizations WHERE organization_id = estimates.organization_id
    ));

-- Create policies for estimate lines
CREATE POLICY "Users can view their estimate lines"
    ON estimate_lines FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM estimates
        WHERE estimates.id = estimate_lines.estimate_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations 
            WHERE organization_id = estimates.organization_id
        )
    ));

CREATE POLICY "Users can insert estimate lines"
    ON estimate_lines FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM estimates
        WHERE estimates.id = estimate_lines.estimate_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations 
            WHERE organization_id = estimates.organization_id
        )
    ));

-- Similar policies for bundles and tax lines
CREATE POLICY "Users can view their estimate bundles"
    ON estimate_line_bundles FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM estimates
        WHERE estimates.id = estimate_line_bundles.estimate_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations 
            WHERE organization_id = estimates.organization_id
        )
    ));

CREATE POLICY "Users can view their tax lines"
    ON estimate_tax_lines FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM estimates
        WHERE estimates.id = estimate_tax_lines.estimate_id
        AND auth.uid() IN (
            SELECT user_id FROM user_organizations 
            WHERE organization_id = estimates.organization_id
        )
    ));

-- Add version
INSERT INTO schema_versions (version_id, description)
VALUES (3, 'Add RLS policies');