import 'package:pata/categories/category_service.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/data/remote/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return TransactionRepository(firestoreService: firestoreService);
});

class TransactionRepository {
  final FirestoreService _firestoreService;

  TransactionRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> addTransaction({
    required int montant,
    required String motif,
    required TransactionType type,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final category = CategoryService().categorize(motif);

    final transaction = Transaction(
      id: const Uuid().v4(),
      montant: montant,
      motif: motif,
      categorie: category,
      type: type,
      date: now,
      synced: true,
    );

    await _firestoreService.addTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _firestoreService.deleteTransaction(id);
  }

  Stream<List<Transaction>> watchTransactions() {
    return _firestoreService.watchTransactions();
  }

  // ✅ Récupérer les transactions d'une période
  Stream<List<Transaction>> watchTransactionsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  }) {
    return _firestoreService.watchTransactions().map((transactions) {
      return transactions.where((t) {
        final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        final isInPeriod = transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
                           transactionDate.isBefore(end.add(const Duration(days: 1)));
        final matchesType = type == null || t.type == type;
        return isInPeriod && matchesType;
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // ✅ Récupérer les totaux par catégorie (avec Future)
  Future<Map<String, int>> getCategoryTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await _firestoreService.fetchAllTransactions();
    final Map<String, int> totals = {};
    for (final t in transactions) {
      if (t.type == TransactionType.depense &&
          t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)))) {
        totals[t.categorie] = (totals[t.categorie] ?? 0) + t.montant;
      }
    }
    return totals;
  }
}