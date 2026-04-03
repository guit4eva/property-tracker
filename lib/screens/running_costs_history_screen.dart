import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart' as widgets;

class RunningCostsHistoryScreen extends StatefulWidget {
  const RunningCostsHistoryScreen({super.key});

  @override
  State<RunningCostsHistoryScreen> createState() =>
      _RunningCostsHistoryScreenState();
}

class _RunningCostsHistoryScreenState extends State<RunningCostsHistoryScreen> {
  final Map<int, bool> _expandedYears = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        if (prov.selectedProperty == null) {
          return const Scaffold(
            body: Center(
              child: widgets.EmptyState(
                message: 'No property selected.',
                icon: Icons.home_work_outlined,
              ),
            ),
          );
        }

        final costs = prov.runningCosts;
        if (costs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Running Costs History')),
            body: const widgets.EmptyState(
              message: 'No running costs history yet.',
              icon: Icons.history_outlined,
            ),
          );
        }

        // Group costs by year
        final costsByYear = <int, List<RunningCost>>{};
        for (final cost in costs) {
          costsByYear.putIfAbsent(cost.year, () => []).add(cost);
        }
        final years = costsByYear.keys.toList()..sort((a, b) => b.compareTo(a));

        // Initialize expanded state
        for (final year in years) {
          _expandedYears.putIfAbsent(year, () => year == years.first);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Running Costs History')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: years.length,
            itemBuilder: (ctx, index) {
              final year = years[index];
              final yearCosts = costsByYear[year]!;
              final isExpanded = _expandedYears[year] ?? false;
              final totalMonthly = yearCosts.fold<double>(
                0,
                (sum, c) => sum + c.amount,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        setState(() => _expandedYears[year] = !isExpanded);
                      },
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        '$year',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${yearCosts.length} cost${yearCosts.length != 1 ? 's' : ''} • ${widgets.formatZAR(totalMonthly)}/mo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: yearCosts
                              .map((cost) => _buildHistoryCostItem(cost))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryCostItem(RunningCost cost) {
    final isPast =
        cost.endDate != null && cost.endDate!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPast
            ? Colors.grey.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPast
              ? Colors.grey.withValues(alpha: 0.2)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey.withValues(alpha: 0.15)
                  : cost.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              cost.category.icon,
              color: isPast ? Colors.grey : cost.category.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cost.description ?? cost.category.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isPast ? Colors.grey : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${widgets.formatZAR(cost.amount)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPast ? Colors.grey : const Color(0xFF6B8E6B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPast
                            ? Colors.grey.withValues(alpha: 0.15)
                            : cost.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cost.frequencyDisplay,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isPast ? Colors.grey : cost.category.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateRange(cost.startDate, cost.endDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: isPast
                        ? Colors.grey.withValues(alpha: 0.7)
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final startStr = '${start.month}/${start.year}';
    if (end == null) return '$startStr - Ongoing';
    final endStr = '${end.month}/${end.year}';
    return '$startStr - $endStr';
  }
}
