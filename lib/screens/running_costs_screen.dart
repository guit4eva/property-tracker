import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../widgets/shared_widgets.dart' as widgets;
import '../models/models.dart';

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
          appBar: AppBar(title: const Text('Running Costs'), actions: [
            IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Running Cost',
                onPressed: () => _showAddEditDialog(context, prov))
          ]),
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
    final previousCosts = yearCosts.where((c) {
      if (c.endDate != null && c.endDate!.isBefore(now)) return true;
      final costDate = DateTime(c.year, c.month);
      return costDate.isBefore(now) && costDate.month != now.month;
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
      if (activeCosts.isNotEmpty) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Icon(Icons.play_circle_outline,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('Active Running Costs',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary))
            ]))
      ],
      Expanded(
          flex: 2,
          child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount:
                  activeCosts.isEmpty ? yearCosts.length : activeCosts.length,
              itemBuilder: (ctx, i) {
                final cost =
                    activeCosts.isEmpty ? yearCosts[i] : activeCosts[i];
                return _buildCostCard(cost, prov,
                    isActive: activeCosts.isNotEmpty || cost.endDate == null);
              })),
      if (activeCosts.isNotEmpty && previousCosts.isNotEmpty) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Icon(Icons.history,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 6),
              Text('Previous Running Costs',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodySmall?.color))
            ])),
        Expanded(
            flex: 1,
            child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: previousCosts.length,
                itemBuilder: (ctx, i) =>
                    _buildCostCard(previousCosts[i], prov, isActive: false))),
      ],
    ]);
  }

  Widget _buildSummaryCard(List<RunningCost> costs) {
    final totalMonthly =
        costs.fold<double>(0, (sum, c) => sum + c.monthlyEquivalent);
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
          title: Text('${widgets.formatZAR(cost.monthlyEquivalent)}/mo',
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
            : existing?.frequency == CostFrequency.daily
                ? 'daily'
                : 'monthly';
    int timesPerPeriod = existing?.interval ?? 1;
    int everyXPeriods = existing?.interval ?? 1;
    int? dayOfWeek = existing?.dayOfWeek;
    int? dayOfMonth = existing?.dayOfMonth;
    int year = existing?.year ?? _selectedYear;
    int month = existing?.month ?? DateTime.now().month;
    DateTime? endDate = existing?.endDate;
    bool isOngoing = existing?.endDate == null;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
              Text(existing == null ? 'Add Running Cost' : 'Edit Running Cost'),
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
                          value: 'times_per_week',
                          child: Text('🔁 X times per week')),
                      DropdownMenuItem(
                          value: 'times_per_month',
                          child: Text('🔁 X times per month')),
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
                  if (frequencyType == 'times_per_week' ||
                      frequencyType == 'times_per_month') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: timesPerPeriod.toString(),
                      decoration: InputDecoration(
                        labelText: 'How many times?',
                        hintText: frequencyType == 'times_per_week'
                            ? 'Per week'
                            : 'Per month',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                      onChanged: (v) => setDialogState(
                          () => timesPerPeriod = int.tryParse(v) ?? 1),
                    ),
                  ],
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
                  if (frequencyType == 'weekly' ||
                      frequencyType == 'every_x_weeks' ||
                      frequencyType == 'times_per_week') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: dayOfWeek,
                      decoration: const InputDecoration(
                          labelText: 'Day of week (optional)'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Any day')),
                        ...List.generate(7, (i) => i + 1).map((d) {
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
                        }),
                      ],
                      onChanged: (v) => setDialogState(() => dayOfWeek = v),
                    ),
                  ],
                  if (frequencyType == 'monthly' ||
                      frequencyType == 'every_x_months' ||
                      frequencyType == 'times_per_month') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: dayOfMonth,
                      decoration: const InputDecoration(
                          labelText: 'Day of month (optional)'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Any day')),
                        ...List.generate(31, (i) => i + 1).map((d) =>
                            DropdownMenuItem(
                                value: d,
                                child: Text('$d${_getOrdinalSuffix(d)}'))),
                      ],
                      onChanged: (v) => setDialogState(() => dayOfMonth = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: year,
                          decoration: const InputDecoration(labelText: 'Year'),
                          items: List.generate(
                                  5, (i) => DateTime.now().year - 2 + i)
                              .map((y) => DropdownMenuItem(
                                  value: y, child: Text(y.toString())))
                              .toList(),
                          onChanged: (v) => setDialogState(() => year = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: month,
                          decoration: const InputDecoration(labelText: 'Month'),
                          items: List.generate(12, (i) => i + 1)
                              .map((m) => DropdownMenuItem(
                                  value: m, child: Text(widgets.monthName(m))))
                              .toList(),
                          onChanged: (v) => setDialogState(() => month = v!),
                        ),
                      ),
                    ],
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
                            context: ctx,
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
                  if (frequencyType != 'monthly') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Monthly: ${widgets.formatZAR(_calculateMonthlyEquivalentSimple(double.tryParse(amountCtrl.text), frequencyType, timesPerPeriod, everyXPeriods))}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
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
                          } else if (frequencyType == 'times_per_week') {
                            mappedFrequency = CostFrequency.everyXDays;
                            mappedInterval = 7 ~/ timesPerPeriod;
                          } else if (frequencyType == 'times_per_month') {
                            mappedFrequency = CostFrequency.everyXDays;
                            mappedInterval = 30 ~/ timesPerPeriod;
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
                            year: year,
                            month: month,
                            category: category,
                            description:
                                descCtrl.text.isNotEmpty ? descCtrl.text : null,
                            amount: double.parse(amountCtrl.text),
                            frequency: mappedFrequency,
                            interval: mappedInterval,
                            dayOfWeek: dayOfWeek,
                            dayOfMonth: dayOfMonth,
                            startDate:
                                existing?.startDate ?? DateTime(year, month, 1),
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
                              Navigator.pop(ctx);
                              // Switch to the year of the saved cost
                              setState(() => _selectedYear = year);
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
        ),
      ),
    );
  }

  double _calculateMonthlyEquivalentSimple(double? amount, String frequencyType,
      int timesPerPeriod, int everyXPeriods) {
    if (amount == null || amount == 0) return 0;
    switch (frequencyType) {
      case 'yearly':
        return amount / 12;
      case 'weekly':
        return amount * 4;
      case 'times_per_week':
        return amount * timesPerPeriod * 4;
      case 'times_per_month':
        return amount * timesPerPeriod;
      case 'every_x_weeks':
        return amount * (4 / everyXPeriods);
      case 'every_x_months':
        return amount / everyXPeriods;
      default:
        return amount;
    }
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
