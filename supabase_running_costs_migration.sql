-- Running Costs Enhanced Schema Migration
-- Adds frequency tracking, scheduling, and date range support

-- Add new columns to running_costs table
ALTER TABLE running_costs 
ADD COLUMN IF NOT EXISTS frequency TEXT DEFAULT 'monthly',
ADD COLUMN IF NOT EXISTS interval INT,
ADD COLUMN IF NOT EXISTS day_of_week INT,
ADD COLUMN IF NOT EXISTS day_of_month INT,
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_running_costs_frequency ON running_costs(frequency);
CREATE INDEX IF NOT EXISTS idx_running_costs_dates ON running_costs(start_date, end_date);

-- Update existing records to have start_date based on year/month
UPDATE running_costs 
SET start_date = TO_DATE(year || '-' || month || '-01', 'YYYY-MM-DD')
WHERE start_date IS NULL;

COMMENT ON COLUMN running_costs.frequency IS 'Cost frequency: once_off, daily, weekly, monthly, yearly, every_x_days, every_x_weeks, every_x_months';
COMMENT ON COLUMN running_costs.interval IS 'Interval for recurring costs (e.g., every 2 weeks)';
COMMENT ON COLUMN running_costs.day_of_week IS 'Day of week (1-7, Monday-Sunday)';
COMMENT ON COLUMN running_costs.day_of_month IS 'Day of month (1-31)';
COMMENT ON COLUMN running_costs.start_date IS 'When this cost starts';
COMMENT ON COLUMN running_costs.end_date IS 'When this cost ends (NULL = ongoing)';
