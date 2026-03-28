#!/usr/bin/env python3
"""
Script to parse the property expense data and generate SQL INSERT statements
for importing into Supabase database.
"""

import csv
import re
from datetime import datetime

def parse_currency(value):
    """Parse currency value like 'R210.43' or 'R1,120.47' to float."""
    if not value or value.strip() == '':
        return None
    # Remove 'R' prefix and commas
    cleaned = value.strip().replace('R', '').replace(',', '')
    try:
        return float(cleaned)
    except ValueError:
        return None

def parse_date(date_str):
    """Parse date like 'Jul 2021' to (year, month) tuple."""
    months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    }
    parts = date_str.strip().split()
    if len(parts) != 2:
        return None, None
    month_str, year_str = parts
    month = months.get(month_str)
    if month is None:
        return None, None
    try:
        year = int(year_str)
    except ValueError:
        return None, None
    return year, month

def extract_site_evaluation(notes):
    """Extract site evaluation value from notes like 'Site evaluation: 1,385,000.00'."""
    if not notes:
        return None
    match = re.search(r'[Ss]ite\s+[Ee]valuation:\s*([\d,]+\.?\d*)', notes)
    if match:
        value_str = match.group(1).replace(',', '')
        try:
            return float(value_str)
        except ValueError:
            return None
    return None

def main():
    # Read the CSV file
    expenses = []
    evaluations = []
    
    with open('/workspace/import_data.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            date_str = row.get('Date', '').strip()
            if not date_str:
                continue
                
            year, month = parse_date(date_str)
            if year is None or month is None:
                print(f"Warning: Could not parse date '{date_str}'")
                continue
            
            property_name = row.get('Property', '').strip()
            water = parse_currency(row.get('Water', ''))
            electricity = parse_currency(row.get('Elec.', ''))
            interest = parse_currency(row.get('Interest', ''))
            annual_levy = parse_currency(row.get('Annual', ''))
            payment = parse_currency(row.get('Payment', ''))
            notes = row.get('Notes', '').strip()
            
            # Check for site evaluation in notes
            site_eval_value = extract_site_evaluation(notes)
            
            # Only add expense if there's actual data
            if any([water, electricity, interest, annual_levy, payment, notes]):
                expense = {
                    'property_name': property_name,
                    'year': year,
                    'month': month,
                    'water': water,
                    'electricity': electricity,
                    'interest': interest,
                    'annual_levy': annual_levy,
                    'payment_received': payment,
                    'notes': notes if notes and not site_eval_value else None
                }
                expenses.append(expense)
            
            # Add site evaluation if found
            if site_eval_value:
                eval_date = f"{year}-{month:02d}-01"
                evaluation = {
                    'property_name': property_name,
                    'evaluation_date': eval_date,
                    'value': site_eval_value,
                    'notes': notes
                }
                # Avoid duplicates
                if not any(e['evaluation_date'] == eval_date and e['property_name'] == property_name for e in evaluations):
                    evaluations.append(evaluation)
    
    # Generate SQL
    sql_output = []
    sql_output.append("-- ============================================================")
    sql_output.append("-- Generated SQL for importing property expense data")
    sql_output.append("-- Run this in your Supabase SQL Editor")
    sql_output.append("-- ============================================================")
    sql_output.append("")
    
    # First, ensure the property exists
    sql_output.append("-- Ensure property exists")
    sql_output.append("INSERT INTO properties (name, address, site_value)")
    sql_output.append("VALUES ('328 Elft Avenue', '328 Elft Avenue', NULL)")
    sql_output.append("ON CONFLICT DO NOTHING;")
    sql_output.append("")
    
    # Get property ID (we'll use a subquery)
    sql_output.append("-- Get property ID for 328 Elft Avenue")
    sql_output.append("DO $$")
    sql_output.append("DECLARE")
    sql_output.append("    prop_id UUID;")
    sql_output.append("BEGIN")
    sql_output.append("    SELECT id INTO prop_id FROM properties WHERE name = '328 Elft Avenue' LIMIT 1;")
    sql_output.append("")
    
    # Insert site evaluations
    if evaluations:
        sql_output.append("    -- Insert site evaluations")
        for eval in evaluations:
            value_formatted = f"{eval['value']:,.2f}".replace(',', '')
            notes_escaped = eval['notes'].replace("'", "''") if eval['notes'] else ''
            sql_output.append(f"    INSERT INTO site_evaluations (property_id, evaluation_date, value, notes)")
            sql_output.append(f"    VALUES (prop_id, '{eval['evaluation_date']}', {value_formatted}, '{notes_escaped}');")
        sql_output.append("")
    
    # Insert monthly expenses
    if expenses:
        sql_output.append("    -- Insert monthly expenses")
        for exp in expenses:
            water_val = exp['water'] if exp['water'] else 0
            electricity_val = exp['electricity'] if exp['electricity'] else 0
            interest_val = exp['interest'] if exp['interest'] else 0
            annual_levy_val = exp['annual_levy'] if exp['annual_levy'] else 'NULL'
            payment_val = exp['payment_received'] if exp['payment_received'] else 0
            notes_val = f"'{exp['notes'].replace(chr(39), chr(39)+chr(39))}'" if exp['notes'] else 'NULL'
            
            if annual_levy_val != 'NULL':
                annual_levy_sql = annual_levy_val
            else:
                annual_levy_sql = 'NULL'
            
            sql_output.append(f"    INSERT INTO monthly_expenses (property_id, year, month, water, electricity, interest, annual_levy, payment_received, notes)")
            sql_output.append(f"    VALUES (prop_id, {exp['year']}, {exp['month']}, {water_val}, {electricity_val}, {interest_val}, {annual_levy_sql}, {payment_val}, {notes_val})")
            sql_output.append(f"    ON CONFLICT (property_id, year, month) DO UPDATE SET")
            sql_output.append(f"        water = EXCLUDED.water,")
            sql_output.append(f"        electricity = EXCLUDED.electricity,")
            sql_output.append(f"        interest = EXCLUDED.interest,")
            sql_output.append(f"        annual_levy = EXCLUDED.annual_levy,")
            sql_output.append(f"        payment_received = EXCLUDED.payment_received,")
            sql_output.append(f"        notes = EXCLUDED.notes;")
            sql_output.append("")
    
    sql_output.append("END $$;")
    sql_output.append("")
    sql_output.append("-- Import complete!")
    
    # Write output
    with open('/workspace/import_data.sql', 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql_output))
    
    print(f"Generated SQL file: /workspace/import_data.sql")
    print(f"Processed {len(expenses)} monthly expenses")
    print(f"Processed {len(evaluations)} site evaluations")

if __name__ == '__main__':
    main()
