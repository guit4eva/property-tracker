-- ============================================================
-- Generated SQL for importing property expense data
-- Run this in your Supabase SQL Editor
-- ============================================================

-- Ensure property exists (use ON CONFLICT on name)
INSERT INTO properties (name, address, site_value)
VALUES ('328 Elft Avenue', '328 Elft Avenue', NULL)
ON CONFLICT (name) DO NOTHING;

-- Get property ID for 328 Elft Avenue
DO $$
DECLARE
    prop_id UUID;
BEGIN
    SELECT id INTO prop_id FROM properties WHERE name = '328 Elft Avenue' LIMIT 1;

    -- Insert site evaluations
    INSERT INTO site_evaluations (property_id, evaluation_date, value, notes)
    VALUES (prop_id, '2021-07-01', 1385000.00, 'Site evaluation: 1,385,000.00');
    INSERT INTO site_evaluations (property_id, evaluation_date, value, notes)
    VALUES (prop_id, '2022-07-01', 1385000.00, 'Site Evaluation: 1,385,000.00');
    INSERT INTO site_evaluations (property_id, evaluation_date, value, notes)
    VALUES (prop_id, '2023-07-01', 1840000.00, 'Site Evaluation: 1,840,000.00');
    INSERT INTO site_evaluations (property_id, evaluation_date, value, notes)
    VALUES (prop_id, '2024-07-01', 1840000.00, 'Site Evaluation: 1,840,000.00');

    -- Insert monthly expenses
    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2021, 7, 0, 0, 15.1, 12325.31, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2021, 8, 0, 0, 0, NULL, 0, 'Missing invoice')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2021, 9, 0, 0, 0, NULL, 0, 'Missing invoice')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2021, 10, 210.43, 413.34, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2021, 11, 210.43, 152.66, 65.23, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2021, 12, 210.43, 304.57, 67.72, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 1, 210.43, 413.72, 73.43, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 2, 210.43, 303.95, 0, NULL, 0, 'R12498.70')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 3, 210.43, 328.45, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 4, 210.43, 345.14, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 5, 210.43, 300.66, 2.36, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 6, 0, 0, 0, NULL, 0, 'Missing invoice')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 7, 220.53, 283.83, 11.36, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 7, 220.53, 283.83, 11.36, 15668.58, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 8, 220.53, 473.54, 14.0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 9, 220.53, 357.73, 0, NULL, 0, 'R20000.00')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 10, 220.53, 457.99, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 11, 220.53, 384.2, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2022, 12, 220.53, 300.06, 1.2, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 1, 220.53, 521.15, 6.32, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 2, 220.53, 301.23, 13.58, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 3, 220.53, 364.88, 19.48, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 4, 220.53, 418.78, 25.46, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 5, 210.43, 396.37, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 6, 220.53, 733.97, 6.04, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 7, 240.38, 453.03, 16.07, 18192.38, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 8, 240.38, 453.03, 0.51, NULL, 0, 'R21000.00')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 9, 240.38, 951.11, 1.85, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 10, 240.38, 434.68, 14.52, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 11, 240.38, 494.31, 21.7, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2023, 12, 240.38, 520.19, 29.5, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 1, 240.38, 768.33, 37.59, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 2, 240.38, 483.43, 48.3, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 3, 240.38, 661.39, 55.99, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 4, 240.38, 595.01, 0, NULL, 0, 'CHECK - R10,000 in TFR JNL')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 5, 240.38, 578.02, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 6, 240.38, 733.12, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 7, 254.57, 740.96, 0, 19501.22, 15000.0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 8, 254.57, 952.32, 10.57, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 9, 254.57, 1120.47, 22.84, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 10, 254.57, 702.47, 73.81, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 11, 272.58, 908.56, 82.09, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2024, 12, 254.57, 766.72, 0, NULL, 0, 'Doesn''t seem like anyone checked the meter these 3 months')
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 1, 254.57, 766.72, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 2, 254.57, 766.72, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 3, 254.57, 766.72, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 4, 254.57, 1090.11, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 5, 254.57, 789.7, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 6, 254.57, 590.49, 6.19, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 7, 265.52, 898.33, 14.47, 20661.26, 30000.0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 8, 265.52, 997.93, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 9, 265.52, 1106.48, 0, 18000.0, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)
    VALUES (prop_id, 2025, 10, 265.52, 972.31, 0, NULL, 0, NULL)
    ON CONFLICT (property_id, year, month) DO UPDATE SET
        water = EXCLUDED.water,
        electricity = EXCLUDED.electricity,
        interest = EXCLUDED.interest,
        annual_levy = EXCLUDED.annual_levy,
        payment_received = EXCLUDED.payment_received,
        notes = EXCLUDED.notes;

END $$;

-- Import complete!