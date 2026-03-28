import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/property_provider.dart';
import '../widgets/shared_widgets.dart';

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

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartView _view = ChartView.overview;
  int? _touchedIndex;
  int _yearFilter = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        if (prov.selectedProperty == null) {
          return const Scaffold(
            body: EmptyState(
              message: 'No property selected.',
              icon: Icons.bar_chart_outlined,
            ),
          );
        }

        var data = prov.monthlyTotalsForChart;
        final allYears = data.map((m) => m['year'] as int).toSet().toList()
          ..sort();

        if (_yearFilter != 0) {
          data = data.where((m) => m['year'] == _yearFilter).toList();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Charts & Analytics')),
          body: data.isEmpty
              ? const EmptyState(
                  message: 'No data to chart yet.',
                  icon: Icons.bar_chart_outlined,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildYearFilter(allYears),
                      const SizedBox(height: 20),
                      _buildDrillDownSelector(),
                      const SizedBox(height: 20),
                      _buildLineChart(data),
                      const SizedBox(height: 28),
                      _buildBarChart(data),
                      const SizedBox(height: 28),
                      if (_view == ChartView.overview) _buildPieBreakdown(prov),
                      if (_view == ChartView.overview)
                        const SizedBox(height: 28),
                      _buildDataTable(data),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildYearFilter(List<int> years) {
    final options = [0, ...years];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final y = options[i];
          final selected = y == _yearFilter;
          return GestureDetector(
            onTap: () => setState(() => _yearFilter = y),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                y == 0 ? 'All Years' : '$y',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrillDownSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drill Down',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChartView.values.map((v) {
            final selected = v == _view;
            return GestureDetector(
              onTap: () => setState(() => _view = v),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? v.color.withAlpha(30)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? v.color.withAlpha(150)
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  v.label,
                  style: TextStyle(
                    color: selected
                        ? v.color
                        : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    final values = data.map((m) => (m[_view.key] as double)).toList();
    final maxY =
        values.isEmpty ? 1000.0 : values.reduce((a, b) => a > b ? a : b) * 1.2;
    final labelColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final gridColor = Theme.of(context).dividerColor;

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
            '${_view.label} Over Time',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            _yearFilter == 0 ? 'All years' : '$_yearFilter',
            style: TextStyle(color: labelColor, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY > 0 ? maxY : 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: gridColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (v, _) => Text(
                        _compactZAR(v),
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: data.length > 12
                          ? (data.length / 6).ceilToDouble()
                          : 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox();
                        }
                        final m = data[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthName(m['month'] as int),
                            style: TextStyle(color: labelColor, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (i) => FlSpot(i.toDouble(), data[i][_view.key] as double),
                    ),
                    isCurved: true,
                    color: _view.color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: data.length <= 24,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: _view.color,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _view.color.withAlpha(50),
                          _view.color.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final displayData =
        data.length > 18 ? data.sublist(data.length - 18) : data;
    final maxY = displayData.isEmpty
        ? 1000.0
        : displayData
                .map((m) => m[_view.key] as double)
                .reduce((a, b) => a > b ? a : b) *
            1.2;
    final labelColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final gridColor = Theme.of(context).dividerColor;

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
          const Text(
            'Monthly Bar Chart',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Last ${displayData.length} months',
            style: TextStyle(color: labelColor, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null) {
                        _touchedIndex = response!.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedIndex = null;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final m = displayData[group.x];
                      return BarTooltipItem(
                        '${monthName(m['month'] as int)} ${m['year']}\n${formatZAR(rod.toY)}',
                        TextStyle(
                          color: _view.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: gridColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (v, _) => Text(
                        _compactZAR(v),
                        style: TextStyle(color: labelColor, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= displayData.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthName(displayData[idx]['month'] as int),
                            style: TextStyle(color: labelColor, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(
                  displayData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: displayData[i][_view.key] as double,
                        color: _touchedIndex == i
                            ? _view.color
                            : _view.color.withAlpha(150),
                        width: displayData.length > 12 ? 8 : 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieBreakdown(PropertyProvider prov) {
    final totals = prov.allTimeTotals;
    final categories = [
      ('Water', totals['water']!, const Color(0xFF42A5F5)),
      ('Electricity', totals['electricity']!, const Color(0xFFF5C842)),
      ('Interest', totals['interest']!, const Color(0xFFEF5350)),
      ('Rates', totals['rates']!, const Color(0xFFAB47BC)),
      ('Running', totals['running']!, const Color(0xFF4CAF7D)),
    ];
    final total = categories.fold(0.0, (s, c) => s + c.$2);
    if (total == 0) return const SizedBox();

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
          const Text(
            'Cost Breakdown',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: categories
                        .where((c) => c.$2 > 0)
                        .map(
                          (c) => PieChartSectionData(
                            value: c.$2,
                            color: c.$3,
                            radius: 50,
                            showTitle: false,
                          ),
                        )
                        .toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: categories
                      .where((c) => c.$2 > 0)
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c.$3,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.$1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ),
                              Text(
                                '${(c.$2 / total * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.$3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> data) {
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
            child: Text(
              'Data Table — ${_view.label}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surface),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              headingTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: const TextStyle(fontSize: 13),
              columns: const [
                DataColumn(label: Text('Month')),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('Received'), numeric: true),
              ],
              rows: data.reversed
                  .take(24)
                  .map(
                    (m) => DataRow(cells: [
                      DataCell(Text(
                        monthYear(m['year'] as int, m['month'] as int),
                      )),
                      DataCell(Text(
                        formatZAR(m[_view.key] as double),
                        style: TextStyle(color: _view.color),
                      )),
                      DataCell(Text(
                        formatZAR(m['received'] as double),
                        style: const TextStyle(color: Color(0xFF4CAF7D)),
                      )),
                    ]),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _compactZAR(double v) {
    if (v >= 1000000) return 'R${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'R${(v / 1000).toStringAsFixed(0)}k';
    return 'R${v.toStringAsFixed(0)}';
  }
}
