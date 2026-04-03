import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable month/year selector widget with arrow navigation and swipe support.
///
/// Matches the exact design used on the Monthly screen.
/// Displays the current month/year in the center with left/right arrows to navigate.
/// Supports swipe gestures to change months.
class MonthYearSelector extends StatefulWidget {
  /// The currently selected date (year and month).
  final DateTime selectedDate;

  /// Callback when the selected date changes.
  final ValueChanged<DateTime> onDateChanged;

  const MonthYearSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<MonthYearSelector> createState() => _MonthYearSelectorState();
}

class _MonthYearSelectorState extends State<MonthYearSelector> {
  void _previousMonth() {
    final newDate = DateTime(
      widget.selectedDate.month == 1
          ? widget.selectedDate.year - 1
          : widget.selectedDate.year,
      widget.selectedDate.month == 1 ? 12 : widget.selectedDate.month - 1,
    );
    widget.onDateChanged(newDate);
  }

  void _nextMonth() {
    final newDate = DateTime(
      widget.selectedDate.month == 12
          ? widget.selectedDate.year + 1
          : widget.selectedDate.year,
      widget.selectedDate.month == 12 ? 1 : widget.selectedDate.month + 1,
    );
    widget.onDateChanged(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            // Swipe right = previous
            _previousMonth();
          } else if (details.primaryVelocity! < 0) {
            // Swipe left = next
            _nextMonth();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(widget.selectedDate),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
