import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/property_provider.dart';
import '../widgets/shared_widgets.dart' as widgets;

class MunicipalityPaymentsScreen extends StatelessWidget {
  const MunicipalityPaymentsScreen({super.key});

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

        // Get all expenses with municipality payments
        final payments =
            prov.expenses.where((e) => e.paymentToMunicipality > 0).toList()
              ..sort((a, b) {
                final yearCmp = b.year.compareTo(a.year);
                return yearCmp != 0 ? yearCmp : b.month.compareTo(a.month);
              });

        final totalPayments = prov.expenses.fold<double>(
          0,
          (sum, e) => sum + e.paymentToMunicipality,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Municipality Payments')),
          body: payments.isEmpty
              ? const widgets.EmptyState(
                  message: 'No municipality payments recorded yet.',
                  icon: Icons.account_balance_outlined,
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
                            const Color(0xFF42A5F5).withValues(alpha: 0.15),
                            const Color(0xFF42A5F5).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Payments',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widgets.formatZAR(totalPayments),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF42A5F5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${payments.length} payment${payments.length != 1 ? 's' : ''} recorded',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Payments list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: payments.length,
                        itemBuilder: (ctx, i) {
                          final payment = payments[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF42A5F5)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Color(0xFF42A5F5),
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                widgets
                                    .formatZAR(payment.paymentToMunicipality),
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
                                    widgets.monthYear(
                                        payment.year, payment.month),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                  if (payment.notes != null &&
                                      payment.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      payment.notes!,
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
