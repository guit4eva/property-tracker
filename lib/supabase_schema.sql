-- ============================================================
-- Property Tracker - Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Properties table
CREATE TABLE IF NOT EXISTS properties (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  address TEXT,
  site_value NUMERIC(12,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Monthly expenses (rates/taxes, water, electricity, interest)
CREATE TABLE IF NOT EXISTS monthly_expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  year INT NOT NULL,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  water NUMERIC(10,2) DEFAULT 0,
  electricity NUMERIC(10,2) DEFAULT 0,
  interest NUMERIC(10,2) DEFAULT 0,
  rates_taxes NUMERIC(10,2) DEFAULT 0,
  annual_levy NUMERIC(10,2) DEFAULT 0,
  payment_received NUMERIC(10,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(property_id, year, month)
);

-- Running costs (cleaning, garden, custom)
CREATE TABLE IF NOT EXISTS running_costs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  year INT NOT NULL,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  category TEXT NOT NULL, -- 'cleaning', 'garden', 'maintenance', 'custom'
  description TEXT,
  amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Site evaluations / milestones
CREATE TABLE IF NOT EXISTS site_evaluations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  evaluation_date DATE NOT NULL,
  value NUMERIC(12,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_monthly_expenses_property ON monthly_expenses(property_id);
CREATE INDEX IF NOT EXISTS idx_monthly_expenses_date ON monthly_expenses(year, month);
CREATE INDEX IF NOT EXISTS idx_running_costs_property ON running_costs(property_id);
CREATE INDEX IF NOT EXISTS idx_running_costs_date ON running_costs(year, month);

-- Enable Row Level Security (optional, if using auth)
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE running_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_evaluations ENABLE ROW LEVEL SECURITY;

-- Policies: allow all for now (adjust if adding user auth)
CREATE POLICY "Allow all on properties" ON properties FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on monthly_expenses" ON monthly_expenses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on running_costs" ON running_costs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on site_evaluations" ON site_evaluations FOR ALL USING (true) WITH CHECK (true);

-- Sample property (328 Elft Avenue)
INSERT INTO properties (name, address, site_value)
VALUES ('328 Elft Avenue', '328 Elft Avenue', 1840000.00)
ON CONFLICT DO NOTHING;
