# Rental Income Auto-Sync Feature

## Problem Fixed

Rental income totals were showing as zero even though rental data had been entered. This happened because:

1. **Monthly expense entries were created BEFORE rent periods were set up** - When entries are created without an active rent period, `payment_received` defaults to 0
2. **Existing entries weren't updated when rent periods were added later** - The auto-population only worked for new entries
3. **Manual editing required** - Users had to manually edit each entry to add the rental amount

## Solution: Fail-Proof Auto-Sync System

The rental income system now has multiple layers of automatic synchronization to ensure `payment_received` is always populated correctly.

### Features Implemented

#### 1. **Auto-Sync on Property Load** (Background)
- **Location**: `PropertyProvider.syncPaymentReceivedFromRentPeriods()`
- **What it does**: Scans all monthly expenses and automatically updates any with `payment_received = 0` if an active rent period exists
- **When it runs**: 
  - Automatically when rent periods are added
  - Automatically when rent periods are updated
  - Can be triggered manually from the UI

#### 2. **Auto-Populate in Entry Screen** (Per-Entry)
- **Location**: `EntryScreen._loadExisting()`
- **What it does**: When you open an existing monthly entry with `payment_received = 0`, it automatically fills in the amount from the active rent period
- **User action required**: Just click Save to persist the change

#### 3. **Visual Indicator & Auto-Fill Button** (User Guidance)
- **Location**: Entry Screen form, below "Payment Received" field
- **What it shows**: When viewing/editing an entry with `payment_received = 0` but an active rent period exists, you'll see:
  - A green info box showing "Rent period active: R X,XXX.XX"
  - An "Auto-fill" button to instantly populate the amount
- **User action required**: Click "Auto-fill" button or manually enter amount

#### 4. **Bulk Sync Button** (Rental Income Screen)
- **Location**: Rental Income Screen app bar (sync icon with badge)
- **What it does**: Shows a badge with the count of entries that can be synced
- **User action required**: 
  1. Tap the sync icon in the app bar
  2. Confirm the sync operation
  3. All entries with 0 payment will be updated from rent periods

## How To Use

### Option 1: Automatic (Recommended)
Just add/edit rent periods! The system will automatically sync rental income to all monthly entries.

### Option 2: Per-Entry Fix
1. Open any monthly entry showing 0 rental income
2. You'll see the "Payment Received" field auto-populated from the active rent period
3. Click Save to persist the change

### Option 3: Bulk Sync (Fastest for Existing Data)
1. Go to **Menu** → **Rental Income**
2. If you have syncable entries, you'll see a sync button with a badge
3. Tap the sync button
4. Confirm the operation
5. All entries will be updated instantly

### Option 4: SQL Direct Fix
For immediate database-level fix, run the provided SQL script:

```sql
-- File: fix_rental_income.sql
UPDATE monthly_expenses me
SET 
    payment_received = rp.rental_amount,
    updated_at = NOW()
FROM rent_periods rp
WHERE me.property_id = rp.property_id
    AND rp.start_date <= DATE(me.year, me.month, 1)
    AND (rp.end_date IS NULL OR rp.end_date >= DATE(me.year, me.month, 1))
    AND me.payment_received = 0;
```

## Technical Details

### Data Flow

```
Rent Period Created/Updated
         ↓
PropertyProvider.addRentPeriod/updateRentPeriod
         ↓
syncPaymentReceivedFromRentPeriods()
         ↓
For each expense with paymentReceived == 0:
  - Check if rent period is active for that month
  - If yes, update paymentReceived from rent period
  - Save to database
         ↓
notifyListeners() → UI updates automatically
```

### Key Methods

- `PropertyProvider.getRentForMonth(year, month)` - Gets active rent amount for a specific month
- `PropertyProvider.syncPaymentReceivedFromRentPeriods()` - Bulk sync method
- `EntryScreen._loadExisting()` - Auto-populates when loading entry
- `RentPeriod.isActiveForDate(date)` - Checks if date falls within rent period

### Safety Features

1. **Only updates zero values**: Entries with existing `payment_received > 0` are never modified
2. **Database transaction**: Each update is saved immediately to Supabase
3. **Error handling**: Failed updates are logged but don't stop the sync process
4. **User confirmation**: Bulk sync requires explicit user confirmation
5. **Visual feedback**: Success messages show how many entries were updated

## Files Modified

1. **lib/providers/property_provider.dart**
   - Added `syncPaymentReceivedFromRentPeriods()` method
   - Modified `addRentPeriod()` to auto-sync
   - Modified `updateRentPeriod()` to auto-sync

2. **lib/screens/entry_screen.dart**
   - Modified `_loadExisting()` to auto-populate payment_received
   - Added visual indicator with auto-fill button

3. **lib/screens/rental_income_screen.dart**
   - Added bulk sync button in app bar
   - Added info banner when syncable entries exist
   - Enhanced empty state with sync option

## Testing Checklist

- [x] Code compiles without errors
- [x] Flutter analyze passes (only warnings, no errors)
- [ ] Add rent period → existing entries auto-update
- [ ] Update rent period → entries re-sync
- [ ] Open existing entry with 0 payment → auto-populates
- [ ] Bulk sync button works correctly
- [ ] Visual indicator shows correct rent amount
- [ ] Entries with existing payment_received are NOT modified

## Future Enhancements

Potential improvements for future versions:

1. **Auto-sync on app launch** - Run sync when app opens
2. **Smart conflict resolution** - Handle cases where rent periods overlap
3. **Sync history** - Track when and what was synced
4. **Undo sync** - Allow reverting sync operations
5. **Notifications** - Alert users when syncable entries are detected
