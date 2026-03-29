import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'providers/property_provider.dart';
import 'models/models.dart';
import 'widgets/shared_widgets.dart';

enum ChartView { overview, water, electricity, interest, rates, running }

extension ChartViewExt on ChartView {
  String get label {
    switch (this) {
      case ChartView.overview:
        return 'Overview';
      case ChartView.water:
        return 'Water';
      case ChartView.electricity:
        return 'Electricity';
      case ChartView.interest:
        return 'Interest';
      case ChartView.rates:
        return 'Rates';
      case ChartView.running:
        return 'Running Costs';
    }
  }

  Color get color {
    switch (this) {
      case ChartView.overview:
        return const Color(0xFF6B8E6B);
      case ChartView.water:
        return const Color(0xFF42A5F5);
      case ChartView.electricity:
        return const Color(0xFFF5C842);
      case ChartView.interest:
        return const Color(0xFFEF5350);
      case ChartView.rates:
        return const Color(0xFFAB47BC);
      case ChartView.running:
        return const Color(0xFF4CAF7D);
    }
  }

  String get key {
    switch (this) {
      case ChartView.overview:
        return 'total';
      case ChartView.water:
        return 'water';
      case ChartView.electricity:
        return 'electricity';
      case ChartView.interest:
        return 'interest';
      case ChartView.rates:
        return 'rates';
      case ChartView.running:
        return 'running';
    }
  }
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  ChartView _view = ChartView.overview;
  int _yearFilter = 0; // 0 = all
  int _selectedYear = DateTime.now().year;
  bool _showAllProperties = false;
  String _selectedTab = 'charts'; // 'charts' or 'summary'

  String formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        if (prov.selectedProperty == null && !_showAllProperties) {
          return const Scaffold(
            body: Center(
              child: EmptyState(
                message: 'No property selected.\nGo to Properties tab.',
                icon: Icons.home_work_outlined,
              ),
            ),
          );
        }

        final hasMultipleProperties = prov.properties.length > 1;
        final allData = _showAllProperties && hasMultipleProperties
            ? prov.allPropertiesMonthlyTotals
            : prov.monthlyTotalsForChart;

        final years = allData.map((m) => m['year'] as int).toSet().toList()
          ..sort();

