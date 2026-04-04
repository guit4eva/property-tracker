import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/property_provider.dart';
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

        return Scaffold(
          appBar: AppBar(title: const Text('Rental Income')),
          body: incomeEntries.isEmpty
              ? const widgets.EmptyState(
                  message: 'No rental income recorded yet.',
                  icon: Icons.payments_outlined,
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
                            '${incomeEntries.length} month${incomeEntries.length != 1 ? 's' : ''} with income',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Income list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: incomeEntries.length,
                        itemBuilder: (ctx, i) {
                          final entry = incomeEntries[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.payments,
                                  color: Color(0xFF66BB6A),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                widgets.formatZAR(entry.paymentReceived),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    widgets.monthYear(entry.year, entry.month),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                  if (entry.notes != null &&
                                      entry.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.notes!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
