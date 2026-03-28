import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/property_provider.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedYear = DateTime.now().year;
  bool _showAllProperties = false; // Toggle for ALL vs selected property

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        // Check if we should show all properties or just selected
        final hasMultipleProperties = prov.properties.length > 1;

        // Get data based on selection
        final allData = _showAllProperties && hasMultipleProperties
            ? prov.allPropertiesMonthlyTotals
            : prov.monthlyTotalsForChart;

        final years = allData.map((m) => m['year'] as int).toSet().toList()
          ..sort();

        if (years.isNotEmpty && !years.contains(_selectedYear)) {
          _selectedYear = years.last;
        }

        final yearData =
            allData.where((m) => m['year'] == _selectedYear).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(_showAllProperties && hasMultipleProperties
                ? 'All Properties Summary'
                : 'Property Summary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy CSV',
                onPressed: () => _copyCSV(context, prov, yearData),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // NEW: Toggle between selected property and ALL properties
                if (hasMultipleProperties) ...[
                  _buildPropertyScopeToggle(prov),
                  const SizedBox(height: 24),
                ],

                _buildYearSelector(years),
                const SizedBox(height: 24),
                _buildYearTotalsCard(yearData),
                const SizedBox(height: 24),
                _buildMonthlyBreakdownTable(yearData, prov),
                const SizedBox(height: 24),
                _buildRunningCostsByCategory(prov, _selectedYear),
                const SizedBox(height: 24),
                if (years.length > 1) _buildYearOverYearComparison(prov, years),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEW: Toggle between single property and all properties
  Widget _buildPropertyScopeToggle(PropertyProvider prov) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary Scope',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label:
                      Text(prov.selectedProperty?.name ?? 'Selected Property'),
                  icon: const Icon(Icons.home),
                ),
                const ButtonSegment(
                  value: true,
                  label: Text('All Properties'),
                  icon: Icon(Icons.home_work),
                ),
              ],
              selected: {_showAllProperties},
              onSelectionChanged: (set) {
                setState(() => _showAllProperties = set.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector(List<int> years) {
    if (years.isEmpty) {
      return Text(
        'No data yet',
        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
      );
    }
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: years.map((y) {
          final sel = y == _selectedYear;
          return GestureDetector(
            onTap: () => setState(() => _selectedYear = y),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                '$y',
                style: TextStyle(
                  color: sel
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildYearTotalsCard(List<Map<String, dynamic>> yearData) {
    if (yearData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          'No data for $_selectedYear',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    double water = 0,
        elec = 0,
        interest = 0,
        rates = 0,
        running = 0,
        received = 0;
    for (final m in yearData) {
      water += m['water'] as double;
      elec += m['electricity'] as double;
      interest += m['interest'] as double;
      rates += m['rates'] as double;
      running += m['running'] as double;
      received += m['received'] as double;
    }
    final total = water + elec + interest + rates + running;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedYear Annual Total',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${yearData.length} months of data${_showAllProperties ? ' (All Properties)' : ''}',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          _summaryRow('💧 Water', water, const Color(0xFF42A5F5)),
          _summaryRow('⚡ Electricity', elec, const Color(0xFFF5C842)),
          _summaryRow('📈 Interest', interest, const Color(0xFFEF5350)),
          _summaryRow('🏛 Rates & Taxes', rates, const Color(0xFFAB47BC)),
          _summaryRow('🔧 Running Costs', running, const Color(0xFF6B8E6B)),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          _summaryRow(
              'Total Expenses', total, Theme.of(context).colorScheme.primary,
              bold: true),
          const SizedBox(height: 8),
          _summaryRow('💰 Total Received', received, const Color(0xFF6B8E6B),
              bold: true),
          _summaryRow(
            'Net Balance',
            received - total,
            received >= total
                ? const Color(0xFF6B8E6B)
                : const Color(0xFFE07A5F),
            bold: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(
                  'Avg/month: ${formatZAR(total / yearData.length)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withAlpha(bold ? 10 : 80),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: bold ? 15 : 14,
              ),
            ),
          ),
          Text(
            formatZAR(amount),
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdownTable(
      List<Map<String, dynamic>> yearData, PropertyProvider prov) {
    if (yearData.isEmpty) return const SizedBox();

    final months = List.generate(12, (i) => i + 1);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Monthly Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '$_selectedYear${_showAllProperties ? ' (All)' : ''}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surface),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                return Colors.transparent;
              }),
              headingTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: const TextStyle(fontSize: 12),
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Month')),
                DataColumn(label: Text('Water'), numeric: true),
                DataColumn(label: Text('Elec.'), numeric: true),
                DataColumn(label: Text('Interest'), numeric: true),
                DataColumn(label: Text('Rates'), numeric: true),
                DataColumn(label: Text('Running'), numeric: true),
                DataColumn(label: Text('Total'), numeric: true),
                DataColumn(label: Text('Rcvd'), numeric: true),
              ],
              rows: months.map((m) {
                final data = yearData.cast<Map<String, dynamic>?>().firstWhere(
                      (d) => d!['month'] == m,
                      orElse: () => null,
                    );
                final hasData = data != null;
                final style = TextStyle(
                  color: hasData
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).textTheme.bodySmall?.color
                    ?..withAlpha(5),
                );
                return DataRow(cells: [
                  DataCell(Text(monthName(m), style: style)),
                  DataCell(Text(
                    hasData ? _compact(data['water'] as double) : '—',
                    style: style.copyWith(
                        color: hasData ? const Color(0xFF42A5F5) : null),
                  )),
                  DataCell(Text(
                    hasData ? _compact(data['electricity'] as double) : '—',
                    style: style.copyWith(
                        color: hasData ? const Color(0xFFF5C842) : null),
                  )),
                  DataCell(Text(
                    hasData ? _compact(data['interest'] as double) : '—',
                    style: style.copyWith(
                        color: hasData ? const Color(0xFFEF5350) : null),
                  )),
                  DataCell(Text(
                    hasData ? _compact(data['rates'] as double) : '—',
                    style: style.copyWith(
                        color: hasData ? const Color(0xFFAB47BC) : null),
                  )),
                  DataCell(Text(
                    hasData ? _compact(data['running'] as double) : '—',
                    style: style.copyWith(
                        color: hasData ? const Color(0xFF6B8E6B) : null),
                  )),
                  DataCell(Text(
                    hasData ? _compact(data['total'] as double) : '—',
                    style: style.copyWith(fontWeight: FontWeight.w700),
                  )),
                  DataCell(Text(
                    hasData ? _compact(data['received'] as double) : '—',
                    style: style.copyWith(
                        color: hasData ? const Color(0xFF6B8E6B) : null),
                  )),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRunningCostsByCategory(PropertyProvider prov, int year) {
    // Get costs based on selection
    final costs = _showAllProperties
        ? prov.allRunningCosts.where((c) => c.year == year).toList()
        : prov.runningCosts.where((c) => c.year == year).toList();

    if (costs.isEmpty) return const SizedBox();

    final byCategory = <CostCategory, double>{};
    for (final c in costs) {
      byCategory[c.category] = (byCategory[c.category] ?? 0) + c.amount;
    }
    final total = byCategory.values.fold(0.0, (s, v) => s + v);

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
          Text(
            'Running Costs by Category${_showAllProperties ? ' (All Properties)' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ...byCategory.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(e.key.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        formatZAR(e.value),
                        style: const TextStyle(
                          color: Color(0xFF6B8E6B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF6B8E6B)),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(color: Theme.of(context).dividerColor, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                formatZAR(total),
                style: const TextStyle(
                  color: Color(0xFF6B8E6B),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearOverYearComparison(PropertyProvider prov, List<int> years) {
    final allData = _showAllProperties
        ? prov.allPropertiesMonthlyTotals
        : prov.monthlyTotalsForChart;

    List<Map<String, double>> yearTotals = years.map((y) {
      final yd = allData.where((m) => m['year'] == y).toList();
      return {
        'year': y.toDouble(),
        'total': yd.fold(0.0, (s, m) => s + (m['total'] as double)),
        'water': yd.fold(0.0, (s, m) => s + (m['water'] as double)),
        'electricity': yd.fold(0.0, (s, m) => s + (m['electricity'] as double)),
        'running': yd.fold(0.0, (s, m) => s + (m['running'] as double)),
      };
    }).toList();

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
          Text(
            'Year-over-Year${_showAllProperties ? ' (All Properties)' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surface),
              headingTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: const TextStyle(fontSize: 12),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Year')),
                DataColumn(label: Text('Water'), numeric: true),
                DataColumn(label: Text('Electricity'), numeric: true),
                DataColumn(label: Text('Running'), numeric: true),
                DataColumn(label: Text('Total'), numeric: true),
              ],
              rows: yearTotals.map((y) {
                return DataRow(cells: [
                  DataCell(Text(
                    '${y['year']!.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: y['year']!.toInt() == _selectedYear
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  )),
                  DataCell(Text(
                    formatZAR(y['water']!),
                    style: const TextStyle(color: Color(0xFF42A5F5)),
                  )),
                  DataCell(Text(
                    formatZAR(y['electricity']!),
                    style: const TextStyle(color: Color(0xFFF5C842)),
                  )),
                  DataCell(Text(
                    formatZAR(y['running']!),
                    style: const TextStyle(color: Color(0xFF6B8E6B)),
                  )),
                  DataCell(Text(
                    formatZAR(y['total']!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v == 0) return '—';
    return 'R${v.toStringAsFixed(0)}';
  }

  void _copyCSV(BuildContext context, PropertyProvider prov,
      List<Map<String, dynamic>> yearData) {
    final buf = StringBuffer();
    buf.writeln(
        'Month,Water,Electricity,Interest,Rates,Running,Total,Received');
    for (final m in yearData) {
      buf.writeln(
        '${monthName(m['month'] as int)} $_selectedYear,'
        '${m['water']},'
        '${m['electricity']},'
        '${m['interest']},'
        '${m['rates']},'
        '${m['running']},'
        '${m['total']},'
        '${m['received']}',
      );
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard'),
        backgroundColor: Color(0xFF6B8E6B),
      ),
    );
  }
}
