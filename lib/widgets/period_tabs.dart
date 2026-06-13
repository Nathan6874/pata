import 'package:flutter/material.dart';

enum Period { day, week, month, year }

class PeriodTabs extends StatelessWidget {
  final Period selectedPeriod;
  final Function(Period) onPeriodChanged;

  const PeriodTabs({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTab(Period.day, 'Jour'),
          _buildTab(Period.week, 'Semaine'),
          _buildTab(Period.month, 'Mois'),
          _buildTab(Period.year, 'Année'),
        ],
      ),
    );
  }

  Widget _buildTab(Period period, String label) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}