import 'package:pata/categories/category_service.dart';
import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategorySummary extends ConsumerStatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const CategorySummary({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<CategorySummary> createState() => _CategorySummaryState();
}

class _CategorySummaryState extends ConsumerState<CategorySummary> {
  // ✅ Mémoriser les données pour éviter de recalculer à chaque rebuild
  Map<String, int>? _cachedData;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(transactionRepositoryProvider);
    
    // Si on a déjà des données en cache, les afficher immédiatement
    if (_cachedData != null && _cachedData!.isNotEmpty) {
      return _buildSummary(_cachedData!);
    }

    return FutureBuilder<Map<String, int>>(
      future: repository.getCategoryTotals(
        startDate: widget.startDate,
        endDate: widget.endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ✅ Affichage minimal pendant le chargement
          return const SizedBox(
            height: 30,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Mettre en cache
        _cachedData = snapshot.data!;
        return _buildSummary(snapshot.data!);
      },
    );
  }

  Widget _buildSummary(Map<String, int> categoryTotals) {
    final categories = CategoryService().rules.map((r) => r.name).toList();
    final visibleCategories = categories.where((cat) => categoryTotals.containsKey(cat)).toList();

    if (visibleCategories.isEmpty) {
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
              children: visibleCategories.map((category) {
                final amount = categoryTotals[category] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        formatCurrencyWithSymbol(amount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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