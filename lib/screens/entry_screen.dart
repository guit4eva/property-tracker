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

class _EntryScreenState extends State<EntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(initial: _selectedDate),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add / Edit Entry'),
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Monthly Expenses'),
                Tab(text: 'Running Costs'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildMonthSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _MonthlyExpenseForm(
                      key: ValueKey(
                          '${prov.selectedProperty!.id}_${_selectedDate.year}_${_selectedDate.month}'),
                      propertyId: prov.selectedProperty!.id,
                      year: _selectedDate.year,
                      month: _selectedDate.month,
                    ),
                    _RunningCostsTab(
                      propertyId: prov.selectedProperty!.id,
                      year: _selectedDate.year,
                      month: _selectedDate.month,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: ListenableBuilder(
            listenable: _tabs,
            builder: (ctx, _) => _tabs.index == 1
                ? FloatingActionButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddRunningCostDialog(
                        propertyId: prov.selectedProperty!.id,
                        year: _selectedDate.year,
                        month: _selectedDate.month,
                      ),
                    ),
                    child: const Icon(Icons.add),
                  )
                : const SizedBox.shrink(),
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
            onPressed: () => setState(() {
              _selectedDate = DateTime(
                _selectedDate.month == 1
                    ? _selectedDate.year - 1
                    : _selectedDate.year,
                _selectedDate.month == 1 ? 12 : _selectedDate.month - 1,
              );
            }),
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
            onPressed: () => setState(() {
              _selectedDate = DateTime(
                _selectedDate.month == 12
                    ? _selectedDate.year + 1
                    : _selectedDate.year,
                _selectedDate.month == 12 ? 1 : _selectedDate.month + 1,
              );
            }),
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
      _ratesStartDate = existing.ratesStartDate;
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
        paymentToMunicipality: _paymentToMunicipality, // NEW
        notes: _notes.isNotEmpty ? _notes : null,
        ratesFrequency: _ratesFrequency,
        ratesStartDate: _ratesStartDate,
      );
      final saved = await prov.upsertExpense(expense);
      if (mounted) {
        setState(() {
          _existingExpense = saved;
          _isEditing = false; // Switch back to info view after save
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            backgroundColor: Color(0xFF6B8E6B),
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

  void _cancelEditing() {
    if (_existingExpense == null) {
      // No existing data, return to empty state
      setState(() => _isEditing = false);
    } else {
      // Has existing data, return to info view
      setState(() => _isEditing = false);
      // Reset form values to existing data
      _water = _existingExpense!.water;
      _electricity = _existingExpense!.electricity;
      _interest = _existingExpense!.interest;
      _ratesTaxes = _existingExpense!.ratesTaxes;
      _paymentReceived = _existingExpense!.paymentReceived;
      _notes = _existingExpense!.notes ?? '';
      _ratesFrequency = _existingExpense!.ratesFrequency;
      _ratesStartDate = _existingExpense!.ratesStartDate;
    }
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
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month));
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
                  ? 'No data for $monthLabel'
                  : 'No expense data recorded\nfor $monthLabel yet',
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
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Saved entry',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
              e.ratesFrequency == RatesFrequency.annually
                  ? 'Rates & Taxes (annual ÷12)'
                  : 'Rates & Taxes',
              effectiveRates,
              const Color(0xFFAB47BC),
              Icons.account_balance_outlined,
              subtitle: e.ratesFrequency == RatesFrequency.annually
                  ? 'Annual amount: ${formatZAR(e.ratesTaxes)}'
                  : null,
            ),
            _infoRow(
                'Interest', e.interest, const Color(0xFFEF5350), Icons.percent),
          ]),
          const SizedBox(height: 16),

          // Totals card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                _summaryRow('Total Expenses', total, isTotal: true),
                if (e.paymentReceived > 0 || e.paymentToMunicipality > 0) ...[
                  const SizedBox(height: 8),
                  if (e.paymentReceived > 0)
                    _summaryRow('Payment Received', e.paymentReceived),
                  if (e.paymentToMunicipality > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(
                        'Payment to Municipality', e.paymentToMunicipality),
                  ],
                  const Divider(height: 16),
                  _summaryRow(
                    'Balance After Payments',
                    balanceAfterMuni,
                    isTotal: true,
                    isBalance: true,
                    balance: balanceAfterMuni,
                  ),
                ],
              ],
            ),
          ),

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
      {String? subtitle}) {
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
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
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
    final totalExpenses = _water +
        _electricity +
        _interest +
        (_ratesFrequency == RatesFrequency.annually
            ? _ratesTaxes / 12
            : _ratesTaxes);
    final balancePreview =
        _paymentReceived - totalExpenses - _paymentToMunicipality;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editing Entry',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(
                                    DateTime(widget.year, widget.month)),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
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

                // Live Balance Preview Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: balancePreview >= 0
                          ? [
                              const Color(0xFF6B8E6B).withValues(alpha: 0.15),
                              const Color(0xFF81C784).withValues(alpha: 0.1)
                            ]
                          : [
                              const Color(0xFFE07A5F).withValues(alpha: 0.15),
                              const Color(0xFFEF5350).withValues(alpha: 0.1)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: balancePreview >= 0
                          ? const Color(0xFF6B8E6B).withValues(alpha: 0.4)
                          : const Color(0xFFE07A5F).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (balancePreview >= 0
                                ? const Color(0xFF6B8E6B)
                                : const Color(0xFFE07A5F))
                            .withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance Preview',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                balancePreview >= 0 ? 'Surplus' : 'Deficit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: balancePreview >= 0
                                      ? const Color(0xFF6B8E6B)
                                      : const Color(0xFFE07A5F),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatZAR(balancePreview.abs()),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: balancePreview >= 0
                                  ? const Color(0xFF6B8E6B)
                                  : const Color(0xFFE07A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      _miniSummaryRow(
                          'Income', _paymentReceived, const Color(0xFF6B8E6B)),
                      const SizedBox(height: 8),
                      _miniSummaryRow(
                          'Expenses', totalExpenses, const Color(0xFFEF5350)),
                      if (_paymentToMunicipality > 0) ...[
                        const SizedBox(height: 8),
                        _miniSummaryRow('Municipality Payment',
                            _paymentToMunicipality, const Color(0xFF9C74CC)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                child: SizedBox(
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
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _miniSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          formatZAR(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 12),
        Container(
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
                'How do you pay rates for this property this year?',
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
                onSelectionChanged: (set) {
                  setState(() {
                    _ratesFrequency = set.first;
                    _ratesTaxes = 0; // Reset amount when switching frequency
                  });
                },
              ),
              if (_ratesFrequency == RatesFrequency.annually) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter the full annual amount. '
                          'Monthly calculations will use ${_ratesTaxes > 0 ? formatZAR(_ratesTaxes / 12) : 'R0.00'}/month.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range, size: 20),
                title: const Text('Rates Start Date',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  _ratesStartDate != null
                      ? DateFormat('d MMMM yyyy').format(_ratesStartDate!)
                      : 'Not set (defaults to this month)',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _ratesStartDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
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

// ─── Running Costs Tab ────────────────────────────────────────────────────────

class _RunningCostsTab extends StatelessWidget {
  final String propertyId;
  final int year;
  final int month;

  const _RunningCostsTab({
    required this.propertyId,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        final costs = prov.getRunningCostsForMonth(year, month);
        final total = costs.fold(0.0, (s, c) => s + c.amount);

        return Column(
          children: [
            if (costs.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Running Costs',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      formatZAR(total),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: costs.isEmpty
                  ? const EmptyState(
                      message: 'No running costs this month.\nTap + to add.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: costs.length,
                      itemBuilder: (ctx, i) => _CostItem(
                        cost: costs[i],
                        onDelete: () => prov.deleteRunningCost(costs[i].id!),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CostItem extends StatelessWidget {
  final RunningCost cost;
  final VoidCallback onDelete;

  const _CostItem({required this.cost, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Text(
            cost.category.emoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cost.description ?? cost.category.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  cost.category.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  'Started ${DateFormat('MMM yyyy').format(cost.startDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatZAR(cost.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.grey,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete cost?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (confirmed == true) onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Add Running Cost dialog ──────────────────────────────────────────────────

class AddRunningCostDialog extends StatefulWidget {
  final String propertyId;
  final int year;
  final int month;

  const AddRunningCostDialog({
    super.key,
    required this.propertyId,
    required this.year,
    required this.month,
  });

  @override
  State<AddRunningCostDialog> createState() => _AddRunningCostDialogState();
}

class _AddRunningCostDialogState extends State<AddRunningCostDialog> {
  CostCategory _category = CostCategory.cleaning;
  String _description = '';
  double _amount = 0;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  Future<void> _save() async {
    if (_amount <= 0) return;
    setState(() => _saving = true);
    try {
      await context.read<PropertyProvider>().addRunningCost(
            RunningCost(
              propertyId: widget.propertyId,
              year: widget.year,
              month: widget.month,
              category: _category,
              description: _description.isNotEmpty ? _description : null,
              amount: _amount,
              startDate: _startDate,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Running Cost'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<CostCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: CostCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(c.emoji),
                            const SizedBox(width: 8),
                            Text(c.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 8),
            Text(
              _category.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Specific details about this cost',
              ),
              onChanged: (v) => _description = v,
            ),
            const SizedBox(height: 12),
            CurrencyField(
              label: 'Monthly Amount',
              initialValue: _amount,
              onChanged: (v) => _amount = v,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: const Text('Start Date'),
              subtitle: Text(
                'Started: ${DateFormat('d MMM yyyy').format(_startDate)}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
                child: const Text('Change'),
              ),
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
          onPressed: _saving ? null : _save,
          child: const Text('Add'),
        ),
      ],
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
