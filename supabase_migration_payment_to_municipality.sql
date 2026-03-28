-- Add payment_to_municipality column to monthly_expenses table
ALTER TABLE monthly_expenses 
ADD COLUMN IF NOT EXISTS payment_to_municipality NUMERIC DEFAULT 0;

-- Add comment for documentation
COMMENT ON COLUMN monthly_expenses.payment_to_municipality IS 'Payments made to municipality for this month';
