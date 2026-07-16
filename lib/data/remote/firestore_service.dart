import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pata/models/transaction.dart' as model;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  
  CollectionReference get _transactionsCollection {
    if (_userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    return _firestore.collection('users').doc(_userId).collection('transactions');
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    await _transactionsCollection.doc(transaction.id).set(transaction.toFirestore());
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    await _transactionsCollection.doc(transaction.id).update(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsCollection.doc(id).delete();
  }

  // ✅ ÉCOUTE EN TEMPS RÉEL
  Stream<List<model.Transaction>> watchTransactions() {
    return _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return model.Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  Future<List<model.Transaction>> fetchAllTransactions() async {
    final snapshot = await _transactionsCollection
        .orderBy('date', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      return model.Transaction.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
}