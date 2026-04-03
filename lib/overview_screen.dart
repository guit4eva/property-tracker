import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'providers/property_provider.dart';
import 'models/models.dart';
import 'widgets/shared_widgets.dart';
import 'widgets/year_selector.dart';

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
  final ChartView? initialView;

  const OverviewScreen({super.key, this.initialView});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  ChartView _view = ChartView.overview;
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month);
  bool _showAllProperties = false;
  String _selectedTab = 'summary'; // 'charts' or 'summary'
  late PageController _yearPageController;
  late PageController _summaryPageController;

  int get _selectedYear => _selectedDate.year;

  void _setSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialView != null) {
      _view = widget.initialView!;
    }
    _yearPageController = PageController(initialPage: 0);
    _summaryPageController = PageController();
  }

  @override
  void dispose() {
    _yearPageController.dispose();
    _summaryPageController.dispose();
    super.dispose();
  }

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

        // Only auto-select year if _selectedYear is not set (0) and not in list
        // Allow 0 (All Time) to remain selected
        if (years.isNotEmpty &&
            _selectedYear != 0 &&
            !years.contains(_selectedYear)) {
          _selectedDate = DateTime(years.last, DateTime.now().month);
        }

        return Scaffold(
          body: Column(
            children: [
              // Year selector (exactly like monthly screen but for years only)
              YearSelector(
                selectedYear: _selectedYear,
                years: [0, ...years], // Include "All Time" option
                onYearChanged: (year) {
                  setState(() {
                    _selectedDate = DateTime(year, _selectedDate.month);
                  });
                  // Sync PageView to the selected year
                  final displayYears = [0, ...years];
                  final index = displayYears.indexOf(year);
                  if (index >= 0 && _summaryPageController.hasClients) {
                    _summaryPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              // Tab toggle
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 'summary';
                          });
                        },
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
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 'charts';
                          });
                        },
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
                                'Graphs',
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
    // Get years from monthly data AND running costs
    final yearsFromData = allData.map((m) => m['year'] as int).toSet();
    final yearsFromRunningCosts = prov.runningCosts.map((c) => c.year).toSet();
    final allYears = {...yearsFromData, ...yearsFromRunningCosts}.toList()
      ..sort();

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                final currentIndex = allYears.indexOf(_selectedYear);
                if (details.primaryVelocity! > 0 && currentIndex > 0) {
                  // Swipe right = previous year
                  setState(() {
                    _selectedDate = DateTime(
                        allYears[currentIndex - 1], _selectedDate.month);
                  });
                } else if (details.primaryVelocity! < 0 &&
                    currentIndex < allYears.length - 1) {
                  // Swipe left = next year
                  setState(() {
                    _selectedDate = DateTime(
                        allYears[currentIndex + 1], _selectedDate.month);
                  });
                }
              }
            },
            child: SingleChildScrollView(
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
                  _buildChart(prov, allData),
                  const SizedBox(height: 24),
                  _buildLegend(prov),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView(
      PropertyProvider prov,
      List<Map<String, dynamic>> allData,
      List<int> years,
      bool hasMultipleProperties) {
    // Get years from monthly data AND running costs
    final yearsFromData = allData.map((m) => m['year'] as int).toSet();
    final yearsFromRunningCosts = prov.runningCosts.map((c) => c.year).toSet();
    final allYears = {...yearsFromData, ...yearsFromRunningCosts}.toList()
      ..sort();

    // Add "All Time" as year 0 at the beginning
    final displayYears = [0, ...allYears];

    return PageView.builder(
      controller: _summaryPageController,
      itemCount: displayYears.length,
      onPageChanged: (index) {
        setState(() {
          _selectedDate = DateTime(displayYears[index], _selectedDate.month);
        });
      },
      itemBuilder: (ctx, index) {
        final year = displayYears[index];
        final yearData = year == 0
            ? allData
            : allData.where((m) => m['year'] == year).toList();

        return SingleChildScrollView(
          key: PageStorageKey('summary_year_$year'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasMultipleProperties) ...[
                _buildPropertyScopeToggle(prov),
                const SizedBox(height: 16),
              ],
              _buildYearTotalsCard(yearData),
              const SizedBox(height: 16),
              _buildAnnualRatesOverview(prov),
              const SizedBox(height: 16),
              _buildMonthlyBreakdownTable(yearData, prov),
              const SizedBox(height: 16),
              _buildRunningCostsByCategory(prov, year),
              if (allYears.length > 1) ...[
                const SizedBox(height: 16),
                _buildYearOverYearComparison(prov, allYears),
              ],
            ],
          ),
        );
      },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ChartView>(
                value: _view,
                isExpanded: true,
                items: ChartView.values.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: v.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(v.label, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _view = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
      PropertyProvider prov, List<Map<String, dynamic>> allData) {
    var data = allData;
    if (_selectedYear != 0) {
      data = data.where((m) => m['year'] == _selectedYear).toList();
    }

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No data available for the selected period.'),
        ),
      );
    }

    // Get unique years for navigation
    final years = allData.map((m) => m['year'] as int).toSet().toList()..sort();
    final displayYears = [0, ...years]; // 0 = All time
    displayYears.indexOf(_selectedYear);

    return Column(
      children: [
        // Chart with swipe navigation
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _yearPageController,
            itemCount: displayYears.length,
            onPageChanged: (index) {
              setState(() {
                _selectedDate =
                    DateTime(displayYears[index], _selectedDate.month);
              });
            },
            itemBuilder: (ctx, index) {
              final year = displayYears[index];
              var yearData = allData;
              if (year != 0) {
                yearData = allData.where((m) => m['year'] == year).toList();
              }

              if (yearData.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No data for this period.'),
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
                  child: _buildLineChart(yearData),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    final key = _view.key;
    final dataPoints = data.length;
    final isDense = dataPoints > 24; // More than 2 years of monthly data

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
    final minY = 0.0; // Always start from 0
    final padding = maxY * 0.15;

    // Calculate intervals based on data density
    final bottomInterval = isDense
        ? (dataPoints / 8).ceil().toDouble() // Show ~8 labels
        : 1.0;
    final leftInterval = maxY > 0 ? maxY / 4 : 1.0;
    final showDots = dataPoints <= 36; // Show dots for 3 years or less

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: leftInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedData.length) {
                  return const Text('');
                }
                final item = sortedData[index];
                final year = item['year'] as int;
                final month = item['month'] as int;

                // For dense data, show year only at year boundaries
                if (isDense) {
                  if (month != 1) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$year',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  );
                } else {
                  // For sparse data, show short month name
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      monthName(month),
                      style: const TextStyle(fontSize: 8),
                    ),
                  );
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0, // Force Y-axis to start at 0
        maxY: maxY + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _view.color,
            barWidth: isDense ? 2 : 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: _view.color,
                  strokeWidth: 1.5,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _view.color.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final item = sortedData[spot.x.toInt()];
                final month =
                    monthYear(item['year'] as int, item['month'] as int);
                final value = (item[key] as num).toDouble();
                return LineTooltipItem(
                  '$month\n${formatZAR(value)}',
                  const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildLegend(PropertyProvider prov) {
    var data = prov.monthlyTotalsForChart;
    if (_selectedYear != 0) {
      data = data.where((m) => m['year'] == _selectedYear).toList();
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

  Widget _buildYearTotalsCard(List<Map<String, dynamic>> yearData) {
    // Get running costs for the selected year
    final prov = Provider.of<PropertyProvider>(context, listen: false);
    final now = DateTime.now();

    // Calculate running costs that are active for the selected year
    double yearRunningCosts = 0;
    if (_selectedYear == 0) {
      // All time: calculate actual occurrences across all years for each cost
      for (final cost in prov.runningCosts) {
        final costStart = cost.startDate;
        final costEnd = cost.endDate ?? now;

        // Calculate total occurrences from start to end
        int occurrences = 0;
        switch (cost.frequency) {
          case CostFrequency.monthly:
            occurrences = (costEnd.year - costStart.year) * 12 +
                (costEnd.month - costStart.month) +
                1;
            break;
          case CostFrequency.weekly:
            if (cost.dayOfWeek != null) {
              int startDayOfWeek = costStart.weekday;
              int targetDay = cost.dayOfWeek!;
              int daysUntilTarget = (targetDay - startDayOfWeek + 7) % 7;
              DateTime firstOccurrence =
                  costStart.add(Duration(days: daysUntilTarget));
              if (!firstOccurrence.isAfter(costEnd)) {
                int totalDays = costEnd.difference(firstOccurrence).inDays;
                occurrences = (totalDays ~/ 7) + 1;
              }
            } else {
              final days = costEnd.difference(costStart).inDays;
              occurrences = (days ~/ 7) + 1;
            }
            break;
          case CostFrequency.yearly:
            occurrences = costEnd.year - costStart.year + 1;
            break;
          case CostFrequency.everyXWeeks:
            if (cost.dayOfWeek != null) {
              int startDayOfWeek = costStart.weekday;
              int targetDay = cost.dayOfWeek!;
              int daysUntilTarget = (targetDay - startDayOfWeek + 7) % 7;
              DateTime firstOccurrence =
                  costStart.add(Duration(days: daysUntilTarget));
              if (!firstOccurrence.isAfter(costEnd)) {
                int totalDays = costEnd.difference(firstOccurrence).inDays;
                int intervalDays = 7 * (cost.interval ?? 1);
                occurrences = (totalDays ~/ intervalDays) + 1;
              }
            } else {
              final days = costEnd.difference(costStart).inDays;
              occurrences = (days ~/ (7 * (cost.interval ?? 1))) + 1;
            }
            break;
          case CostFrequency.everyXMonths:
            final months = (costEnd.year - costStart.year) * 12 +
                (costEnd.month - costStart.month);
            occurrences = (months ~/ (cost.interval ?? 1)) + 1;
            break;
          default:
            occurrences = 1;
        }

        if (occurrences > 0) {
          yearRunningCosts += cost.amount * occurrences;
        }
      }
    } else {
      // For selected year: calculate actual occurrences based on frequency
      for (final cost in prov.runningCosts) {
        final costStart = cost.startDate;
        final costEnd = cost.endDate;

        // Check if this cost is active during the selected year
        final yearStart = DateTime(_selectedYear, 1, 1);
        final yearEnd = DateTime(_selectedYear, 12, 31);

        // Skip if cost doesn't overlap with selected year
        if (costEnd != null && costEnd.isBefore(yearStart)) continue;
        if (costStart.isAfter(yearEnd)) continue;

        // Calculate actual occurrences in the year
        // For ongoing costs, cap at current date for "to date" accuracy
        final actualEnd = costEnd ?? now;
        final effectiveStart =
            costStart.isAfter(yearStart) ? costStart : yearStart;
        final effectiveEnd = actualEnd.isBefore(yearEnd) ? actualEnd : yearEnd;

        // Skip if effective period is invalid
        if (effectiveEnd.isBefore(effectiveStart)) continue;

        int occurrences = 0;
        switch (cost.frequency) {
          case CostFrequency.monthly:
            // Count months between effective start and end
            occurrences = (effectiveEnd.year - effectiveStart.year) * 12 +
                (effectiveEnd.month - effectiveStart.month) +
                1;
            break;
          case CostFrequency.weekly:
            // Count specific day of week occurrences
            if (cost.dayOfWeek != null) {
              // Find first occurrence of the day on or after effectiveStart
              int startDayOfWeek = effectiveStart.weekday; // 1=Monday, 7=Sunday
              int targetDay = cost.dayOfWeek!;
              int daysUntilTarget = (targetDay - startDayOfWeek + 7) % 7;
              DateTime firstOccurrence =
                  effectiveStart.add(Duration(days: daysUntilTarget));

              if (!firstOccurrence.isAfter(effectiveEnd)) {
                int totalDays = effectiveEnd.difference(firstOccurrence).inDays;
                occurrences = (totalDays ~/ 7) + 1;
              }
            } else {
              // Fallback: count every 7 days from start
              final days = effectiveEnd.difference(effectiveStart).inDays;
              occurrences = (days ~/ 7) + 1;
            }
            break;
          case CostFrequency.yearly:
            occurrences = 1;
            break;
          case CostFrequency.everyXWeeks:
            // Count specific day of week occurrences with interval
            if (cost.dayOfWeek != null) {
              int startDayOfWeek = effectiveStart.weekday;
              int targetDay = cost.dayOfWeek!;
              int daysUntilTarget = (targetDay - startDayOfWeek + 7) % 7;
              DateTime firstOccurrence =
                  effectiveStart.add(Duration(days: daysUntilTarget));

              if (!firstOccurrence.isAfter(effectiveEnd)) {
                int totalDays = effectiveEnd.difference(firstOccurrence).inDays;
                int intervalDays = 7 * (cost.interval ?? 1);
                occurrences = (totalDays ~/ intervalDays) + 1;
              }
            } else {
              final days = effectiveEnd.difference(effectiveStart).inDays;
              occurrences = (days ~/ (7 * (cost.interval ?? 1))) + 1;
            }
            break;
          case CostFrequency.everyXMonths:
            final months = (effectiveEnd.year - effectiveStart.year) * 12 +
                (effectiveEnd.month - effectiveStart.month);
            occurrences = (months ~/ (cost.interval ?? 1)) + 1;
            break;
          default:
            occurrences = 1;
        }

        if (occurrences > 0) {
          yearRunningCosts += cost.amount * occurrences;
        }
      }
    }

    // Calculate rental income for the selected year
    double yearRentalIncome = 0;

    // First, try to get from monthly expenses (actual recorded payments)
    yearRentalIncome = yearData.fold<double>(
      0,
      (sum, m) => sum + (m['paymentReceived'] as double? ?? 0),
    );

    // If no monthly expense data, calculate from rent periods
    if (yearRentalIncome == 0 && prov.rentPeriods.isNotEmpty) {
      if (_selectedYear == 0) {
        // All time: sum actual months for each rent period
        for (final period in prov.rentPeriods) {
          // For ongoing rents, count months from start to current month
          // For ended rents, count actual duration
          final end = period.endDate ?? DateTime(now.year, now.month);
          final start = period.startDate;

          // Calculate months between start and end
          int months =
              (end.year - start.year) * 12 + (end.month - start.month) + 1;
          if (months < 0) months = 0;

          yearRentalIncome += period.rentalAmount * months;
        }
      } else {
        // For selected year: calculate how many months rent was active in that year
        for (final period in prov.rentPeriods) {
          final periodStart = period.startDate;
          // For ongoing rents, only count up to current month of selected year
          final periodEnd = period.endDate ??
              (now.year == _selectedYear
                  ? DateTime(now.year, now.month)
                  : DateTime(_selectedYear, 12, 31));

          // Calculate overlap with selected year
          final yearStart = DateTime(_selectedYear, 1, 1);
          final yearEnd = DateTime(_selectedYear, 12, 31);

          // Find the overlap period
          final overlapStart =
              periodStart.isAfter(yearStart) ? periodStart : yearStart;
          final overlapEnd = periodEnd.isBefore(yearEnd) ? periodEnd : yearEnd;

          if (overlapStart.isBefore(overlapEnd) ||
              overlapStart.year == overlapEnd.year &&
                  overlapStart.month == overlapEnd.month) {
            // Calculate months in overlap
            int months = (overlapEnd.year - overlapStart.year) * 12 +
                (overlapEnd.month - overlapStart.month) +
                1;
            if (months < 0) months = 0;

            yearRentalIncome += period.rentalAmount * months;
          }
        }
      }
    }

    double totalWater = 0,
        totalElec = 0,
        totalInterest = 0,
        totalRates = 0,
        totalRunning = 0,
        totalIncome = yearRentalIncome;
    for (final m in yearData) {
      totalWater += m['water'] as double;
      totalElec += m['electricity'] as double;
      totalInterest += m['interest'] as double;
      totalRates += m['rates'] as double;
    }

    totalRunning = yearRunningCosts;

    final totalExpenses =
        totalWater + totalElec + totalInterest + totalRates + totalRunning;
    final deficit = totalExpenses - totalIncome;

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
            formatZAR(totalExpenses),
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
              _miniStat('💧 Water', totalWater, const Color(0xFF42A5F5)),
              _miniStat('⚡ Electricity', totalElec, const Color(0xFFF5C842)),
              _miniStat('📈 Interest', totalInterest, const Color(0xFFEF5350)),
              _miniStat('🏛 Rates', totalRates, const Color(0xFFAB47BC)),
              _miniStat('🔧 Running', totalRunning, const Color(0xFF4CAF7D)),
              _miniStat('💰 Income', totalIncome, const Color(0xFF6B8E6B)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deficit > 0
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFF6B8E6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      deficit > 0 ? 'Total Deficit' : 'Total Surplus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            deficit > 0 ? Colors.red : const Color(0xFF6B8E6B),
                      ),
                    ),
                    Text(
                      formatZAR(deficit.abs()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            deficit > 0 ? Colors.red : const Color(0xFF6B8E6B),
                      ),
                    ),
                  ],
                ),
                if (_selectedYear != 0) ...[
                  const SizedBox(height: 8),
                  Divider(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly avg:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        formatZAR(totalExpenses / 12),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: IntrinsicColumnWidth(),
                3: IntrinsicColumnWidth(),
                4: IntrinsicColumnWidth(),
                5: IntrinsicColumnWidth(),
                6: IntrinsicColumnWidth(),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(formatZAR(total),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  );
                }),
              ],
            ),
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
                          '$monthsConfigured/12 months',
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
          (byCategory[cost.category] ?? 0) + cost.monthlyEquivalent;
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
}
