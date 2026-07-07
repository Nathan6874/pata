import 'package:hive_flutter/hive_flutter.dart';
import 'package:pata/adapters/transaction_adapter.dart';
import 'package:pata/adapters/sync_queue_adapter.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/models/sync_queue.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String syncQueueBoxName = 'sync_queue';

  static late Box<Transaction> _transactionsBox;
  static late Box<SyncQueueItem> _syncQueueBox;

  static Future<void> init() async {
    // ✅ Sur le Web, on n'utilise pas path_provider
    if (kIsWeb) {
      Hive.init('hive_db');
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    }
    
    // Enregistrer les adapters
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(SyncQueueItemAdapter());
    Hive.registerAdapter(SyncActionAdapter());
    
    // Ouvrir les boxes
    _transactionsBox = await Hive.openBox<Transaction>(transactionsBoxName);
    _syncQueueBox = await Hive.openBox<SyncQueueItem>(syncQueueBoxName);
  }

  static Box<Transaction> get transactionsBox => _transactionsBox;
  static Box<SyncQueueItem> get syncQueueBox => _syncQueueBox;

  static Future<void> clearAll() async {
    await _transactionsBox.clear();
    await _syncQueueBox.clear();
  }
}