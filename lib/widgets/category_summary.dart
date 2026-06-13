import 'package:pata/categories/category_service.dart';
import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategorySummary extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const CategorySummary({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(transactionRepositoryProvider);
    final categoryTotals = repository.getCategoryTotals(
      startDate: startDate,
      endDate: endDate,
    );
    
    final categories = CategoryService().rules.map((r) => r.name).toList();
    
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé par catégorie',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: categories.where((cat) => categoryTotals.containsKey(cat)).map((category) {
                final amount = categoryTotals[category] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        formatCurrencyWithSymbol(amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Nourriture':
        return Colors.green;
      case 'Transport':
        return Colors.orange;
      case 'Factures':
        return Colors.red;
      case 'Télécom':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}