import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../widgets/shared_widgets.dart' as widgets;
import '../models/models.dart';
import 'running_costs_history_screen.dart';

class RunningCostsScreen extends StatefulWidget {
  const RunningCostsScreen({super.key});
  @override
  State<RunningCostsScreen> createState() => _RunningCostsScreenState();
}

class _RunningCostsScreenState extends State<RunningCostsScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        if (prov.selectedProperty == null) {
          return const Scaffold(
              body: Center(
                  child: widgets.EmptyState(
                      message: 'No property selected.\nGo to Properties tab.',
                      icon: Icons.home_work_outlined)));
        }
        final costs = prov.runningCosts;
        final years = costs.map((c) => c.year).toSet().toList()..sort();
        if (years.isEmpty) years.add(_selectedYear);
        if (!years.contains(_selectedYear)) _selectedYear = years.last;
        final yearCosts = costs.where((c) => c.year == _selectedYear).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Running Costs'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'View History',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RunningCostsHistoryScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Running Cost',
                onPressed: () => _showAddEditDialog(context, prov),
              ),
            ],
          ),
          body: yearCosts.isEmpty
              ? widgets.EmptyState(
                  message:
                      'No running costs for $_selectedYear.\n\nTap + to add one.',
                  icon: Icons.receipt_long_outlined)
              : _buildContent(prov, yearCosts, years),
        );
      },
    );
  }

  Widget _buildContent(
      PropertyProvider prov, List<RunningCost> yearCosts, List<int> years) {
    final now = DateTime.now();
    final activeCosts = yearCosts.where((c) {
      if (c.endDate != null && c.endDate!.isBefore(now)) return false;
      final costDate = DateTime(c.year, c.month);
      return costDate.isBefore(now) || costDate.month == now.month;
    }).toList();

    return Column(children: [
      Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                  value: years.contains(_selectedYear)
                      ? _selectedYear
                      : years.last,
                  isExpanded: true,
                  items: years
                      .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text('$y Running Costs',
                              style: const TextStyle(fontSize: 16))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedYear = v!)))),
      _buildSummaryCard(yearCosts),
      Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: yearCosts.length,
              itemBuilder: (ctx, i) {
                final cost = yearCosts[i];
                final isActive =
                    cost.endDate == null || cost.endDate!.isAfter(now);
                return _buildCostCard(cost, prov, isActive: isActive);
              })),
    ]);
  }

  Widget _buildSummaryCard(List<RunningCost> costs) {
    final totalMonthly = costs.fold<double>(0, (sum, c) => sum + c.amount);
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF6B8E6B).withValues(alpha: 0.15),
              const Color(0xFF81C784).withValues(alpha: 0.1)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF6B8E6B).withValues(alpha: 0.4),
                width: 1.5)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Monthly Running Costs',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(widgets.formatZAR(totalMonthly),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B8E6B))),
                  ]),
            ),
            Text('${costs.length} cost${costs.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ));
  }

  Widget _buildCostCard(RunningCost cost, PropertyProvider prov,
      {bool isActive = true}) {
    final isPast =
        cost.endDate != null && cost.endDate!.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? null : Theme.of(context).colorScheme.surface,
      child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: isPast
                      ? Colors.grey.withValues(alpha: 0.15)
                      : cost.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(cost.category.icon,
                  color: isPast ? Colors.grey : cost.category.color, size: 20)),
          title: Text(widgets.formatZAR(cost.amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPast ? Colors.grey : const Color(0xFF6B8E6B))),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 2),
            Text(cost.description ?? cost.category.label,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: isPast ? Colors.grey.withValues(alpha: 0.7) : null)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.withValues(alpha: 0.15)
                          : cost.category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(cost.frequencyDisplay,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPast ? Colors.grey : cost.category.color))),
              const SizedBox(width: 8),
              Text(widgets.monthYear(cost.year, cost.month),
                  style: TextStyle(
                      fontSize: 11,
                      color: isPast
                          ? Colors.grey.withValues(alpha: 0.7)
                          : Theme.of(context).textTheme.bodySmall?.color)),
              if (cost.endDate != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.event_busy,
                    size: 12,
                    color: isPast
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                    'End: ${cost.endDate!.day}/${cost.endDate!.month}/${cost.endDate!.year}',
                    style: TextStyle(
                        fontSize: 10,
                        color: isPast
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary))
              ],
            ]),
            if (isPast) ...[
              const SizedBox(height: 4),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Ended',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)))
            ],
          ]),
          trailing: PopupMenuButton(
              itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('Delete', style: TextStyle(color: Colors.red)))
                  ],
              onSelected: (v) {
                if (v == 'edit') {
                  _showAddEditDialog(context, prov, cost);
                } else if (v == 'delete') _deleteCost(prov, cost.id!);
              })),
    );
  }

  String _getOrdinalSuffix(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _showAddEditDialog(BuildContext context, PropertyProvider prov,
      [RunningCost? existing]) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl =
        TextEditingController(text: existing?.amount.toStringAsFixed(2) ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    CostCategory category = existing?.category ?? CostCategory.garden;
    String frequencyType = existing?.frequency == CostFrequency.yearly
        ? 'yearly'
        : existing?.frequency == CostFrequency.weekly
            ? 'weekly'
            : existing?.frequency == CostFrequency.everyXWeeks
                ? 'every_x_weeks'
                : existing?.frequency == CostFrequency.everyXMonths
                    ? 'every_x_months'
                    : 'monthly';
    int timesPerPeriod = existing?.interval ?? 1;
    int everyXPeriods = existing?.interval ?? 1;
    int? dayOfWeek = existing?.dayOfWeek;
    int? dayOfMonth = existing?.dayOfMonth;
    DateTime startDate =
        existing?.startDate ?? DateTime(_selectedYear, DateTime.now().month);
    DateTime? endDate = existing?.endDate;
    bool isOngoing = existing?.endDate == null;
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> pickStartDate() async {
            final picked = await showDialog<DateTime>(
              context: dialogCtx,
              builder: (pickerCtx) =>
                  _MonthYearPickerDialog(initial: startDate),
            );
            if (picked != null) setDialogState(() => startDate = picked);
          }

          return AlertDialog(
            title: Text(
                existing == null ? 'Add Running Cost' : 'Edit Running Cost'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<CostCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: CostCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text('${c.emoji} ${c.label}')))
                          .toList(),
                      onChanged: (v) => setDialogState(() => category = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: frequencyType,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: const [
                        DropdownMenuItem(
                            value: 'monthly', child: Text('📆 Monthly')),
                        DropdownMenuItem(
                            value: 'weekly', child: Text('📆 Weekly')),
                        DropdownMenuItem(
                            value: 'yearly', child: Text('📆 Yearly')),
                        DropdownMenuItem(
                            value: 'every_x_weeks',
                            child: Text('🔁 Every X weeks')),
                        DropdownMenuItem(
                            value: 'every_x_months',
                            child: Text('🔁 Every X months')),
                      ],
                      onChanged: (v) => setDialogState(() {
                        frequencyType = v!;
                        timesPerPeriod = 1;
                        everyXPeriods = 1;
                      }),
                    ),
                    if (frequencyType == 'every_x_weeks' ||
                        frequencyType == 'every_x_months') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: everyXPeriods.toString(),
                        decoration: InputDecoration(
                            labelText: 'Every how many?',
                            hintText: frequencyType == 'every_x_weeks'
                                ? 'Weeks'
                                : 'Months'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                        onChanged: (v) => setDialogState(
                            () => everyXPeriods = int.tryParse(v) ?? 1),
                      ),
                    ],
                    // Day of week for weekly frequencies
                    if (frequencyType == 'weekly' ||
                        frequencyType == 'every_x_weeks') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: dayOfWeek ?? 1,
                        decoration:
                            const InputDecoration(labelText: 'Day of week'),
                        items: List.generate(7, (i) => i + 1).map((d) {
                          const days = [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ];
                          return DropdownMenuItem(
                              value: d, child: Text(days[d - 1]));
                        }).toList(),
                        onChanged: (v) => setDialogState(() => dayOfWeek = v),
                      ),
                    ],
                    // Start Date
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, size: 20),
                      title: const Text('Start Date'),
                      subtitle: Text(
                          '${startDate.day}/${startDate.month}/${startDate.year}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogCtx,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                        child: const Text('Set'),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ongoing (no end date)'),
                      subtitle: const Text(
                          'Enable if this cost continues indefinitely'),
                      value: isOngoing,
                      onChanged: (v) => setDialogState(() => isOngoing = v),
                    ),
                    if (!isOngoing) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_busy, size: 20),
                        title: const Text('End Date'),
                        subtitle: endDate != null
                            ? Text(
                                '${endDate!.day}/${endDate!.month}/${endDate!.year}')
                            : const Text('Select end date'),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                          child: const Text('Set'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Amount', prefixText: 'R '),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              StatefulBuilder(
                builder: (ctx, setBtnState) => ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setBtnState(() => saving = true);
                            CostFrequency mappedFrequency;
                            int? mappedInterval;
                            if (frequencyType == 'yearly') {
                              mappedFrequency = CostFrequency.yearly;
                              mappedInterval = null;
                            } else if (frequencyType == 'weekly') {
                              mappedFrequency = CostFrequency.weekly;
                              mappedInterval = null;
                            } else if (frequencyType == 'every_x_weeks') {
                              mappedFrequency = CostFrequency.everyXWeeks;
                              mappedInterval = everyXPeriods;
                            } else if (frequencyType == 'every_x_months') {
                              mappedFrequency = CostFrequency.everyXMonths;
                              mappedInterval = everyXPeriods;
                            } else {
                              mappedFrequency = CostFrequency.monthly;
                              mappedInterval = null;
                            }
                            final cost = RunningCost(
                              id: existing?.id,
                              propertyId: prov.selectedProperty!.id,
                              year: startDate.year,
                              month: startDate.month,
                              category: category,
                              description: descCtrl.text.isNotEmpty
                                  ? descCtrl.text
                                  : null,
                              amount: double.parse(amountCtrl.text),
                              frequency: mappedFrequency,
                              interval: mappedInterval,
                              dayOfWeek: dayOfWeek,
                              dayOfMonth: dayOfMonth,
                              startDate: startDate,
                              endDate: isOngoing ? null : endDate,
                            );
                            try {
                              if (existing == null) {
                                await prov.addRunningCost(cost);
                              } else {
                                await prov.deleteRunningCost(existing.id!);
                                await prov.addRunningCost(cost);
                              }
                              if (context.mounted) {
                                Navigator.pop(dialogCtx);
                                // Switch to the year of the saved cost
                                setState(() => _selectedYear = startDate.year);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(existing == null
                                        ? 'Running cost added'
                                        : 'Running cost updated'),
                                    backgroundColor: const Color(0xFF6B8E6B),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCost(PropertyProvider prov, String id) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Delete Running Cost'),
                content: const Text(
                    'Are you sure you want to delete this running cost?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)))
                ]));
    if (confirmed == true) await prov.deleteRunningCost(id);
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
