-- ============================================================
-- Supabase Data Import Script
-- Clears all existing data and imports property expenses
-- ============================================================

-- 1. Delete all existing data (in correct order for foreign keys)
DELETE FROM rent_periods;
DELETE FROM running_costs;
DELETE FROM site_evaluations;
DELETE FROM monthly_expenses;
DELETE FROM properties;

-- 2. Insert Properties
INSERT INTO properties (id, name, address, site_value, created_at)
VALUES 
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '328 Elft Avenue', '328 Elft Avenue', NULL, '2021-07-01T00:00:00Z'),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', '330 Elft Avenue', '330 Elft Avenue', NULL, '2026-03-01T00:00:00Z');

-- 3. Insert Site Evaluations
INSERT INTO site_evaluations (id, property_id, evaluation_date, value, notes)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '2021-07-15', 1385000.00, 'Site evaluation: 1,385,000.00'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '2022-07-15', 1385000.00, 'Site evaluation: 1,385,000.00'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '2023-07-15', 1840000.00, 'Site evaluation: 1,840,000.00'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '2024-07-15', 1840000.00, 'Site evaluation: 1,840,000.00');

-- 4. Insert Monthly Expenses for 328 Elft Avenue
-- Format: property_id, year, month, water, electricity, interest, rates_taxes, annual_levy, payment_received, notes, rates_frequency, rates_start_date
INSERT INTO monthly_expenses (
  id, property_id, year, month, water, electricity, interest, 
  rates_taxes, annual_levy, payment_received, payment_to_municipality, 
  notes, rates_frequency, rates_start_date, created_at, updated_at
) VALUES

-- 2021
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2021, 7,  0, 0, 15.10, 0, 12325.31, 0, 0, 'Site evaluation: 1,385,000.00', 'annually', '2021-07-01', NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2021, 8,  0, 0, 0, 0, 0, 0, 0, 'Missing invoice', 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2021, 9,  0, 0, 0, 0, 0, 0, 0, 'Missing invoice', 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2021, 10, 210.43, 413.34, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2021, 11, 210.43, 152.66, 65.23, 0, 0, 0, 0, 'Rented for: 2 years 7 months', 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2021, 12, 210.43, 304.57, 67.72, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),

-- 2022
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 1,  210.43, 413.72, 73.43, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 2,  210.43, 303.95, 0, 0, 0, 12498.70, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 3,  210.43, 328.45, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 4,  210.43, 345.14, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 5,  210.43, 300.66, 2.36, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 6,  0, 0, 0, 0, 0, 0, 0, 'Missing invoice', 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 7,  220.53, 283.83, 11.36, 0, 15668.58, 0, 0, 'Site evaluation: 1,385,000.00', 'annually', '2022-07-01', NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 8,  220.53, 473.54, 14.00, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 9,  220.53, 357.73, 0, 0, 0, 20000.00, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 10, 220.53, 457.99, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 11, 220.53, 384.20, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2022, 12, 220.53, 300.06, 1.20, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),

-- 2023
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 1,  220.53, 521.15, 6.32, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 2,  220.53, 301.23, 13.58, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 3,  220.53, 364.88, 19.48, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 4,  220.53, 418.78, 25.46, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 5,  220.53, 396.37, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 6,  220.53, 733.97, 6.04, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 7,  240.38, 453.03, 16.07, 0, 18192.38, 0, 0, 'Site evaluation: 1,840,000.00', 'annually', '2023-07-01', NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 8,  240.38, 453.03, 0.51, 0, 0, 21000.00, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 9,  240.38, 951.11, 1.85, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 10, 240.38, 434.68, 14.52, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 11, 240.38, 494.31, 21.70, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2023, 12, 240.38, 520.19, 29.50, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),

-- 2024
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 1,  240.38, 768.33, 37.59, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 2,  240.38, 483.43, 48.30, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 3,  240.38, 661.39, 55.99, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 4,  240.38, 595.01, 0, 0, 0, 0, 0, 'CHECK - R10,000 in TFR JNL', 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 5,  240.38, 578.02, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 6,  240.38, 733.12, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 7,  254.57, 740.96, 0, 0, 19501.22, 15000.00, 0, 'Site evaluation: 1,840,000.00', 'annually', '2024-07-01', NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 8,  254.57, 952.32, 10.57, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 9,  254.57, 1120.47, 22.84, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 10, 254.57, 702.47, 73.81, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 11, 272.58, 908.56, 82.09, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2024, 12, 254.57, 766.72, 0, 0, 0, 0, 0, 'Doesn''t seem like anyone checked the meter these 3 months', 'monthly', NULL, NOW(), NOW()),

-- 2025
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 1,  254.57, 766.72, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 2,  254.57, 766.72, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 3,  254.57, 766.72, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 4,  254.57, 1090.11, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 5,  254.57, 789.70, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 6,  254.57, 590.49, 6.19, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 7,  265.52, 898.33, 14.47, 0, 20661.26, 30000.00, 0, NULL, 'annually', '2025-07-01', NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 8,  265.52, 997.93, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 9,  265.52, 1106.48, 0, 0, 0, 18000.00, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 10, 265.52, 972.31, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 11, 0, 0, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2025, 12, 0, 0, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),

-- 2026
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2026, 1,  0, 0, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),
(gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2026, 2,  0, 0, 0, 0, 0, 0, 0, NULL, 'monthly', NULL, NOW(), NOW()),

-- 330 Elft Avenue
(gen_random_uuid(), 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 2026, 3,  0, 0, 0, 0, 0, 12315.04, 0, NULL, 'monthly', NULL, NOW(), NOW());

-- ============================================================
-- Verification Queries
-- ============================================================

-- Check properties
SELECT id, name, address FROM properties;

-- Check site evaluations
SELECT property_id, evaluation_date, value, notes FROM site_evaluations;

-- Check monthly expenses count
SELECT COUNT(*) as total_expenses FROM monthly_expenses;

-- Check expenses by year
SELECT year, COUNT(*) as months, 
       SUM(water) as total_water, 
       SUM(electricity) as total_electricity,
       SUM(payment_received) as total_payments
FROM monthly_expenses 
GROUP BY year 
ORDER BY year;
