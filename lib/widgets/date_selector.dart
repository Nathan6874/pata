import 'package:pata/utils/date_formatter.dart';
import 'package:pata/widgets/period_tabs.dart';
import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final Period periodType;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.periodType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24),
            onPressed: () => _navigate(-1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              _getFormattedDate(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24),
            onPressed: () => _navigate(1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  void _navigate(int direction) {
    DateTime newDate;
    switch (periodType) {
      case Period.day:
        newDate = selectedDate.add(Duration(days: direction));
        break;
      case Period.week:
        newDate = selectedDate.add(Duration(days: direction * 7));
        break;
      case Period.month:
        newDate = DateTime(selectedDate.year, selectedDate.month + direction, 1);
        break;
      case Period.year:
        newDate = DateTime(selectedDate.year + direction, 1, 1);
        break;
    }
    onDateChanged(newDate);
  }

  String _getFormattedDate() {
    switch (periodType) {
      case Period.day:
        return DateFormatter.formatDay(selectedDate);
      case Period.week:
        final start = DateFormatter.getStartOfWeek(selectedDate);
        final end = DateFormatter.getEndOfWeek(selectedDate);
        return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
      case Period.month:
        return DateFormatter.formatMonth(selectedDate);
      case Period.year:
        return selectedDate.year.toString();
    }
  }
}