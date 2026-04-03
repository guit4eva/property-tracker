import 'package:flutter/material.dart';

/// A reusable year selector widget with arrow navigation and swipe support.
///
/// Matches the exact design used on the Monthly screen but for years only.
/// Displays the current year in the center with left/right arrows to navigate.
/// Supports swipe gestures and tap to pick a year.
class YearSelector extends StatefulWidget {
  /// The currently selected year.
  final int selectedYear;

  /// List of available years to navigate through.
  final List<int> years;

  /// Callback when the selected year changes.
  final ValueChanged<int> onYearChanged;

  /// Label to show when viewing all time.
  final String allTimeLabel;

  const YearSelector({
    super.key,
    required this.selectedYear,
    required this.years,
    required this.onYearChanged,
    this.allTimeLabel = 'All Time',
  });

  @override
  State<YearSelector> createState() => _YearSelectorState();
}

class _YearSelectorState extends State<YearSelector> {
  void _previousYear() {
    final currentIndex = widget.years.indexOf(widget.selectedYear);
    if (currentIndex > 0) {
      widget.onYearChanged(widget.years[currentIndex - 1]);
    }
  }

  void _nextYear() {
    final currentIndex = widget.years.indexOf(widget.selectedYear);
    if (currentIndex < widget.years.length - 1) {
      widget.onYearChanged(widget.years[currentIndex + 1]);
    }
  }

  Future<void> _pickYear() async {
    if (widget.years.isEmpty) return;

    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _YearPickerDialog(
        initial: widget.selectedYear,
        years: widget.years,
      ),
    );
    if (picked != null) {
      widget.onYearChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            // Swipe right = previous
            _previousYear();
          } else if (details.primaryVelocity! < 0) {
            // Swipe left = next
            _nextYear();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: _previousYear,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickYear,
                child: Text(
                  widget.selectedYear == 0
                      ? widget.allTimeLabel
                      : '${widget.selectedYear}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _nextYear,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for picking a year.
class _YearPickerDialog extends StatefulWidget {
  final int initial;
  final List<int> years;

  const _YearPickerDialog({
    required this.initial,
    required this.years,
  });

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final sortedYears = List<int>.from(widget.years)..sort((a, b) => b.compareTo(a));

    return AlertDialog(
      title: const Text('Select Year'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: sortedYears.length,
                itemBuilder: (ctx, index) {
                  final year = sortedYears[index];
                  final selected = year == _selectedYear;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedYear = year),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$year',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedYear),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
