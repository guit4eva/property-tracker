-- Check if property exists and get its ID
SELECT id, name, address FROM properties WHERE name = '328 Elft Avenue';

-- Count expenses by year for this property
SELECT 
    year, 
    COUNT(*) as expense_count
FROM monthly_expenses me
JOIN properties p ON me.property_id = p.id
WHERE p.name = '328 Elft Avenue'
GROUP BY year
ORDER BY year;

-- Check specific 2025 months
SELECT year, month, water, electricity, interest, annual_levy, payment_received
FROM monthly_expenses me
JOIN properties p ON me.property_id = p.id
WHERE p.name = '328 Elft Avenue' AND year = 2025
ORDER BY month;
