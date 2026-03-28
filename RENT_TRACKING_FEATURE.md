# Rent Tracking Feature - Implementation Complete

## Overview
Added comprehensive rent tracking with year-on-year increases and automatic population when creating new expense entries.

---

## 📋 Changes Made

### 1. **Database Schema** (`supabase_rent_migration.sql`)
```sql
CREATE TABLE rent_periods (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL means indefinite/current
    rental_amount NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Action Required**: Run this SQL in Supabase Dashboard → SQL Editor

### 2. **Model** (`lib/models/models.dart`)
- Added `RentPeriod` class with:
  - `isActiveForDate()` method to check if period applies to a specific month
  - JSON serialization/deserialization
  - `copyWith()` for immutability

### 3. **Service Layer** (`lib/services/supabase_service.dart`)
Added CRUD operations:
- `fetchRentPeriodsForProperty()`
- `createRentPeriod()`
- `updateRentPeriod()`
- `deleteRentPeriod()`

### 4. **Provider** (`lib/providers/property_provider.dart`)
- Added `_rentPeriods` state management
- `getRentForMonth(year, month)` - finds active rent for any month
- `addRentPeriod()`, `updateRentPeriod()`, `deleteRentPeriod()`
- Auto-loads rent periods when selecting a property

### 5. **Auto-Population** (`lib/screens/entry_screen.dart`)
Modified `_loadExisting()` to automatically fill `paymentReceived` field:
```dart
_paymentReceived = prov.getRentForMonth(widget.year, widget.month) ?? 0;
```

When creating a new entry for a month with no existing data, the rent amount is auto-populated based on the active rent period.

### 6. **UI - Rent History Screen** (`lib/screens/rent_history_screen.dart`)
New screen with:
- List of all rent periods for a property
- Visual distinction between current and historical periods
- Add/Edit/Delete functionality
- Date pickers for start/end dates
- "Ongoing" toggle for current rent
- Form validation

### 7. **Integration** (`lib/screens/properties_screen.dart`)
- Added "Rent History" option to property menu
- Accessible via three-dot menu on any property card

---

## 🚀 How to Use

### Step 1: Run Database Migration
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Paste contents of `supabase_rent_migration.sql`
4. Click "Run"

### Step 2: Add Rent Periods
1. Go to **Properties** tab
2. Tap ⋮ (three dots) on a property
3. Select **"Rent History"**
4. Tap **+** to add first period
5. Enter:
   - **Start Date**: When this rent amount begins (e.g., Jan 1, 2024)
   - **Amount**: Monthly rent (e.g., R15,000)
   - **Ongoing**: Enable if this is current rent (no end date)
6. Save

### Step 3: Add Annual Increases
For year-on-year increases:
1. Edit previous period, set **End Date** (e.g., Dec 31, 2024)
2. Add new period with **Start Date** (e.g., Jan 1, 2025) and new amount
3. Mark new period as **Ongoing**

### Step 4: Automatic Population
When adding expenses:
1. Go to **Entry** tab
2. Select a month (e.g., March 2025)
3. Tap **"Add Expense Data"**
4. **Payment Received** field auto-fills with correct rent amount
5. Adjust other expenses and save

---

## 💡 Example Scenario

**Property**: 328 Elft Avenue

**Rent History**:
- Jan 2024 - Dec 2024: R15,000/month
- Jan 2025 - Present: R16,500/month

**User Experience**:
- Creating entry for **June 2024** → Payment Received auto-fills with **R15,000**
- Creating entry for **March 2025** → Payment Received auto-fills with **R16,500**
- Creating entry for **January 2026** (no period defined) → Payment Received = **R0** (manual entry needed)

---

## 🎨 UI Features

### Rent History Screen
- **Green badge** for current/ongoing periods
- **Grey icon** for historical periods
- **Edit/Delete** actions per period
- **Empty state** with CTA when no periods exist

### Add/Edit Dialog
- Calendar date pickers
- "Ongoing" toggle simplifies current rent entry
- Input validation (positive numbers only)
- Loading states during save

---

## 🔧 Technical Details

### Date Logic
- Uses middle of month (15th) for period matching
- Periods are sorted by start date
- Last matching period wins (most recent first search)

### Data Flow
```
User selects month → EntryScreen._loadExisting() 
→ PropertyProvider.getRentForMonth(year, month)
→ Finds active RentPeriod
→ Returns rentalAmount
→ Auto-populates paymentReceived field
```

---

## ✅ Testing Checklist

- [ ] Run SQL migration in Supabase
- [ ] Add property if none exists
- [ ] Navigate to Properties → ⋮ → Rent History
- [ ] Add rent period with start date and amount
- [ ] Mark as ongoing
- [ ] Go to Entry tab, select future month
- [ ] Tap "Add Expense Data"
- [ ] Verify Payment Received is pre-filled
- [ ] Add another period with future start date (increase)
- [ ] Check different months show correct amounts
- [ ] Edit/delete periods and verify updates

---

## 📝 Future Enhancements

- [ ] Rent due date tracking
- [ ] Late payment fees calculation
- [ ] Lease agreement attachments
- [ ] Rent payment history vs expected
- [ ] Notifications for rent reviews
- [ ] Export rent roll reports

---

## 🐛 Troubleshooting

**Issue**: Rent not auto-populating
- **Check**: Is there a rent period with start date before selected month?
- **Check**: Is the period marked as ongoing or has end date after selected month?
- **Check**: Did you run the SQL migration?

**Issue**: Wrong amount showing
- **Check**: Are there overlapping periods? (shouldn't happen but verify)
- **Check**: Is the start date correct? (e.g., Jan 1 not Dec 31)

**Issue**: Can't access Rent History
- **Check**: Is import added to `properties_screen.dart`?
- **Check**: Is `rent_history_screen.dart` in correct folder?

---

**Implementation Date**: 2025
**Status**: ✅ Complete and Ready for Testing
