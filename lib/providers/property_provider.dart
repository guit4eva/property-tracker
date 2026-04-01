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

  List<RentPeriod> getRentPeriods() => List.unmodifiable(_rentPeriods);

  Future<void> addRentPeriod(RentPeriod period) async {
    try {
      final saved = await SupabaseService.createRentPeriod(period);
      _rentPeriods.add(saved);
      _rentPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));
      notifyListeners();
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
    return getRunningCostsForMonth(year, month)
        .fold(0.0, (sum, c) => sum + c.monthlyEquivalent);
  }

  /// All-time totals for the selected property
  Map<String, double> get allTimeTotals {
    double water = 0,
        elec = 0,
        interest = 0,
        rates = 0,
        running = 0,
        received = 0,
        muniPayments = 0; // NEW
    for (final e in _expenses) {
      water += e.water;
      elec += e.electricity;
      interest += e.interest;
      rates += e.ratesTaxes + (e.annualLevy ?? 0);
      received += e.paymentReceived;
      muniPayments += e.paymentToMunicipality; // NEW
    }
    for (final c in _runningCosts) {
      running += c.monthlyEquivalent;
    }
    return {
      'water': water,
      'electricity': elec,
      'interest': interest,
      'rates': rates,
      'running': running,
      'received': received,
      'municipality_payments': muniPayments, // NEW
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
        'rates': e.ratesTaxes + (e.annualLevy ?? 0),
        'running': 0.0,
        'received': e.paymentReceived,
        'total': e.totalExpenses,
      };
    }
    // merge running costs using monthlyEquivalent
    for (final c in costs) {
      final key = '${c.year}-${c.month.toString().padLeft(2, '0')}';
      if (months.containsKey(key)) {
        months[key]!['running'] =
            (months[key]!['running'] as double) + c.monthlyEquivalent;
        months[key]!['total'] =
            (months[key]!['total'] as double) + c.monthlyEquivalent;
      } else {
        months[key] = {
          'year': c.year,
          'month': c.month,
          'water': 0.0,
          'electricity': 0.0,
          'interest': 0.0,
          'rates': 0.0,
          'running': c.monthlyEquivalent,
          'received': 0.0,
          'total': c.monthlyEquivalent,
        };
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
