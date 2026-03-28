import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/property_provider.dart';
import '../widgets/shared_widgets.dart' as widgets;
import '../models/models.dart';

class RentHistoryScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const RentHistoryScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<RentHistoryScreen> createState() => _RentHistoryScreenState();
}

class _RentHistoryScreenState extends State<RentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rent History - ${widget.propertyName}'),
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
          final periods = prov.getRentPeriods();

          if (prov.loading && periods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (periods.isEmpty) {
            return const widgets.EmptyState(
              message:
                  'No rent periods configured yet.\n\nTap + to add a rent period.',
              icon: Icons.attach_money,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: periods.length,
            itemBuilder: (ctx, i) {
              final period = periods[i];
              final isCurrent = period.endDate == null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCurrent ? Icons.home : Icons.history,
                      color: isCurrent ? const Color(0xFF4CAF50) : Colors.grey,
                    ),
                  ),
                  title: Text(
                    'R${period.rentalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? const Color(0xFF4CAF50) : null,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM yyyy').format(period.startDate)} - ${isCurrent ? 'Present' : DateFormat('MMM yyyy').format(period.endDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (isCurrent)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddEditDialog(period: period),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () => _confirmDelete(period),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    if (_isIndefinite) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
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
          createdAt: DateTime.now());

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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
              // Start Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                onTap: _pickStartDate,
              ),
              const Divider(),

              // End Date / Indefinite toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.more_horiz),
                title: const Text('Ongoing (no end date)'),
                subtitle: const Text('Enable if this is the current rent'),
                value: _isIndefinite,
                onChanged: (v) => setState(() => _isIndefinite = v),
              ),

              if (!_isIndefinite) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_busy),
                  title: const Text('End Date'),
                  subtitle: _endDate != null
                      ? Text(DateFormat('dd MMM yyyy').format(_endDate!))
                      : const Text('Select end date'),
                  onTap: _pickEndDate,
                ),
              ],

              const Divider(),

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

// ──────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
