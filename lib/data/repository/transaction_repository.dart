import 'package:pata/categories/category_service.dart';
import 'package:pata/data/local/hive_service.dart';
import 'package:pata/data/remote/firestore_service.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/models/sync_queue.dart';
import 'package:pata/providers/providers.dart';
import 'package:pata/utils/connectivity_checker.dart';  // ← AJOUTER CET IMPORT
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final connectivityChecker = ref.read(connectivityCheckerProvider);
  
  return TransactionRepository(
    firestoreService: firestoreService,
    connectivityChecker: connectivityChecker,
  );
});

class TransactionRepository {
  final FirestoreService _firestoreService;
  final ConnectivityChecker _connectivityChecker;

  TransactionRepository({
    required FirestoreService firestoreService,
    required ConnectivityChecker connectivityChecker,
  }) : _firestoreService = firestoreService,
       _connectivityChecker = connectivityChecker;

  // Charger les données depuis Firestore vers Hive
  Future<void> loadFromFirestore() async {
    if (!_connectivityChecker.isConnected) return;
    
    try {
      final transactions = await _firestoreService.fetchAllTransactions();
      
      // Vider Hive
      await HiveService.transactionsBox.clear();
      
      // Remplir avec les données Firestore
      for (final transaction in transactions) {
        await HiveService.transactionsBox.put(transaction.id, transaction);
      }
      
      print('✅ ${transactions.length} transactions chargées depuis Firestore');
    } catch (e) {
      print('❌ Erreur chargement Firestore: $e');
    }
  }

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
      synced: false,
    );

    await HiveService.transactionsBox.put(transaction.id, transaction);
    
    final syncItem = SyncQueueItem(
      id: transaction.id,
      action: SyncAction.create,
      transaction: transaction,
      createdAt: DateTime.now(),
    );
    await HiveService.syncQueueBox.put(transaction.id, syncItem);

    if (_connectivityChecker.isConnected) {
      await _syncNow();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final transaction = HiveService.transactionsBox.get(id);
    if (transaction != null) {
      await HiveService.transactionsBox.delete(id);
      
      final syncItem = SyncQueueItem(
        id: id,
        action: SyncAction.delete,
        transaction: transaction,
        createdAt: DateTime.now(),
      );
      await HiveService.syncQueueBox.put(id, syncItem);
      
      if (_connectivityChecker.isConnected) {
        await _syncNow();
      }
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final updatedTransaction = transaction.copyWith(synced: false);
    await HiveService.transactionsBox.put(updatedTransaction.id, updatedTransaction);
    
    final syncItem = SyncQueueItem(
      id: updatedTransaction.id,
      action: SyncAction.update,
      transaction: updatedTransaction,
      createdAt: DateTime.now(),
    );
    await HiveService.syncQueueBox.put(updatedTransaction.id, syncItem);
    
    if (_connectivityChecker.isConnected) {
      await _syncNow();
    }
  }

  Future<void> _syncNow() async {
    final syncItems = HiveService.syncQueueBox.values.toList();
    
    for (final item in syncItems) {
      try {
        switch (item.action) {
          case SyncAction.create:
            await _firestoreService.addTransaction(item.transaction);
            break;
          case SyncAction.update:
            await _firestoreService.updateTransaction(item.transaction);
            break;
          case SyncAction.delete:
            await _firestoreService.deleteTransaction(item.id);
            break;
        }
        
        final transaction = HiveService.transactionsBox.get(item.id);
        if (transaction != null) {
          await HiveService.transactionsBox.put(
            item.id,
            transaction.copyWith(synced: true),
          );
        }
        await HiveService.syncQueueBox.delete(item.id);
      } catch (e) {
        print('Erreur de synchronisation: $e');
      }
    }
  }

  Future<void> syncManually() async {
    if (_connectivityChecker.isConnected) {
      await _syncNow();
    }
  }

  List<Transaction> getTransactionsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  }) {
    final allTransactions = HiveService.transactionsBox.values.toList();
    
    return allTransactions.where((t) {
      final isInPeriod = t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                         t.date.isBefore(endDate.add(const Duration(days: 1)));
      final matchesType = type == null || t.type == type;
      return isInPeriod && matchesType;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int getTotalByCategory({
    required DateTime startDate,
    required DateTime endDate,
    required String category,
  }) {
    final transactions = getTransactionsByPeriod(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.depense,
    );
    
    return transactions
        .where((t) => t.categorie == category)
        .fold(0, (sum, t) => sum + t.montant);
  }

  Map<String, int> getCategoryTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final transactions = getTransactionsByPeriod(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.depense,
    );
    
    final Map<String, int> totals = {};
    for (final t in transactions) {
      totals[t.categorie] = (totals[t.categorie] ?? 0) + t.montant;
    }
    return totals;
  }

  int getTotalRevenus({required DateTime startDate, required DateTime endDate}) {
    final revenus = getTransactionsByPeriod(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.revenu,
    );
    return revenus.fold(0, (sum, t) => sum + t.montant);
  }

  int getTotalDepenses({required DateTime startDate, required DateTime endDate}) {
    final depenses = getTransactionsByPeriod(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.depense,
    );
    return depenses.fold(0, (sum, t) => sum + t.montant);
  }
}