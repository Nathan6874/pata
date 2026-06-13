import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType {
  depense,
  revenu,
}

class Transaction extends Equatable {
  final String id;
  final int montant;
  final String motif;
  final String categorie;
  final TransactionType type;
  final DateTime date;
  final bool synced;

  const Transaction({
    required this.id,
    required this.montant,
    required this.motif,
    required this.categorie,
    required this.type,
    required this.date,
    this.synced = false,
  });

  Transaction copyWith({
    String? id,
    int? montant,
    String? motif,
    String? categorie,
    TransactionType? type,
    DateTime? date,
    bool? synced,
  }) {
    return Transaction(
      id: id ?? this.id,
      montant: montant ?? this.montant,
      motif: motif ?? this.motif,
      categorie: categorie ?? this.categorie,
      type: type ?? this.type,
      date: date ?? this.date,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'montant': montant,
      'motif': motif,
      'categorie': categorie,
      'type': type.name,
      'date': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      montant: data['montant'] as int,
      motif: data['motif'] as String,
      categorie: data['categorie'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.depense,
      ),
      date: DateTime.parse(data['date'] as String),
      synced: true,
    );
  }

  @override
  List<Object?> get props => [id, montant, motif, categorie, type, date, synced];
}