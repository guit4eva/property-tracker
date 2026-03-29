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
                icon: Icons.home_work_outlined,
              ),
            ),
          );
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
                  icon: Icons.receipt_long_outlined,
                )
              : _buildContent(prov, yearCosts, years),
        );
      },
    );
  }

  Widget _buildContent(
      PropertyProvider prov, List<RunningCost> yearCosts, List<int> years) {
    return Column(
      children: [
        // Year selector
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: years.contains(_selectedYear) ? _selectedYear : years.last,
              isExpanded: true,
              items: years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y Running Costs',
                            style: const TextStyle(fontSize: 16)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
            ),
          ),
        ),
        // Summary card
        _buildSummaryCard(yearCosts),
        // List of costs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: yearCosts.length,
            itemBuilder: (ctx, i) {
              final cost = yearCosts[i];
              return _buildCostCard(cost, prov);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(List<RunningCost> costs) {
    final totalMonthly =
        costs.fold<double>(0, (sum, c) => sum + c.monthlyEquivalent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6B8E6B).withValues(alpha: 0.15),
            const Color(0xFF81C784).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B8E6B).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Monthly Running Costs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widgets.formatZAR(totalMonthly),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B8E6B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${costs.length} cost(s) in $_selectedYear',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard(RunningCost cost, PropertyProvider prov) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cost.category.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(cost.category.icon, color: cost.category.color),
        ),
        title: Text(
          widgets.formatZAR(cost.monthlyEquivalent) + '/mo',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF6B8E6B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              cost.description ?? cost.category.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cost.category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cost.frequency.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cost.category.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widgets.monthYear(cost.year, cost.month),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (v) {
            if (v == 'edit') {
              _showAddEditDialog(context, prov, cost);
            } else if (v == 'delete') {
              _deleteCost(prov, cost.id!);
            }
          },
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, PropertyProvider prov,
      [RunningCost? existing]) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl =
        TextEditingController(text: existing?.amount.toStringAsFixed(2) ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    CostCategory category = existing?.category ?? CostCategory.garden;
    CostFrequency frequency = existing?.frequency ?? CostFrequency.monthly;
    int year = existing?.year ?? _selectedYear;
    int month = existing?.month ?? DateTime.now().month;
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
                              value: c,
                              child: Text(c.label),
                            ))
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
                  DropdownButtonFormField<CostFrequency>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: CostFrequency.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.label),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => frequency = v!),
                  ),
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
                  if (frequency != CostFrequency.monthly) ...[
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
                              'Monthly equivalent: ${widgets.formatZAR(double.tryParse(amountCtrl.text) != null ? (frequency == CostFrequency.yearly ? double.parse(amountCtrl.text) / 12 : frequency == CostFrequency.weekly ? double.parse(amountCtrl.text) * 4.33 : frequency == CostFrequency.daily ? double.parse(amountCtrl.text) * 30.44 : double.parse(amountCtrl.text)) : 0)}',
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
                          final cost = RunningCost(
                            id: existing?.id,
                            propertyId: prov.selectedProperty!.id,
                            year: year,
                            month: month,
                            category: category,
                            description:
                                descCtrl.text.isNotEmpty ? descCtrl.text : null,
                            amount: double.parse(amountCtrl.text),
                            frequency: frequency,
                          );
                          if (existing == null) {
                            await prov.addRunningCost(cost);
                          } else {
                            // Update not implemented yet - delete and re-add
                            await prov.deleteRunningCost(existing.id!);
                            await prov.addRunningCost(cost);
                          }
                          if (context.mounted) Navigator.pop(ctx);
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

  Future<void> _deleteCost(PropertyProvider prov, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Running Cost'),
        content:
            const Text('Are you sure you want to delete this running cost?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await prov.deleteRunningCost(id);
    }
  }
}
