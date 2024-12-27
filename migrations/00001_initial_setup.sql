-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types if needed
CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');

-- Create a custom function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Schema version tracking
CREATE TABLE IF NOT EXISTS schema_versions (
    version_id bigint PRIMARY KEY,
    description text NOT NULL,
    installed_on timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    success boolean NOT NULL DEFAULT true,
    execution_time integer NOT NULL DEFAULT 0
);

-- Insert initial version
INSERT INTO schema_versions (version_id, description)
VALUES (1, 'Initial setup with extensions and utilities');