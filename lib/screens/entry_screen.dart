import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/property_provider.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late DateTime _selectedDate;
  late PageController _pageController;
  static const int _totalMonths = 240; // 20 years range
  static const int _centerIndex = _totalMonths ~/ 2; // Center point
  final _formKey = GlobalKey<_MonthlyExpenseFormState>();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month);
    _pageController = PageController(initialPage: _centerIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _dateToIndex(DateTime date) {
    final now = DateTime.now();
    final nowIndex = now.year * 12 + (now.month - 1); // Zero-based month
    final dateIndex = date.year * 12 + (date.month - 1); // Zero-based month
    return _centerIndex + (dateIndex - nowIndex);
  }

  DateTime _indexToDate(int index) {
    final now = DateTime.now();
    final nowIndex = now.year * 12 + (now.month - 1); // Zero-based month
    final dateIndex = nowIndex + (index - _centerIndex);
    final year = dateIndex ~/ 12;
    final month = (dateIndex % 12) + 1; // Convert back to 1-based month
    return DateTime(year, month);
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(initial: _selectedDate),
    );
    if (picked != null) {
      final targetIndex = _dateToIndex(picked);
      setState(() => _selectedDate = picked);
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousMonth() {
    final newDate = DateTime(
      _selectedDate.month == 1 ? _selectedDate.year - 1 : _selectedDate.year,
      _selectedDate.month == 1 ? 12 : _selectedDate.month - 1,
    );
    setState(() => _selectedDate = newDate);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    final newDate = DateTime(
      _selectedDate.month == 12 ? _selectedDate.year + 1 : _selectedDate.year,
      _selectedDate.month == 12 ? 1 : _selectedDate.month + 1,
    );
    setState(() => _selectedDate = newDate);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        if (prov.selectedProperty == null) {
          return const Scaffold(
            body: EmptyState(
              message: 'No property selected.\nGo to Properties tab.',
              icon: Icons.home_work_outlined,
            ),
          );
        }

        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            // Exit edit mode when navigating away
            _formKey.currentState?.exitEditMode();
          },
          child: Scaffold(
            body: Column(
              children: [
                _buildMonthSelector(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _totalMonths,
                    onPageChanged: (index) {
                      final newDate = _indexToDate(index);
                      setState(() => _selectedDate = newDate);
                    },
                    itemBuilder: (context, index) {
                      final date = _indexToDate(index);

                      return _MonthlyExpenseForm(
                        key: ValueKey(
                            '${prov.selectedProperty!.id}_${date.year}_${date.month}'),
                        propertyId: prov.selectedProperty!.id,
                        year: date.year,
                        month: date.month,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Expense Form ─────────────────────────────────────────────────────

class _MonthlyExpenseForm extends StatefulWidget {
  final String propertyId;
  final int year;
  final int month;

  const _MonthlyExpenseForm({
    super.key,
    required this.propertyId,
    required this.year,
    required this.month,
  });

  @override
  State<_MonthlyExpenseForm> createState() => _MonthlyExpenseFormState();
}

class _MonthlyExpenseFormState extends State<_MonthlyExpenseForm> {
  // Form field values
  double _water = 0;
  double _electricity = 0;
  double _interest = 0;
  double _ratesTaxes = 0;
  double _paymentReceived = 0;
  double _paymentToMunicipality = 0; // NEW
  String _notes = '';
  bool _saving = false;
  RatesFrequency _ratesFrequency = RatesFrequency.monthly;
  DateTime? _ratesStartDate;

  // View state: null = loading/new, false = show empty state, true = editing
  bool _isEditing = false;
  MonthlyExpense? _existingExpense;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void didUpdateWidget(_MonthlyExpenseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if property or month changed
    if (oldWidget.propertyId != widget.propertyId ||
        oldWidget.year != widget.year ||
        oldWidget.month != widget.month) {
      _loadExisting();
    }
  }

  void _loadExisting() {
    final prov = context.read<PropertyProvider>();
    final existing = prov.getExpenseForMonth(widget.year, widget.month);

    if (existing != null) {
      _existingExpense = existing;
      _water = existing.water;
      _electricity = existing.electricity;
      _interest = existing.interest;
      _ratesTaxes = existing.ratesTaxes;
      _paymentReceived = existing.paymentReceived;
      _paymentToMunicipality = existing.paymentToMunicipality; // NEW
      _notes = existing.notes ?? '';
      _ratesFrequency = existing.ratesFrequency;
      // If annual rates but no start date, default to Jan 1
      _ratesStartDate = existing.ratesStartDate ??
          (existing.ratesFrequency == RatesFrequency.annually
              ? DateTime(existing.year, 1, 1)
              : null);
      _isEditing = false; // Show info view by default when data exists
    } else {
      _existingExpense = null;
      _water = 0;
      _electricity = 0;
      _interest = 0;
      _ratesTaxes = 0;
      // Auto-populate rent if available for this month
      _paymentReceived = prov.getRentForMonth(widget.year, widget.month) ?? 0;
      _paymentToMunicipality = 0; // NEW
      _notes = '';
      _ratesFrequency = RatesFrequency.monthly;
      _ratesStartDate = null;
      _isEditing = false; // Show empty state CTA when no data
    }
  }

  void exitEditMode() {
    if (_isEditing) {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _editAnnualRates() async {
    if (_existingExpense == null) return;

    final amountCtrl = TextEditingController(
      text: _existingExpense!.ratesTaxes.toStringAsFixed(2),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Annual Rates for ${widget.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current annual amount: ${formatZAR(_existingExpense!.ratesTaxes)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _existingExpense!.ratesStartDate != null
                  ? 'Period: ${_formatDateRange(_existingExpense!.ratesStartDate!, widget.year)}${_existingExpense!.annualRatesEndDate != null ? ' to ' + _formatDate(_existingExpense!.annualRatesEndDate!) : ''}'
                  : 'Period: 1 Jan ${widget.year} to 31 Dec ${widget.year} (default)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(
                labelText: 'New Annual Amount',
                prefixText: 'R ',
                hintText: 'e.g., 12000',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountCtrl.text);
              if (newAmount != null && newAmount > 0) {
                // Use existing start date or default to Jan 1 of current year
                final startDate = _existingExpense!.ratesStartDate ??
                    DateTime(widget.year, 1, 1);
                Navigator.pop(ctx, {
                  'amount': newAmount,
                  'startDate': startDate,
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isEditing = true;
        _ratesTaxes = result['amount'] as double;
        _ratesFrequency = RatesFrequency.annually;
        _ratesStartDate = result['startDate'] as DateTime?;
      });
    }
  }

  void _deleteAnnualRates() {
    if (_existingExpense == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Annual Rates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete annual rates for ${widget.year}?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              _existingExpense!.ratesStartDate != null
                  ? 'Period: ${_formatDateRange(_existingExpense!.ratesStartDate!, widget.year)}${_existingExpense!.annualRatesEndDate != null ? ' to ' + _formatDate(_existingExpense!.annualRatesEndDate!) : ''}'
                  : 'Period: 1 Jan ${widget.year} to 31 Dec ${widget.year} (default)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will remove rates from all 12 months and reset them to monthly.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final prov = context.read<PropertyProvider>();
        // Delete expenses for all 12 months
        for (int m = 1; m <= 12; m++) {
          final expense = prov.getExpenseForMonth(widget.year, m);
          if (expense != null &&
              expense.ratesFrequency == RatesFrequency.annually) {
            final updatedExpense = expense.copyWith(
              ratesTaxes: 0,
              ratesFrequency: RatesFrequency.monthly,
            );
            await prov.upsertExpense(updatedExpense);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Annual rates deleted'),
              backgroundColor: Color(0xFF6B8E6B),
            ),
          );
        }
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prov = context.read<PropertyProvider>();
      final expense = MonthlyExpense(
        id: _existingExpense?.id,
        propertyId: widget.propertyId,
        year: widget.year,
        month: widget.month,
        water: _water,
        electricity: _electricity,
        interest: _interest,
        ratesTaxes: _ratesTaxes,
        paymentReceived: _paymentReceived,
        paymentToMunicipality: _paymentToMunicipality,
        notes: _notes.isNotEmpty ? _notes : null,
        ratesFrequency: _ratesFrequency,
        ratesStartDate: _ratesStartDate,
      );
      final saved = await prov.upsertExpense(expense);

      // If annual rates, overwrite ALL months in the year with the divided amount
      // Note: We save the FULL annual amount to all months with annually frequency
      // The effectiveMonthlyRates getter will divide by 12 for display/calculation
      if (_ratesFrequency == RatesFrequency.annually && _ratesTaxes > 0) {
        for (int m = 1; m <= 12; m++) {
          // Get existing data for this month
          final existingMonth = prov.getExpenseForMonth(widget.year, m);

          // Create/update expense for this month with the SAME annual amount
          final monthExpense = MonthlyExpense(
            propertyId: widget.propertyId,
            year: widget.year,
            month: m,
            water: existingMonth?.water ?? 0,
            electricity: existingMonth?.electricity ?? 0,
            interest: existingMonth?.interest ?? 0,
            ratesTaxes: _ratesTaxes, // Save full annual amount to ALL months
            paymentReceived: existingMonth?.paymentReceived ??
                prov.getRentForMonth(widget.year, m) ??
                0,
            paymentToMunicipality: existingMonth?.paymentToMunicipality ?? 0,
            ratesFrequency: RatesFrequency.annually,
            ratesStartDate: _ratesStartDate,
          );
          await prov.upsertExpense(monthExpense);
        }
      }

      if (mounted) {
        setState(() {
          _existingExpense = saved;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_ratesFrequency == RatesFrequency.annually
                ? 'Saved! Annual rates divided across all months in $widget.year'
                : 'Saved successfully'),
            backgroundColor: const Color(0xFF6B8E6B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  String _formatDateRange(DateTime? startDate, int year) {
    if (startDate == null) {
      return 'Jan $year - Dec $year';
    }
    // Calculate end date: last day of the same month, one year later
    final actualEndDate = DateTime(startDate.year + 1, startDate.month, 0);
    return '${DateFormat('d MMM yyyy').format(startDate)} to ${DateFormat('d MMM yyyy').format(actualEndDate)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Data exists and not editing → info view
    if (_existingExpense != null && !_isEditing) {
      return _buildInfoView();
    }
    // No data and not editing → show empty state (the new implementation)
    if (_existingExpense == null && !_isEditing) {
      return _buildEmptyState();
    }
    // Either new entry or editing existing
    return _buildForm();
  }

  // ─── Empty State (NEW IMPLEMENTATION) ────────────────────────────────────

  Widget _buildEmptyState() {
    final isFutureMonth = DateTime(widget.year, widget.month)
        .isAfter(DateTime(DateTime.now().year, DateTime.now().month));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withAlpha(40),
                    Theme.of(context).colorScheme.secondary.withAlpha(40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                isFutureMonth
                    ? Icons.calendar_month_outlined
                    : Icons.add_chart_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFutureMonth
                  ? 'No data for this month'
                  : 'No expense data recorded\nfor this month yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isFutureMonth
                  ? 'This month is in the future.\nYou can add estimated expenses.'
                  : 'Tap the button below to enter\nwater, electricity, and other costs.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(180),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Add Expense Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (!isFutureMonth) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter data manually or import from CSV'),
                      backgroundColor: Color(0xFF6B8E6B),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Quick tips'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Info View (read-only, shown when data exists) ─────────────────────────

  Widget _buildInfoView() {
    final e = _existingExpense!;
    final effectiveRates = e.effectiveMonthlyRates;
    final total = e.water + e.electricity + e.interest + effectiveRates;
    final balanceAfterMuni =
        e.paymentReceived - total - e.paymentToMunicipality; // NEW

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Utilities section
          _infoSectionLabel('Utilities'),
          const SizedBox(height: 12),
          _infoCard([
            _infoRow('Water', e.water, const Color(0xFF42A5F5),
                Icons.water_drop_outlined),
            _infoRow('Electricity', e.electricity, const Color(0xFFF5C842),
                Icons.bolt_outlined),
          ]),
          const SizedBox(height: 16),

          // Rates & Finance section
          _infoSectionLabel('Rates & Finance'),
          const SizedBox(height: 12),
          _infoCard([
            _infoRow(
              'Rates & Taxes',
              effectiveRates,
              const Color(0xFFAB47BC),
              Icons.account_balance_outlined,
              subtitle: e.ratesFrequency == RatesFrequency.annually
                  ? '${formatZAR(e.ratesTaxes)}\n(${_formatDateRange(e.ratesStartDate, e.year)})'
                  : null,
              subtitleStyle: const TextStyle(fontStyle: FontStyle.italic),
            ),
            _infoRow(
                'Interest', e.interest, const Color(0xFFEF5350), Icons.percent),
          ]),
          const SizedBox(height: 16),

          // Totals card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _summaryRow('Total Expenses', total, isTotal: true),
              ],
            ),
          ),
          if (e.paymentReceived > 0 || e.paymentToMunicipality > 0) ...[
            const SizedBox(height: 16),

            // Payment Tracking section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  if (e.paymentReceived > 0) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6B8E6B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Color(0xFF6B8E6B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rent Received',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Payment from tenant',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatZAR(e.paymentReceived),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF6B8E6B),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (e.paymentToMunicipality > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF9C74CC).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            color: Color(0xFF9C74CC),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paid to Municipality',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Payment to municipality',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatZAR(e.paymentToMunicipality),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF9C74CC),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Balance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: balanceAfterMuni >= 0
                              ? const Color(0xFF6B8E6B).withValues(alpha: 0.15)
                              : const Color(0xFFE07A5F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatZAR(balanceAfterMuni),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: balanceAfterMuni >= 0
                                ? const Color(0xFF6B8E6B)
                                : const Color(0xFFE07A5F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (balanceAfterMuni >= 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Surplus: Rent covers all expenses',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  if (balanceAfterMuni < 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Deficit: Expenses exceed rent',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (e.notes != null && e.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoSectionLabel('Notes'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(e.notes!),
            ),
          ],
          const SizedBox(height: 24),

          // Edit button at bottom
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, double amount, Color color, IconData icon,
      {String? subtitle, TextStyle? subtitleStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle,
                      style: subtitleStyle ??
                          TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
              ],
            ),
          ),
          Text(
            formatZAR(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount,
      {bool isTotal = false, bool isBalance = false, double? balance}) {
    Color amountColor = Theme.of(context).colorScheme.primary;
    if (isBalance && balance != null) {
      amountColor =
          balance >= 0 ? const Color(0xFF6B8E6B) : const Color(0xFFE07A5F);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                fontSize: isTotal ? 15 : 14)),
        Text(
          formatZAR(amount),
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            fontSize: isTotal ? 16 : 14,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  // ─── Edit/New Form ─────────────────────────────────────────────────────────

  Widget _buildForm() {
    final isEditing = _existingExpense != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Editing entry',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Utilities Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF42A5F5).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.water_drop_outlined,
                            color: Color(0xFF42A5F5), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Utilities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDescribedField(
                  label: 'Water',
                  description:
                      'Monthly water and sewerage charges from municipality',
                  icon: Icons.water_drop_outlined,
                  value: _water,
                  onChanged: (v) => setState(() => _water = v),
                  color: const Color(0xFF42A5F5),
                ),
                const SizedBox(height: 16),
                _buildDescribedField(
                  label: 'Electricity',
                  description:
                      'Monthly electricity bill from municipality or prepaid',
                  icon: Icons.bolt_outlined,
                  value: _electricity,
                  onChanged: (v) => setState(() => _electricity = v),
                  color: const Color(0xFFF5C842),
                ),
                const SizedBox(height: 24),

                // Rates & Finance Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFAB47BC).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_outlined,
                            color: Color(0xFFAB47BC), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Rates & Finance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildRatesSection(),
                const SizedBox(height: 16),
                _buildDescribedField(
                  label: 'Interest',
                  description: 'Monthly mortgage bond interest payment',
                  icon: Icons.percent,
                  value: _interest,
                  onChanged: (v) => setState(() => _interest = v),
                  color: const Color(0xFFEF5350),
                ),
                const SizedBox(height: 24),

                // Payment Tracking Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6B8E6B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.payments_outlined,
                            color: Color(0xFF6B8E6B), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payment Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDescribedField(
                  label: 'Payment Received',
                  description:
                      'Rental income or any payments received this month',
                  icon: Icons.payments_outlined,
                  value: _paymentReceived,
                  onChanged: (v) => setState(() => _paymentReceived = v),
                  color: const Color(0xFF6B8E6B),
                ),
                const SizedBox(height: 16),
                _buildDescribedField(
                  label: 'Payment to Municipality',
                  description:
                      'Payments made to municipality for rates/utilities',
                  icon: Icons.account_balance_outlined,
                  value: _paymentToMunicipality,
                  onChanged: (v) => setState(() => _paymentToMunicipality = v),
                  color: const Color(0xFF9C74CC),
                ),
                const SizedBox(height: 24),

                // Notes Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.note_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextFormField(
                    maxLines: 3,
                    initialValue: _notes,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText:
                          'e.g. meter not read, special circumstances, reminders...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                      ),
                    ),
                    onChanged: (v) => _notes = v,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Sticky Footer with Save Button
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing ? Icons.update : Icons.save,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isEditing ? 'Update Entry' : 'Save Entry',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildDescribedField({
    required String label,
    required String description,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: _EditableCurrencyField(
            label: label,
            value: value,
            onChanged: onChanged,
            hint: description,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatesSection() {
    final prov = context.read<PropertyProvider>();
    final monthlyEquivalent = _ratesFrequency == RatesFrequency.annually
        ? _ratesTaxes / 12
        : _ratesTaxes;

    // Check if this month is covered by annual rates
    // Check if this month ALREADY HAS saved annual rates
    final hasExistingAnnualRates = _existingExpense != null &&
        _existingExpense!.ratesFrequency == RatesFrequency.annually &&
        _existingExpense!.ratesTaxes > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasExistingAnnualRates) ...[
          // Show read-only view for months covered by annual rates
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Annual Rates: ${_formatDateRange(_existingExpense!.ratesStartDate, widget.year)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _editAnnualRates(),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      tooltip: 'Edit annual rates',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                      onPressed: () => _deleteAnnualRates(),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      tooltip: 'Delete annual rates',
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Annual: ${formatZAR(_existingExpense!.ratesTaxes)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              _existingExpense!.ratesStartDate != null
                                  ? 'Period: ${_formatDateRange(_existingExpense!.ratesStartDate!, widget.year)}${_existingExpense!.annualRatesEndDate != null ? ' to ' + _formatDate(_existingExpense!.annualRatesEndDate!) : ''}'
                                  : 'Period: 1 Jan ${widget.year} to 31 Dec ${widget.year} (default)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Amount:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      formatZAR(_existingExpense!.ratesTaxes / 12),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This Month:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      formatZAR(_existingExpense!.ratesTaxes / 12),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // Show editable view
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: _EditableCurrencyField(
              label: _ratesFrequency == RatesFrequency.annually
                  ? 'Annual Rates & Taxes'
                  : 'Monthly Rates & Taxes',
              value: _ratesTaxes,
              onChanged: (v) => setState(() => _ratesTaxes = v),
              hint: _ratesFrequency == RatesFrequency.annually
                  ? 'Total annual amount (will be divided by 12)'
                  : 'Monthly property rates/municipal taxes',
            ),
          ),
          // Show monthly breakdown when annual is selected
          if (_ratesFrequency == RatesFrequency.annually &&
              _ratesTaxes > 0) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly equivalent:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatZAR(monthlyEquivalent),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        if (_ratesFrequency == RatesFrequency.annually && _ratesTaxes > 0) ...[
          // Show note when annual rates are being entered/edited
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ratesStartDate != null
                        ? 'This amount will be saved as annual rates and divided across all 12 months from ${_formatDateRange(_ratesStartDate, widget.year)} to ${_formatDate(DateTime(_ratesStartDate!.year + 1, _ratesStartDate!.month, 0))}'
                        : 'This amount will be saved as annual rates for ${widget.year} and divided across all 12 months',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ] else ...[
          // Show Payment Frequency section (hidden when editing annual rates)
          if (_ratesFrequency != RatesFrequency.annually || _ratesTaxes == 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Frequency',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How are rates paid for this property?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<RatesFrequency>(
                    segments: const [
                      ButtonSegment(
                        value: RatesFrequency.monthly,
                        label: Text('Monthly'),
                        icon: Icon(Icons.calendar_month, size: 16),
                      ),
                      ButtonSegment(
                        value: RatesFrequency.annually,
                        label: Text('Annually'),
                        icon: Icon(Icons.calendar_today, size: 16),
                      ),
                    ],
                    selected: {_ratesFrequency},
                    onSelectionChanged: (set) async {
                      final newFrequency = set.first;

                      // Check if switching to annually with existing monthly data
                      if (newFrequency == RatesFrequency.annually &&
                          _ratesTaxes > 0) {
                        final prov = context.read<PropertyProvider>();
                        final existingMonths = prov.expenses
                            .where((e) =>
                                e.year == widget.year && e.ratesTaxes > 0)
                            .toList();

                        if (existingMonths.isNotEmpty) {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Existing Monthly Data'),
                              content: Text(
                                'You have rates data entered for ${existingMonths.length} month(s) in $widget.year. '
                                'Switching to annual will use the annual amount divided across all months. '
                                'Continue?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Continue'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                        }
                      }

                      setState(() {
                        _ratesFrequency = newFrequency;
                        // When switching to annual, divide by 12 to get approximate annual
                        // When switching to monthly, multiply by 12 to get approximate monthly
                        if (_ratesTaxes > 0) {
                          _ratesTaxes =
                              _ratesFrequency == RatesFrequency.annually
                                  ? _ratesTaxes * 12
                                  : _ratesTaxes / 12;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.date_range, size: 20),
                    title: const Text('Rates Start Month',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _ratesStartDate != null
                          ? DateFormat('MMMM yyyy').format(_ratesStartDate!)
                          : 'Not set (defaults to this month)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDialog<DateTime>(
                          context: context,
                          builder: (ctx) => _MonthYearPickerDialog(
                            initial: _ratesStartDate ?? DateTime.now(),
                          ),
                        );
                        if (date != null) {
                          setState(() => _ratesStartDate = date);
                        }
                      },
                      child: const Text('Set'),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Property rates, municipal taxes, and service charges',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Editable Currency Field ──────────────────────────────────────────────────

class _EditableCurrencyField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? hint;

  const _EditableCurrencyField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  State<_EditableCurrencyField> createState() => _EditableCurrencyFieldState();
}

class _EditableCurrencyFieldState extends State<_EditableCurrencyField> {
  late TextEditingController _ctrl;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value > 0 ? widget.value.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(_EditableCurrencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFocus && oldWidget.value != widget.value) {
      _ctrl.text = widget.value > 0 ? widget.value.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) => _hasFocus = focus,
      child: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint ?? '0.00',
          prefixText: 'R ',
          prefixStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          widget.onChanged(parsed ?? 0);
        },
      ),
    );
  }
}

// ─── Month/Year picker dialog ─────────────────────────────────────────────────

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initial;
  const _MonthYearPickerDialog({required this.initial});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = List.generate(
        12, (i) => DateFormat('MMM').format(DateTime(2000, i + 1)));
    return AlertDialog(
      title: const Text('Select Month'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(12, (i) {
                final m = i + 1;
                final selected = m == _month;
                return GestureDetector(
                  onTap: () => setState(() => _month = m),
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        monthNames[i],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, DateTime(_year, _month)),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
