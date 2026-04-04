import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/property_provider.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class EvaluationsScreen extends StatelessWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, prov, _) {
        final evaluations = prov.evaluations;
        final property = prov.selectedProperty;

        if (property == null) {
          return const Scaffold(
            body: EmptyState(
              message: 'No property selected.',
              icon: Icons.home_work_outlined,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Evaluation History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddEvaluation(context, property.id),
              ),
            ],
          ),
          body: evaluations.isEmpty
              ? _buildEmptyState(context, property.id)
              : _buildEvaluationList(context, evaluations, property),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEvaluation(context, property.id),
            icon: const Icon(Icons.add),
            label: const Text('Add Evaluation'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String propertyId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Theme.of(context).colorScheme.primary..withAlpha(5),
          ),
          const SizedBox(height: 16),
          Text(
            'No evaluations yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add property evaluations to track value over time',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEvaluation(context, propertyId),
            icon: const Icon(Icons.add),
            label: const Text('Add First Evaluation'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationList(BuildContext context,
      List<SiteEvaluation> evaluations, Property property) {
    // Sort by date descending (newest first)
    final sorted = List<SiteEvaluation>.from(evaluations)
      ..sort((a, b) => b.evaluationDate.compareTo(a.evaluationDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final eval = sorted[index];
        final previousEval =
            index < sorted.length - 1 ? sorted[index + 1] : null;
        final change =
            previousEval != null ? eval.value - previousEval.value : null;
        final changePercent = previousEval != null && previousEval.value > 0
            ? (change! / previousEval.value) * 100
            : null;

        return _buildEvaluationCard(
            context, eval, change, changePercent, index == 0);
      },
    );
  }

  Widget _buildEvaluationCard(
    BuildContext context,
    SiteEvaluation eval,
    double? change,
    double? changePercent,
    bool isLatest,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLatest
                        ? Theme.of(context).colorScheme.primary.withAlpha(1)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: isLatest
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatZAR(eval.value),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('d MMMM yyyy').format(eval.evaluationDate),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLatest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                        ..withAlpha(1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (change != null) ...[
              const SizedBox(height: 12),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    change >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: change >= 0
                        ? const Color(0xFF6B8E6B)
                        : const Color(0xFFE07A5F),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Change from previous:',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${change >= 0 ? '+' : ''}${formatZAR(change)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: change >= 0
                          ? const Color(0xFF6B8E6B)
                          : const Color(0xFFE07A5F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${changePercent!.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: change >= 0
                          ? const Color(0xFF6B8E6B)
                          : const Color(0xFFE07A5F),
                    ),
                  ),
                ],
              ),
            ],
            if (eval.notes != null && eval.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        eval.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddEvaluation(BuildContext context, String propertyId) {
    final valueController = TextEditingController();
    final notesController = TextEditingController();
    DateTime evalDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Property Evaluation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Property Value *',
                  hintText: 'Current market value',
                  prefixText: 'R ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Evaluation Date'),
                subtitle: Text(DateFormat('d MMMM yyyy').format(evalDate)),
                trailing: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: evalDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      evalDate = date;
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Market conditions, improvements made, etc.',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (valueController.text.isEmpty) return;

              final value = double.tryParse(
                valueController.text.replaceAll(',', '.').replaceAll(' ', ''),
              );
              if (value == null || value <= 0) return;

              final evaluation = SiteEvaluation(
                propertyId: propertyId,
                evaluationDate: evalDate,
                value: value,
                notes:
                    notesController.text.isEmpty ? null : notesController.text,
              );

              await context.read<PropertyProvider>().addEvaluation(evaluation);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save Evaluation'),
          ),
        ],
      ),
    );
  }
}
