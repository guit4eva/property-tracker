import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/property_provider.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart' as widgets;

class RentalIncomeScreen extends StatelessWidget {
  const RentalIncomeScreen({super.key});

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

        // Get all expenses with rental income
        final incomeEntries =
            prov.expenses.where((e) => e.paymentReceived > 0).toList()
              ..sort((a, b) {
                final yearCmp = b.year.compareTo(a.year);
                return yearCmp != 0 ? yearCmp : b.month.compareTo(a.month);
              });

        final totalIncome = prov.expenses.fold<double>(
          0,
          (sum, e) => sum + e.paymentReceived,
        );

        // Group by year
        final Map<int, List<MonthlyExpense>> byYear = {};
        for (final entry in incomeEntries) {
          byYear.putIfAbsent(entry.year, () => []).add(entry);
        }
        final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

        // Check if there are entries with 0 payment that could be synced
        final syncableEntries = prov.expenses.where((e) {
          if (e.paymentReceived > 0) return false;
          final rentAmount = prov.getRentForMonth(e.year, e.month);
          return rentAmount != null && rentAmount > 0;
        }).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rental Income'),
            actions: [
              if (syncableEntries > 0)
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.sync),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$syncableEntries',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  tooltip: 'Sync rental income from rent periods',
                  onPressed: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sync Rental Income'),
                        content: Text(
                          'This will update $syncableEntries ${syncableEntries == 1 ? 'entry' : 'entries'} with rental income from your active rent periods. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, 0),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, 1),
                            child: const Text('Sync'),
                          ),
                        ],
                      ),
                    );

                    if (result == 1) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Syncing rental income...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      final updated =
                          await prov.syncPaymentReceivedFromRentPeriods();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ Updated $updated ${updated == 1 ? 'entry' : 'entries'} with rental income',
                            ),
                            backgroundColor: const Color(0xFF6B8E6B),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          body: incomeEntries.isEmpty
              ? Column(
                  children: [
                    if (syncableEntries > 0)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B8E6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF6B8E6B).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: const Color(0xFF6B8E6B)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have $syncableEntries ${syncableEntries == 1 ? 'entry' : 'entries'} that can be synced with active rent periods.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(0xFF6B8E6B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final updated = await prov
                                      .syncPaymentReceivedFromRentPeriods();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '✓ Updated $updated ${updated == 1 ? 'entry' : 'entries'} with rental income',
                                        ),
                                        backgroundColor:
                                            const Color(0xFF6B8E6B),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sync),
                                label: Text(
                                    'Sync $syncableEntries ${syncableEntries == 1 ? 'Entry' : 'Entries'}'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B8E6B),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Expanded(
                      child: widgets.EmptyState(
                        message: 'No rental income recorded yet.',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Total card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF66BB6A).withValues(alpha: 0.15),
                            const Color(0xFF66BB6A).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF66BB6A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Rental Income',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widgets.formatZAR(totalIncome),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF66BB6A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${incomeEntries.length} month${incomeEntries.length != 1 ? 's' : ''} with income across ${years.length} ${years.length == 1 ? 'year' : 'years'}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Year-grouped tables
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: years.length,
                        itemBuilder: (ctx, yearIdx) {
                          final year = years[yearIdx];
                          final yearEntries = byYear[year]!;
                          final yearTotal = yearEntries.fold<double>(
                              0, (sum, e) => sum + e.paymentReceived);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Year header
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 12, bottom: 8, left: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$year',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      widgets.formatZAR(yearTotal),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF66BB6A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Table
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Table header
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withValues(alpha: 0.5),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Month',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Amount',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 1),
                                    // Table rows
                                    ...yearEntries
                                        .map((entry) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      widgets.monthYear(
                                                          entry.year,
                                                          entry.month),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      widgets.formatZAR(entry
                                                          .paymentReceived),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF66BB6A),
                                                      ),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
