# Municipality Payment Tracking Feature

## Overview
Added ability to track payments made to the municipality for rates and utilities, separate from rental income received.

## Changes Made

### 1. Database Schema (`supabase_migration_payment_to_municipality.sql`)
```sql
ALTER TABLE monthly_expenses 
ADD COLUMN IF NOT EXISTS payment_to_municipality NUMERIC DEFAULT 0;
```

**Action Required**: Run this SQL migration in your Supabase SQL Editor.

### 2. Model Updates (`lib/models/models.dart`)
- Added `paymentToMunicipality` field to `MonthlyExpense` class
- Added `balanceAfterMunicipality` getter: `paymentReceived - totalExpenses - paymentToMunicipality`
- Updated `fromJson()`, `toJson()`, and `copyWith()` methods

### 3. UI Updates (`lib/screens/entry_screen.dart`)
- **Form**: New "Payment to Municipality" field with purple color scheme
- **Info View**: Shows municipality payments separately when > 0
- **Balance Calculation**: Now shows "Balance After Payments" accounting for both received and municipality payments

### 4. Provider Updates (`lib/providers/property_provider.dart`)
- Updated `allTimeTotals` to include `municipality_payments`

## Usage

### Adding Municipality Payments
1. Navigate to Entry tab
2. Select month
3. Tap "Add Expense Data" or "Edit"
4. Enter amount in "Payment to Municipality" field
5. Save

### Viewing Balance
The info view now shows:
- Total Expenses
- Payment Received (if any)
- Payment to Municipality (if any)
- **Balance After Payments** (final balance after all transactions)

## Balance Formula
```
Balance = Payment Received - Total Expenses - Payment to Municipality
```

Positive balance = surplus  
Negative balance = outstanding amount owed

## Next Steps
1. Run the SQL migration in Supabase
2. Test adding/editing entries with municipality payments
3. Verify balance calculations display correctly
