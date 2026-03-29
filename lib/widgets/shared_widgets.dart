import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Currency formatter ───────────────────────────────────────────────────────

final _zar =
    NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 2);

String formatZAR(double v) => _zar.format(v);

String monthName(int month) => DateFormat('MMM').format(DateTime(2000, month));

String monthYear(int year, int month) =>
    DateFormat('MMM yyyy').format(DateTime(year, month));

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatZAR(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

// ─── Currency TextField ───────────────────────────────────────────────────────

class CurrencyField extends StatefulWidget {
  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;
  final String? hint;

  const CurrencyField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
  });

  @override
  State<CurrencyField> createState() => _CurrencyFieldState();
}

class _CurrencyFieldState extends State<CurrencyField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text:
          widget.initialValue > 0 ? widget.initialValue.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? '0.00',
        prefixText: 'R ',
        prefixStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        widget.onChanged(parsed ?? 0);
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(80)),
          const SizedBox(height: 12),
          Text(
            message,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Loading overlay ─────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor:
            AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
        strokeWidth: 2,
      ),
    );
  }
}

// ─── Cost category chip ───────────────────────────────────────────────────────

const Map<String, Color> categoryColors = {
  'water': Color(0xFF42A5F5),
  'electricity': Color(0xFFF5C842),
  'interest': Color(0xFFEF5350),
  'rates': Color(0xFFAB47BC),
  'running': Color(0xFF4CAF7D),
  'received': Color(0xFF4CAF7D),
};
