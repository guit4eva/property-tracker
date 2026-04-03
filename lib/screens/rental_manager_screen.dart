import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/property_provider.dart';
import '../models/models.dart';

class RentalManagerScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const RentalManagerScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<RentalManagerScreen> createState() => _RentalManagerScreenState();
}

class _RentalManagerScreenState extends State<RentalManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure we're viewing the correct property's data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PropertyProvider>();
      if (prov.selectedProperty?.id != widget.propertyId) {
        // Find and select the property
        final property = prov.properties.firstWhere(
          (p) => p.id == widget.propertyId,
          orElse: () => prov.properties.first,
        );
        prov.selectProperty(property);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.propertyName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Rental Manager',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Rent Period',
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, prov, _) {
          // Filter rent periods for this property
          final periods = prov.rentPeriods
              .where((r) => r.propertyId == widget.propertyId)
              .toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          if (prov.loading && periods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (periods.isEmpty) {
            return _buildEmptyState();
          }

          return _buildRentPeriodsList(periods);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Rent Period'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Rent Periods Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track rental income by adding\nrent periods for this property',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Add Your First Rent Period',
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
          ],
        ),
      ),
    );
  }

  Widget _buildRentPeriodsList(List<RentPeriod> periods) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (ctx, i) {
        final period = periods[i];
        final now = DateTime.now();
        final isCurrent =
            period.endDate == null || period.endDate!.isAfter(now);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showAddEditDialog(period: period),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCurrent ? Icons.home : Icons.history_edu,
                          color:
                              isCurrent ? const Color(0xFF4CAF50) : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              runSpacing: 2,
                              children: [
                                Text(
                                  'R${period.rentalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateRange(
                                  period.startDate, period.endDate),
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
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showAddEditDialog(period: period);
                          } else if (value == 'delete') {
                            _confirmDelete(period);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Start',
                          DateFormat('MMM yyyy').format(period.startDate),
                          Icons.calendar_today,
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Theme.of(context).dividerColor,
                        ),
                        _buildStatItem(
                          period.endDate == null ? 'End' : 'Ended',
                          period.endDate == null
                              ? 'Ongoing'
                              : DateFormat('MMM yyyy').format(period.endDate!),
                          period.endDate == null
                              ? Icons.more_horiz
                              : Icons.event_busy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final startStr = DateFormat('MMM yyyy').format(start);
    final endStr = end == null ? 'Present' : DateFormat('MMM yyyy').format(end);
    return '$startStr - $endStr';
  }

  void _showAddEditDialog({RentPeriod? period}) {
    showDialog(
      context: context,
      builder: (ctx) => _RentPeriodFormDialog(
        propertyId: widget.propertyId,
        period: period,
      ),
    );
  }

  Future<void> _confirmDelete(RentPeriod period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rent Period'),
        content: Text(
          'Are you sure you want to delete the rent period starting ${DateFormat('MMM yyyy').format(period.startDate)}?',
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
    );

    if (confirmed == true && mounted) {
      await context.read<PropertyProvider>().deleteRentPeriod(period.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rent period deleted')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _RentPeriodFormDialog extends StatefulWidget {
  final String propertyId;
  final RentPeriod? period;

  const _RentPeriodFormDialog({
    required this.propertyId,
    this.period,
  });

  @override
  State<_RentPeriodFormDialog> createState() => _RentPeriodFormDialogState();
}

class _RentPeriodFormDialogState extends State<_RentPeriodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;
  DateTime? _endDate;
  late TextEditingController _amountController;
  bool _isSaving = false;
  bool _isIndefinite = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.period?.startDate ?? DateTime.now();
    _endDate = widget.period?.endDate;
    _amountController = TextEditingController(
      text: widget.period != null
          ? widget.period!.rentalAmount.toStringAsFixed(2)
          : '',
    );
    _isIndefinite = _endDate == null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(initial: _startDate),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    if (_isIndefinite) return;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(
        initial: _endDate ?? _startDate.add(const Duration(days: 365)),
      ),
    );
    if (picked != null) {
      if (picked.isBefore(_startDate)) return;
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final prov = context.read<PropertyProvider>();

      final period = RentPeriod(
        id: widget.period?.id,
        propertyId: widget.propertyId,
        startDate: _startDate,
        endDate: _isIndefinite ? null : _endDate,
        rentalAmount: amount,
        createdAt: DateTime.now(),
      );

      if (widget.period == null) {
        await prov.addRentPeriod(period);
      } else {
        await prov.updateRentPeriod(period);
      }

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.period == null
                ? 'Rent period added'
                : 'Rent period updated'),
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.period == null ? 'Add Rent Period' : 'Edit Rent Period'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monthly Rent Amount',
                  prefixText: 'R ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  if (double.parse(v) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Start Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('MMM yyyy').format(_startDate)),
                onTap: _pickStartDate,
              ),
              const Divider(height: 1),

              // Ongoing toggle - moved below start date
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: const Text('Ongoing (no end date)'),
                subtitle: const Text('Enable if this is the current rent'),
                value: _isIndefinite,
                onChanged: (v) => setState(() => _isIndefinite = v),
              ),

              if (!_isIndefinite) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_busy),
                  ),
                  title: const Text('End Date'),
                  subtitle: _endDate != null
                      ? Text(DateFormat('MMM yyyy').format(_endDate!))
                      : const Text('Select end date'),
                  onTap: _pickEndDate,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog for picking month and year only (no day).
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
