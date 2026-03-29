import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/property_provider.dart';
import '../widgets/shared_widgets.dart';
import 'evaluations_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showGraphs = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        if (prov.loading && prov.properties.isEmpty) {
          return const Scaffold(body: LoadingOverlay());
        }

        if (prov.properties.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmptyState(
                    message:
                        'No properties yet.\nAdd one in the Properties tab.',
                    icon: Icons.home_work_outlined,
                  ),
                ],
              ),
            ),
          );
        }

        final totals = prov.allTimeTotals;
        final monthlyData = prov.monthlyTotalsForChart;
        final now = DateTime.now();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, prov),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPropertyHeader(context, prov),
                    const SizedBox(height: 24),
                    _buildViewToggle(),
                    const SizedBox(height: 24),
                    if (!_showGraphs)
                      _buildAllTimeSummary(totals)
                    else
                      _buildExpenseChart(totals),
                    const SizedBox(height: 28),
                    _buildThisMonthCard(context, prov, now),
                    const SizedBox(height: 28),
                    const SectionHeader(title: 'Recent Months'),
                    const SizedBox(height: 14),
                    _buildRecentMonths(context, monthlyData),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, PropertyProvider prov) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home_work,
                size: 18, color: Theme.of(context).colorScheme.onPrimary),
          ),
          const SizedBox(width: 10),
          const Text('Property Tracker'),
        ],
      ),
      actions: [
        // Offline indicator
        if (prov.isOffline)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Offline - changes will sync when online',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Refresh button
        IconButton(
          icon: Icon(
            prov.loading ? Icons.refresh : Icons.refresh,
            size: 20,
          ),
          onPressed: prov.loading ? null : () => prov.refresh(),
          tooltip: 'Refresh data',
        ),
        if (prov.loading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Values'),
              icon: Icon(Icons.format_list_numbered),
            ),
            ButtonSegment(
              value: true,
              label: Text('Graphs'),
              icon: Icon(Icons.pie_chart),
            ),
          ],
          selected: {_showGraphs},
          onSelectionChanged: (set) {
            setState(() => _showGraphs = set.first);
          },
        ),
      ),
    );
  }

  Widget _buildPropertyHeader(BuildContext context, PropertyProvider prov) {
    final prop = prov.selectedProperty!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prop.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (prop.address != null)
                      Text(
                        prop.address!,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (prop.siteValue != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(60)),
                  ),
                  child: Text(
                    formatZAR(prop.currentValue),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _pillStat(
                '${prov.expenses.length}',
                'months tracked',
                Icons.calendar_month,
              ),
              const SizedBox(width: 12),
              _pillStat(
                '${prov.runningCosts.length}',
                'running costs',
                Icons.receipt_long,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EvaluationsScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Evaluations',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillStat(String value, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildAllTimeSummary(Map<String, double> totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'All-Time Summary'),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              label: 'Total Water',
              amount: totals['water']!,
              color: const Color(0xFF42A5F5),
              icon: Icons.water_drop_outlined,
            ),
            StatCard(
              label: 'Total Electricity',
              amount: totals['electricity']!,
              color: const Color(0xFFF5C842),
              icon: Icons.bolt_outlined,
            ),
            StatCard(
              label: 'Total Interest',
              amount: totals['interest']!,
              color: const Color(0xFFEF5350),
              icon: Icons.percent,
            ),
            StatCard(
              label: 'Rates & Taxes',
              amount: totals['rates']!,
              color: const Color(0xFFAB47BC),
              icon: Icons.account_balance_outlined,
            ),
            StatCard(
              label: 'Running Costs',
              amount: totals['running']!,
              color: const Color(0xFF6B8E6B),
              icon: Icons.build_outlined,
            ),
            StatCard(
              label: 'Total Expenses',
              amount: totals['total']!,
              color: Theme.of(context).colorScheme.primary,
              icon: Icons.summarize_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseChart(Map<String, double> totals) {
    final data = [
      PieChartSectionData(
        value: totals['water']!,
        title: 'Water\n${formatCompact(totals['water']!)}',
        color: const Color(0xFF42A5F5),
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: totals['electricity']!,
        title: 'Electricity\n${formatCompact(totals['electricity']!)}',
        color: const Color(0xFFF5C842),
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: totals['interest']!,
        title: 'Interest\n${formatCompact(totals['interest']!)}',
        color: const Color(0xFFEF5350),
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: totals['rates']!,
        title: 'Rates\n${formatCompact(totals['rates']!)}',
        color: const Color(0xFFAB47BC),
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: totals['running']!,
        title: 'Running\n${formatCompact(totals['running']!)}',
        color: const Color(0xFF6B8E6B),
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ].where((section) => section.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Expense Distribution'),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: data.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pie_chart_outline_rounded,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(100),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No expense data yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add expenses to see breakdown',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sections: data,
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            centerSpaceColor: Colors.transparent,
                          ),
                        ),
                ),
                if (data.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildLegend(
                          'Water', const Color(0xFF42A5F5), totals['water']!),
                      _buildLegend('Electricity', const Color(0xFFF5C842),
                          totals['electricity']!),
                      _buildLegend('Interest', const Color(0xFFEF5350),
                          totals['interest']!),
                      _buildLegend(
                          'Rates', const Color(0xFFAB47BC), totals['rates']!),
                      _buildLegend('Running', const Color(0xFF6B8E6B),
                          totals['running']!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${formatCompact(amount)}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  String formatCompact(double value) {
    if (value >= 1000000) {
      return 'R${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R${value.toStringAsFixed(0)}';
  }

  Widget _buildThisMonthCard(
      BuildContext context, PropertyProvider prov, DateTime now) {
    final expense = prov.getExpenseForMonth(now.year, now.month);
    final runningTotal = prov.totalRunningCostsForMonth(now.year, now.month);
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Month',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expense == null)
            Text(
              'No data entered for this month.',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color),
            )
          else ...[
            _row('Water', expense.water, const Color(0xFF42A5F5)),
            _row('Electricity', expense.electricity, const Color(0xFFF5C842)),
            _row('Interest', expense.interest, const Color(0xFFEF5350)),
            _row('Rates & Taxes', expense.effectiveMonthlyRates,
                const Color(0xFFAB47BC)),
            _row('Running Costs', runningTotal, const Color(0xFF6B8E6B)),
            Divider(color: Theme.of(context).dividerColor, height: 24),
            _row(
              'Total Expenses',
              expense.totalExpenses + runningTotal,
              Theme.of(context).colorScheme.primary,
              bold: true,
            ),
            if (expense.paymentReceived > 0) ...[
              _row(
                  'Received', expense.paymentReceived, const Color(0xFF6B8E6B)),
              _row(
                'Balance',
                expense.paymentReceived - expense.totalExpenses - runningTotal,
                expense.paymentReceived >= expense.totalExpenses + runningTotal
                    ? const Color(0xFF6B8E6B)
                    : const Color(0xFFEF5350),
                bold: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(String label, double amount, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withValues(alpha: bold ? 1.0 : 0.8),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: bold ? 15 : 14,
              ),
            ),
          ),
          Text(
            formatZAR(amount),
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMonths(
      BuildContext context, List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const EmptyState(
        message: 'No data yet. Add your first entry.',
        icon: Icons.calendar_month_outlined,
      );
    }

    final recent = data.reversed.take(6).toList();

    return Column(
      children: recent.map((m) {
        final label = monthYear(m['year'] as int, m['month'] as int);
        final total = m['total'] as double;
        final received = m['received'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'W: ${formatZAR(m['water'])} • E: ${formatZAR(m['electricity'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatZAR(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (received > 0)
                    Text(
                      'Rcvd: ${formatZAR(received)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
