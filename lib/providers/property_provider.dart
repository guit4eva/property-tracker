import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class PropertyProvider extends ChangeNotifier {
  List<Property> _properties = [];
  Property? _selectedProperty;
  List<MonthlyExpense> _expenses = [];
  List<RunningCost> _runningCosts = [];
  List<SiteEvaluation> _evaluations = [];
  List<RentPeriod> _rentPeriods = []; // NEW: Rent periods
  bool _loading = false;
  String? _error;

  // Offline support
  bool _isOffline = false;
  final List<Map<String, dynamic>> _pendingChanges = [];

  // Filters for advanced search/filtering
  int? _filterYear;
  CostCategory? _filterCategory;
  double? _filterMinAmount;
  double? _filterMaxAmount;

  List<Property> get properties => _properties;
  Property? get selectedProperty => _selectedProperty;
  List<MonthlyExpense> get expenses => _expenses;
  List<RunningCost> get runningCosts => _runningCosts;
  List<SiteEvaluation> get evaluations => _evaluations;
  List<RentPeriod> get rentPeriods => _rentPeriods; // NEW
  bool get loading => _loading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  List<Map<String, dynamic>> get pendingChanges => _pendingChanges;
  int? get filterYear => _filterYear;
  CostCategory? get filterCategory => _filterCategory;
  double? get filterMinAmount => _filterMinAmount;
  double? get filterMaxAmount => _filterMaxAmount;

  // NEW: Getter for all running costs across all properties (for summary)
  List<RunningCost> get allRunningCosts => _runningCosts;

  // ─── Refresh & Manual Reload ────────────────────────────────────────────────

  /// Manual refresh method - can be called from UI
  Future<void> refresh() async {
    if (_selectedProperty != null) {
      await _loadPropertyData(_selectedProperty!.id);
    }
    await loadProperties();
  }

  /// Check connectivity and update offline status
  Future<void> checkConnectivity() async {
    try {
      await SupabaseService.fetchProperties();
      _isOffline = false;
      // Sync pending changes when back online
      if (_pendingChanges.isNotEmpty) {
        await _syncPendingChanges();
      }
    } catch (_) {
      _isOffline = true;
    }
    notifyListeners();
  }

  Future<void> _syncPendingChanges() async {
    // Process pending changes when back online
    for (final change in List.from(_pendingChanges)) {
      try {
        // Re-apply the change based on type
        final type = change['type'] as String;
        if (type == 'expense') {
          final expense = MonthlyExpense.fromJson(change['data']);
          await SupabaseService.upsertExpense(expense);
        }
        // Add more types as needed
        _pendingChanges.remove(change);
      } catch (_) {
        // Keep in pending queue if sync fails
      }
    }
    notifyListeners();
  }

  // ─── Properties ────────────────────────────────────────────────────────────

  Future<void> loadProperties() async {
    _setLoading(true);
    try {
      _properties = await SupabaseService.fetchProperties();
      if (_properties.isNotEmpty && _selectedProperty == null) {
        await selectProperty(_properties.first);
      } else if (_selectedProperty != null) {
        // Reload selected property data after properties are loaded
        await _loadPropertyData(_selectedProperty!.id);
      }
    } catch (e) {
      _error = e.toString();
      _isOffline = true;
    }
    _setLoading(false);
  }

  Future<void> selectProperty(Property p) async {
    _selectedProperty = p;
    notifyListeners();
    await _loadPropertyData(p.id);
  }

  Future<void> addProperty(Property p) async {
    final created = await SupabaseService.createProperty(p);
    _properties.add(created);
    await selectProperty(created);
    notifyListeners();
  }

  Future<void> updateProperty(Property p) async {
    final updated = await SupabaseService.updateProperty(p);
    final idx = _properties.indexWhere((e) => e.id == p.id);
    if (idx >= 0) _properties[idx] = updated;
    if (_selectedProperty?.id == p.id) _selectedProperty = updated;
    notifyListeners();
  }

  Future<void> deleteProperty(String id) async {
    await SupabaseService.deleteProperty(id);
    _properties.removeWhere((e) => e.id == id);
    if (_selectedProperty?.id == id) {
      _selectedProperty = _properties.isNotEmpty ? _properties.first : null;
      if (_selectedProperty != null) {
        await _loadPropertyData(_selectedProperty!.id);
      } else {
        _expenses = [];
        _runningCosts = [];
        _evaluations = [];
      }
    }
    notifyListeners();
  }

  Future<void> _loadPropertyData(String propertyId) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        SupabaseService.fetchExpensesForProperty(propertyId),
        SupabaseService.fetchRunningCostsForProperty(propertyId),
        SupabaseService.fetchEvaluationsForProperty(propertyId),
        SupabaseService.fetchRentPeriodsForProperty(propertyId), // NEW
      ]);
      _expenses = results[0] as List<MonthlyExpense>;
      _runningCosts = results[1] as List<RunningCost>;
      _evaluations = results[2] as List<SiteEvaluation>;
      _rentPeriods = results[3] as List<RentPeriod>; // NEW
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  // ─── Monthly Expenses ───────────────────────────────────────────────────────

  MonthlyExpense? getExpenseForMonth(int year, int month) {
    try {
      return _expenses.firstWhere(
        (e) => e.year == year && e.month == month,
      );
    } catch (_) {
      return null;
    }
  }

  Future<MonthlyExpense> upsertExpense(MonthlyExpense expense) async {
    try {
      final saved = await SupabaseService.upsertExpense(expense);
      final idx = _expenses.indexWhere(
          (e) => e.year == expense.year && e.month == expense.month);
      if (idx >= 0) {
        _expenses[idx] = saved;
      } else {
        _expenses.add(saved);
        _expenses.sort((a, b) {
          final yCmp = a.year.compareTo(b.year);
          return yCmp != 0 ? yCmp : a.month.compareTo(b.month);
        });
      }
      notifyListeners();
      return saved;
    } catch (e) {
      // Offline support: queue for later sync
      _pendingChanges.add({'type': 'expense', 'data': expense.toJson()});
      _isOffline = true;
      // Optimistically update UI
      final idx = _expenses.indexWhere(
          (e) => e.year == expense.year && e.month == expense.month);
      if (idx >= 0) {
        _expenses[idx] = expense;
      } else {
        _expenses.add(expense);
      }
      notifyListeners();
      rethrow;
    }
  }

  // ─── Running Costs ──────────────────────────────────────────────────────────

  List<RunningCost> getRunningCostsForMonth(int year, int month) {
    return _runningCosts
        .where((c) => c.year == year && c.month == month)
        .toList();
  }

  Future<void> addRunningCost(RunningCost cost) async {
    try {
      final saved = await SupabaseService.createRunningCost(cost);
      _runningCosts.add(saved);
      notifyListeners();
    } catch (e) {
      // Offline support: queue for later sync
      _pendingChanges.add({'type': 'running_cost', 'data': cost.toJson()});
      _isOffline = true;
      // Optimistically update UI
      _runningCosts.add(cost);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRunningCost(String id) async {
    await SupabaseService.deleteRunningCost(id);
    _runningCosts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ─── Site Evaluations ───────────────────────────────────────────────────────

  Future<void> addEvaluation(SiteEvaluation eval) async {
    final saved = await SupabaseService.createEvaluation(eval);
    _evaluations.add(saved);
    _evaluations.sort((a, b) => a.evaluationDate.compareTo(b.evaluationDate));
    notifyListeners();
  }

  Future<void> deleteEvaluation(String id) async {
    await SupabaseService.deleteEvaluation(id);
    _evaluations.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ─── Rent Periods ───────────────────────────────────────────────────────────

  /// Get the active rent amount for a specific month/year
  double? getRentForMonth(int year, int month) {
    final targetDate = DateTime(year, month, 15); // Use middle of month
    for (final period in _rentPeriods.reversed) {
      if (period.isActiveForDate(targetDate)) {
        return period.rentalAmount;
      }
    }
    return null;
  }

  /// Auto-sync payment_received from rent periods for expenses that have 0
  /// Returns the number of records updated
  Future<int> syncPaymentReceivedFromRentPeriods() async {
    int updatedCount = 0;

    for (int i = 0; i < _expenses.length; i++) {
      final expense = _expenses[i];

      // Only update if paymentReceived is 0
      if (expense.paymentReceived == 0) {
        final rentAmount = getRentForMonth(expense.year, expense.month);

        if (rentAmount != null && rentAmount > 0) {
          // Create updated expense with correct payment_received
          final updatedExpense = MonthlyExpense(
            id: expense.id,
            propertyId: expense.propertyId,
            year: expense.year,
            month: expense.month,
            water: expense.water,
            electricity: expense.electricity,
            interest: expense.interest,
            ratesTaxes: expense.ratesTaxes,
            annualLevy: expense.annualLevy,
            paymentReceived: rentAmount,
            paymentToMunicipality: expense.paymentToMunicipality,
            notes: expense.notes,
            isLocked: expense.isLocked,
            ratesFrequency: expense.ratesFrequency,
            ratesStartDate: expense.ratesStartDate,
          );

          try {
            // Save to database
            final saved = await SupabaseService.upsertExpense(updatedExpense);
            _expenses[i] = saved;
            updatedCount++;
          } catch (e) {
            // If database update fails, keep local value but continue
            debugPrint('Failed to sync expense ${expense.id}: $e');
          }
        }
      }
    }

    if (updatedCount > 0) {
      notifyListeners();
    }

    return updatedCount;
  }

  List<RentPeriod> getRentPeriods() => List.unmodifiable(_rentPeriods);

  Future<void> addRentPeriod(RentPeriod period) async {
    try {
      final saved = await SupabaseService.createRentPeriod(period);
      _rentPeriods.add(saved);
      _rentPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
      notifyListeners();

      // Auto-sync payment_received for all expenses
      await syncPaymentReceivedFromRentPeriods();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRentPeriod(RentPeriod period) async {
    try {
      final updated = await SupabaseService.updateRentPeriod(period);
      final idx = _rentPeriods.indexWhere((r) => r.id == period.id);
      if (idx >= 0) {
        _rentPeriods[idx] = updated;
        _rentPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
      }
      notifyListeners();

      // Auto-sync payment_received for all expenses
      await syncPaymentReceivedFromRentPeriods();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRentPeriod(String id) async {
    try {
      await SupabaseService.deleteRentPeriod(id);
      _rentPeriods.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ─── Analytics helpers ──────────────────────────────────────────────────────

  /// Total running costs for a month (all categories)
  double totalRunningCostsForMonth(int year, int month) {
    final costs = getRunningCostsForMonth(year, month);
    double total = 0;
    for (final c in costs) {
      total += c.monthlyEquivalent;
    }
    return total;
  }

  /// All-time totals for the selected property
  Map<String, double> get allTimeTotals {
    double water = 0,
        elec = 0,
        interest = 0,
        rates = 0,
        running = 0,
        received = 0,
        muniPayments = 0;
    final now = DateTime.now();

    for (final e in _expenses) {
      water += e.water;
      elec += e.electricity;
      interest += e.interest;
      rates +=
          e.effectiveMonthlyRates; // Uses monthly division for annual rates
      received += e.paymentReceived;
      muniPayments += e.paymentToMunicipality;
    }

    // Calculate running costs with actual occurrences
    for (final c in _runningCosts) {
      final costStart = c.startDate;
      final costEnd = c.endDate ?? now;

      int occurrences = 0;
      switch (c.frequency) {
        case CostFrequency.monthly:
          occurrences = (costEnd.year - costStart.year) * 12 +
              (costEnd.month - costStart.month) +
              1;
          break;
        case CostFrequency.weekly:
          if (c.dayOfWeek != null) {
            int startDayOfWeek = costStart.weekday;
            int targetDay = c.dayOfWeek!;
            int daysUntilTarget = (targetDay - startDayOfWeek + 7) % 7;
            DateTime firstOccurrence =
                costStart.add(Duration(days: daysUntilTarget));
            if (!firstOccurrence.isAfter(costEnd)) {
              int totalDays = costEnd.difference(firstOccurrence).inDays;
              occurrences = (totalDays ~/ 7) + 1;
            }
          } else {
            final days = costEnd.difference(costStart).inDays;
            occurrences = (days ~/ 7) + 1;
          }
          break;
        case CostFrequency.yearly:
          occurrences = costEnd.year - costStart.year + 1;
          break;
        case CostFrequency.everyXWeeks:
          if (c.dayOfWeek != null) {
            int startDayOfWeek = costStart.weekday;
            int targetDay = c.dayOfWeek!;
            int daysUntilTarget = (targetDay - startDayOfWeek + 7) % 7;
            DateTime firstOccurrence =
                costStart.add(Duration(days: daysUntilTarget));
            if (!firstOccurrence.isAfter(costEnd)) {
              int totalDays = costEnd.difference(firstOccurrence).inDays;
              int intervalDays = 7 * (c.interval ?? 1);
              occurrences = (totalDays ~/ intervalDays) + 1;
            }
          } else {
            final days = costEnd.difference(costStart).inDays;
            occurrences = (days ~/ (7 * (c.interval ?? 1))) + 1;
          }
          break;
        case CostFrequency.everyXMonths:
          final months = (costEnd.year - costStart.year) * 12 +
              (costEnd.month - costStart.month);
          occurrences = (months ~/ (c.interval ?? 1)) + 1;
          break;
        default:
          occurrences = 1;
      }

      if (occurrences > 0) {
        running += c.amount * occurrences;
      }
    }

    return {
      'water': water,
      'electricity': elec,
      'interest': interest,
      'rates': rates,
      'running': running,
      'received': received,
      'municipality_payments': muniPayments,
      'total': water + elec + interest + rates + running,
    };
  }

  /// Monthly totals for charting (sorted) - SELECTED PROPERTY
  List<Map<String, dynamic>> get monthlyTotalsForChart {
    return _calculateMonthlyTotals(_expenses, _runningCosts);
  }

  /// NEW: Monthly totals for ALL properties combined
  List<Map<String, dynamic>> get allPropertiesMonthlyTotals {
    // For now, return the same as monthlyTotalsForChart
    // In a full implementation, this would aggregate data from all properties
    return monthlyTotalsForChart;
  }

  List<Map<String, dynamic>> _calculateMonthlyTotals(
      List<MonthlyExpense> expenses, List<RunningCost> costs) {
    final months = <String, Map<String, dynamic>>{};
    for (final e in expenses) {
      final key = '${e.year}-${e.month.toString().padLeft(2, '0')}';
      months[key] = {
        'year': e.year,
        'month': e.month,
        'water': e.water,
        'electricity': e.electricity,
        'interest': e.interest,
        'rates': e.effectiveMonthlyRates,
        'running': 0.0,
        'received': e.paymentReceived,
        'total': e.totalExpenses,
      };
    }
    // merge running costs - calculate actual occurrences per month
    for (final c in costs) {
      // Calculate which months this cost is active
      final costStart = c.startDate;
      final costEnd = c.endDate;

      // Determine the range of months to check
      final startYear = costStart.year;
      final startMonth = costStart.month;
      final endYear = costEnd?.year ?? DateTime.now().year;
      final endMonth = costEnd?.month ?? DateTime.now().month;

      // For each month in the range, check if this cost occurs
      for (int year = startYear; year <= endYear; year++) {
        for (int month = 1; month <= 12; month++) {
          // Skip if before start or after end
          if (year < startYear || (year == startYear && month < startMonth))
            continue;
          if (costEnd != null &&
              (year > endYear || (year == endYear && month > endMonth)))
            continue;

          final key = '$year-${month.toString().padLeft(2, '0')}';

          // Check if this cost occurs in this specific month
          bool occursInMonth = false;
          switch (c.frequency) {
            case CostFrequency.monthly:
              occursInMonth = true;
              break;
            case CostFrequency.weekly:
              // Count how many times this day of week occurs in the month
              if (c.dayOfWeek != null) {
                // For chart display, use the amount (not multiplied by occurrences)
                // since each occurrence is a separate event
                occursInMonth =
                    true; // Show the cost for months where it's active
              } else {
                occursInMonth = true;
              }
              break;
            case CostFrequency.yearly:
              occursInMonth = (month == costStart.month);
              break;
            case CostFrequency.everyXWeeks:
              occursInMonth = true; // Show for active months
              break;
            case CostFrequency.everyXMonths:
              final monthsFromStart =
                  (year - costStart.year) * 12 + (month - costStart.month);
              occursInMonth = (monthsFromStart % (c.interval ?? 1)) == 0;
              break;
            default:
              occursInMonth = true;
          }

          if (occursInMonth) {
            if (months.containsKey(key)) {
              months[key]!['running'] =
                  (months[key]!['running'] as double) + c.amount;
              months[key]!['total'] =
                  (months[key]!['total'] as double) + c.amount;
            } else {
              months[key] = {
                'year': year,
                'month': month,
                'water': 0.0,
                'electricity': 0.0,
                'interest': 0.0,
                'rates': 0.0,
                'running': c.amount,
                'received': 0.0,
                'total': c.amount,
              };
            }
          }
        }
      }
    }
    final sorted = months.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => e.value).toList();
  }

  // ─── Filter & Search Methods ────────────────────────────────────────────────

  /// Set year filter for expenses
  void setFilterYear(int? year) {
    _filterYear = year;
    notifyListeners();
  }

  /// Set category filter for running costs
  void setFilterCategory(CostCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  /// Set amount range filter
  void setFilterAmountRange(double? min, double? max) {
    _filterMinAmount = min;
    _filterMaxAmount = max;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _filterYear = null;
    _filterCategory = null;
    _filterMinAmount = null;
    _filterMaxAmount = null;
    notifyListeners();
  }

  /// Get filtered expenses based on current filters
  List<MonthlyExpense> get filteredExpenses {
    var result = _expenses;

    if (_filterYear != null) {
      result = result.where((e) => e.year == _filterYear).toList();
    }

    if (_filterMinAmount != null) {
      result =
          result.where((e) => e.totalExpenses >= _filterMinAmount!).toList();
    }

    if (_filterMaxAmount != null) {
      result =
          result.where((e) => e.totalExpenses <= _filterMaxAmount!).toList();
    }

    return result;
  }

  /// Get filtered running costs based on current filters
  List<RunningCost> get filteredRunningCosts {
    var result = _runningCosts;

    if (_filterYear != null) {
      result = result.where((c) => c.year == _filterYear).toList();
    }

    if (_filterCategory != null) {
      result = result.where((c) => c.category == _filterCategory).toList();
    }

    if (_filterMinAmount != null) {
      result = result.where((c) => c.amount >= _filterMinAmount!).toList();
    }

    if (_filterMaxAmount != null) {
      result = result.where((c) => c.amount <= _filterMaxAmount!).toList();
    }

    return result;
  }

  /// Search expenses by notes
  List<MonthlyExpense> searchExpensesByNotes(String query) {
    if (query.isEmpty) return _expenses;
    final lowerQuery = query.toLowerCase();
    return _expenses
        .where((e) => e.notes?.toLowerCase().contains(lowerQuery) ?? false)
        .toList();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
