-- Rent Periods Migration Script
-- Removes user dependency, links strictly to properties

-- Drop existing table if it exists to ensure clean schema
DROP TABLE IF EXISTS rent_periods CASCADE;

CREATE TABLE IF NOT EXISTS rent_periods (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL means indefinite/current
    rental_amount NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rent_periods_property ON rent_periods(property_id);
CREATE INDEX IF NOT EXISTS idx_rent_periods_dates ON rent_periods(start_date, end_date);

-- Enable RLS
ALTER TABLE rent_periods ENABLE ROW LEVEL SECURITY;

-- For now, allow all operations since there is no user auth
CREATE POLICY "Allow all access to rent periods" ON rent_periods
FOR ALL USING (true) WITH CHECK (true);
