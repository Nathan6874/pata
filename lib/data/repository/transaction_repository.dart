import 'package:pata/categories/category_service.dart';
import 'package:pata/data/local/hive_service.dart';
import 'package:pata/data/remote/firestore_service.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/models/sync_queue.dart';
import 'package:pata/providers/providers.dart';
import 'package:pata/utils/connectivity_checker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

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

  // ✅ Méthode syncData à l'intérieur de la classe
  Future<void> syncData() async {
    if (_connectivityChecker.isConnected) {
      await loadFromFirestore();
      await _syncNow();
    }
  }

  // Helper pour vérifier si Hive est prêt
  Box<Transaction>? get _transactionsBox {
    try {
      return HiveService.transactionsBox;
    } catch (e) {
      print('⚠️ Hive transactionsBox non disponible: $e');
      return null;
    }
  }

  Box<SyncQueueItem>? get _syncQueueBox {
    try {
      return HiveService.syncQueueBox;
    } catch (e) {
      print('⚠️ Hive syncQueueBox non disponible: $e');
      return null;
    }
  }

  // Charger les données depuis Firestore vers Hive
  Future<void> loadFromFirestore() async {
    if (!_connectivityChecker.isConnected) return;
    
    try {
      final transactions = await _firestoreService.fetchAllTransactions();
      
      final box = _transactionsBox;
      if (box == null) {
        print('⚠️ Hive non disponible, chargement ignoré');
        return;
      }
      
      // Vider Hive
      await box.clear();
      
      // Remplir avec les données Firestore
      for (final transaction in transactions) {
        await box.put(transaction.id, transaction);
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

    final box = _transactionsBox;
    final syncBox = _syncQueueBox;
    
    if (box == null || syncBox == null) {
      print('⚠️ Hive non disponible, transaction non sauvegardée');
      return;
    }

    await box.put(transaction.id, transaction);
    
    final syncItem = SyncQueueItem(
      id: transaction.id,
      action: SyncAction.create,
      transaction: transaction,
      createdAt: DateTime.now(),
    );
    await syncBox.put(transaction.id, syncItem);

    if (_connectivityChecker.isConnected) {
      await _syncNow();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final box = _transactionsBox;
    final syncBox = _syncQueueBox;
    
    if (box == null || syncBox == null) {
      print('⚠️ Hive non disponible, suppression ignorée');
      return;
    }

    final transaction = box.get(id);
    if (transaction != null) {
      await box.delete(id);
      
      final syncItem = SyncQueueItem(
        id: id,
        action: SyncAction.delete,
        transaction: transaction,
        createdAt: DateTime.now(),
      );
      await syncBox.put(id, syncItem);
      
      if (_connectivityChecker.isConnected) {
        await _syncNow();
      }
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final box = _transactionsBox;
    final syncBox = _syncQueueBox;
    
    if (box == null || syncBox == null) {
      print('⚠️ Hive non disponible, mise à jour ignorée');
      return;
    }

    final updatedTransaction = transaction.copyWith(synced: false);
    await box.put(updatedTransaction.id, updatedTransaction);
    
    final syncItem = SyncQueueItem(
      id: updatedTransaction.id,
      action: SyncAction.update,
      transaction: updatedTransaction,
      createdAt: DateTime.now(),
    );
    await syncBox.put(updatedTransaction.id, syncItem);
    
    if (_connectivityChecker.isConnected) {
      await _syncNow();
    }
  }

  Future<void> _syncNow() async {
    final syncBox = _syncQueueBox;
    if (syncBox == null) {
      print('⚠️ Hive syncQueue non disponible');
      return;
    }

    final syncItems = syncBox.values.toList();
    
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
        
        final box = _transactionsBox;
        if (box != null) {
          final transaction = box.get(item.id);
          if (transaction != null) {
            await box.put(
              item.id,
              transaction.copyWith(synced: true),
            );
          }
        }
        await syncBox.delete(item.id);
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
    final box = _transactionsBox;
    if (box == null) {
      print('⚠️ Hive non disponible, liste vide');
      return [];
    }

    final allTransactions = box.values.toList();
    
    return allTransactions.where((t) {
      // Comparer uniquement les dates (sans l'heure)
      final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      final isInPeriod = transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
                        transactionDate.isBefore(end.add(const Duration(days: 1)));
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