        if (years.isNotEmpty && !years.contains(_selectedYear)) {
          _selectedYear = years.last;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_showAllProperties && hasMultipleProperties
                ? 'All Properties Overview'
                : 'Overview'),
            actions: [
              if (_selectedTab == 'summary')
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy CSV',
                  onPressed: () => _copyCSV(context, prov),
                ),
            ],
          ),
          body: Column(
            children: [
              // Tab toggle
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 'charts'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 'charts'
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 18,
                                color: _selectedTab == 'charts'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Charts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _selectedTab == 'charts'
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 'summary'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 'summary'
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_chart,
                                size: 18,
                                color: _selectedTab == 'summary'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _selectedTab == 'summary'
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedTab == 'charts'
                    ? _buildChartsView(
                        prov, allData, years, hasMultipleProperties)
                    : _buildSummaryView(
                        prov, allData, years, hasMultipleProperties),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsView(
      PropertyProvider prov,
      List<Map<String, dynamic>> allData,
      List<int> years,
      bool hasMultipleProperties) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMultipleProperties) ...[
            _buildPropertyScopeToggle(prov),
            const SizedBox(height: 16),
          ],
          _buildChartTypeSelector(),
          const SizedBox(height: 20),
          _buildYearFilter(years),
          const SizedBox(height: 20),
          _buildChart(prov, allData),
          const SizedBox(height: 24),
          _buildLegend(prov),
        ],
      ),
    );
  }

  Widget _buildSummaryView(
      PropertyProvider prov,
      List<Map<String, dynamic>> allData,
      List<int> years,
      bool hasMultipleProperties) {
    final yearData = _selectedYear == 0
        ? allData // All time
        : allData.where((m) => m['year'] == _selectedYear).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          if (hasMultipleProperties) ...[
            _buildPropertyScopeToggle(prov),
            const SizedBox(height: 16),
          ],
          _buildYearSelector(years),
          const SizedBox(height: 16),
          _buildYearTotalsCard(yearData),
          const SizedBox(height: 16),
          _buildAnnualRatesOverview(prov),
          const SizedBox(height: 16),
          _buildMonthlyBreakdownTable(yearData, prov),
          const SizedBox(height: 16),
          _buildRunningCostsByCategory(prov, _selectedYear),
          if (years.length > 1) ...[
            const SizedBox(height: 16),
            _buildYearOverYearComparison(prov, years),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyScopeToggle(PropertyProvider prov) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showAllProperties = false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showAllProperties
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      size: 16,
                      color: !_showAllProperties
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'This Property',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_showAllProperties
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showAllProperties = true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showAllProperties
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 16,
                      color: _showAllProperties
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All Properties',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _showAllProperties
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ChartView.values.map((v) {
        final selected = _view == v;
        return FilterChip(
          label: Text(v.label),
          selected: selected,
          onSelected: (s) => setState(() => _view = v),
          selectedColor: v.color.withValues(alpha: 0.2),
          checkmarkColor: v.color,
          labelStyle: TextStyle(
            color: selected
                ? v.color
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearFilter(List<int> years) {
    if (years.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Text('Year:',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _yearFilter == 0,
                  onSelected: (s) => setState(() => _yearFilter = 0),
                ),
                const SizedBox(width: 4),
                ...years.map((y) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FilterChip(
                        label: Text(y.toString()),
                        selected: _yearFilter == y,
                        onSelected: (s) => setState(() => _yearFilter = y),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
      PropertyProvider prov, List<Map<String, dynamic>> allData) {
    var data = allData;
    if (_yearFilter != 0) {
      data = data.where((m) => m['year'] == _yearFilter).toList();
    }

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No data available for the selected period.'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: _buildLineChart(data),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    final key = _view.key;

    // Sort data by year and month
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) {
        final yearCmp = (a['year'] as int).compareTo(b['year'] as int);
        if (yearCmp != 0) return yearCmp;
        return (a['month'] as int).compareTo(b['month'] as int);
      });

    final spots = <FlSpot>[];
    for (var i = 0; i < sortedData.length; i++) {
      final item = sortedData[i];
      final value = (item[key] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY > 0 ? maxY / 5 : 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(0)}k'
                        : value.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length > 6 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedData.length)
                  return const Text('');
                final item = sortedData[index];
                final month =
                    monthYear(item['year'] as int, item['month'] as int);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Text(
                      month.length > 10 ? month.substring(0, 9) : month,
                      style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _view.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _view.color,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _view.color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(PropertyProvider prov) {
    var data = prov.monthlyTotalsForChart;
    if (_yearFilter != 0) {
      data = data.where((m) => m['year'] == _yearFilter).toList();
    }

    final key = _view.key;
    final total =
        data.fold<double>(0, (sum, m) => sum + (m[key] as num).toDouble());

    // Calculate min, max, and average
    final values = data.map((m) => (m[key] as num).toDouble()).toList();
    final minValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final avgValue = values.isEmpty ? 0.0 : total / values.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${formatZAR(total)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                'Avg: ${formatZAR(avgValue)}/mo',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Min: ${formatZAR(minValue)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(width: 16),
              Text('Max: ${formatZAR(maxValue)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ],
      ),
    );
  }

  // Summary view widgets
  Widget _buildYearSelector(List<int> years) {
    if (years.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: years.contains(_selectedYear) ? _selectedYear : null,
          isExpanded: true,
          hint: const Text('All Time', style: TextStyle(fontSize: 16)),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...years.map((y) => DropdownMenuItem(
                  value: y,
                  child:
                      Text(y.toString(), style: const TextStyle(fontSize: 16)),
                )),
          ],
          onChanged: (v) => setState(() => _selectedYear = v ?? 0),
        ),
      ),
    );
  }

  Widget _buildYearTotalsCard(List<Map<String, dynamic>> yearData) {
    double totalWater = 0,
        totalElec = 0,
        totalInterest = 0,
        totalRates = 0,
        totalRunning = 0;
    for (final m in yearData) {
      totalWater += m['water'] as double;
      totalElec += m['electricity'] as double;
      totalInterest += m['interest'] as double;
      totalRates += m['rates'] as double;
      totalRunning += m['running'] as double;
    }

    final title = _selectedYear == 0
        ? 'All-Time Total Expenses'
        : '$_selectedYear Total Expenses';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatZAR(totalWater +
                totalElec +
                totalInterest +
                totalRates +
                totalRunning),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _miniStat('Water', totalWater, const Color(0xFF42A5F5)),
              _miniStat('Electricity', totalElec, const Color(0xFFF5C842)),
              _miniStat('Interest', totalInterest, const Color(0xFFEF5350)),
              _miniStat('Rates', totalRates, const Color(0xFFAB47BC)),
              _miniStat('Running', totalRunning, const Color(0xFF4CAF7D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(formatZAR(amount),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdownTable(
      List<Map<String, dynamic>> yearData, PropertyProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Monthly Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.5),
              6: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
                ),
                children: [
                  'Month',
                  'Water',
                  'Elec',
                  'Interest',
                  'Rates',
                  'Running',
                  'Total'
                ]
                    .map((h) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(h,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              )),
                        ))
                    .toList(),
              ),
              ...yearData.map((m) {
                final total = (m['total'] as num).toDouble();
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Theme.of(context).dividerColor, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                          monthYear(m['year'] as int, m['month'] as int),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    _tableCell(m['water'] as double),
                    _tableCell(m['electricity'] as double),
                    _tableCell(m['interest'] as double),
                    _tableCell(m['rates'] as double),
                    _tableCell(m['running'] as double),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(formatZAR(total),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCell(double value) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(value > 0 ? formatZAR(value) : '-',
          style: TextStyle(
            fontSize: 12,
            color: value > 0
                ? Theme.of(context).textTheme.bodyMedium?.color
                : Theme.of(context).dividerColor,
          )),
    );
  }

  Widget _buildAnnualRatesOverview(PropertyProvider prov) {
    // Get all expenses with annual rates for the selected year
    final allExpenses = prov.expenses;
    final yearFilter = _selectedYear == 0 ? null : _selectedYear;

    final annualRatesExpenses = allExpenses
        .where((e) => e.ratesFrequency == RatesFrequency.annually)
        .where((e) => yearFilter == null || e.year == yearFilter)
        .toList();

    if (annualRatesExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by year
    final byYear = <int, List<MonthlyExpense>>{};
    for (final e in annualRatesExpenses) {
      if (!byYear.containsKey(e.year)) {
        byYear[e.year] = [];
      }
      byYear[e.year]!.add(e);
    }

    final years = byYear.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Annual Rates Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...years.map((year) {
            final expenses = byYear[year]!;
            // Get unique annual amounts (should all be the same)
            final annualAmounts =
                expenses.map((e) => e.ratesTaxes).toSet().toList();
            final annualAmount =
                annualAmounts.isNotEmpty ? annualAmounts.first : 0.0;
            final monthlyEquivalent = annualAmount / 12;
            final monthsConfigured = expenses.length;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$year',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formatZAR(annualAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${monthsConfigured}/12 months',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatZAR(monthlyEquivalent)}/mo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRunningCostsByCategory(PropertyProvider prov, int year) {
    final costs = year == 0
        ? prov.filteredRunningCosts // All time
        : prov.filteredRunningCosts.where((c) => c.year == year).toList();
    if (costs.isEmpty) return const SizedBox.shrink();

    final byCategory = <CostCategory, double>{};
    for (final cost in costs) {
      byCategory[cost.category] =
          (byCategory[cost.category] ?? 0) + cost.amount;
    }

    final title = year == 0
        ? 'Running Costs by Category (All Time)'
        : 'Running Costs by Category ($year)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...byCategory.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: e.key.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    Text(formatZAR(e.value),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildYearOverYearComparison(PropertyProvider prov, List<int> years) {
    final yearTotals = <int, double>{};
    for (final year in years) {
      final data =
          prov.monthlyTotalsForChart.where((m) => m['year'] == year).toList();
      yearTotals[year] = data.fold<double>(
          0, (sum, m) => sum + (m['total'] as num).toDouble());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Year-over-Year Comparison',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...yearTotals.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${e.key}', style: const TextStyle(fontSize: 13)),
                    Text(formatZAR(e.value),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _copyCSV(BuildContext context, PropertyProvider prov) {
    final allData = _showAllProperties && prov.properties.length > 1
        ? prov.allPropertiesMonthlyTotals
        : prov.monthlyTotalsForChart;
    final yearData = allData.where((m) => m['year'] == _selectedYear).toList();

    final buffer = StringBuffer();
    buffer.writeln('Month,Water,Electricity,Interest,Rates,Running,Total');
    for (final m in yearData) {
      buffer.writeln(
          '${monthYear(m['year'] as int, m['month'] as int)},${m['water']},${m['electricity']},${m['interest']},${m['rates']},${m['running']},${m['total']}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard'),
        backgroundColor: Color(0xFF6B8E6B),
      ),
    );
  }
}
