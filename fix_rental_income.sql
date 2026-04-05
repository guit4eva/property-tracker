-- Fix Rental Income: Update payment_received from active rent periods
-- This populates payment_received for all monthly_expenses that currently have 0
-- but should have values based on the rent_periods table

-- First, let's see what will be updated:
SELECT 
    me.id,
    me.year,
    me.month,
    me.payment_received as current_value,
    rp.rental_amount as new_value,
    rp.id as rent_period_id
FROM monthly_expenses me
LEFT JOIN rent_periods rp ON me.property_id = rp.property_id
    AND rp.start_date <= DATE(me.year, me.month, 1)
    AND (rp.end_date IS NULL OR rp.end_date >= DATE(me.year, me.month, 1))
WHERE me.payment_received = 0
ORDER BY me.year, me.month;

-- Now perform the update:
UPDATE monthly_expenses me
SET 
    payment_received = rp.rental_amount,
    updated_at = NOW()
FROM rent_periods rp
WHERE me.property_id = rp.property_id
    AND rp.start_date <= DATE(me.year, me.month, 1)
    AND (rp.end_date IS NULL OR rp.end_date >= DATE(me.year, me.month, 1))
    AND me.payment_received = 0;

-- Verify the update worked:
SELECT 
    year,
    month,
    payment_received,
    water,
    electricity
FROM monthly_expenses
WHERE property_id = (SELECT id FROM properties LIMIT 1)
ORDER BY year, month;
