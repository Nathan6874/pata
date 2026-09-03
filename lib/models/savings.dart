import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Savings extends Equatable {
  final String id;
  final int montant;
  final String motif;
  final DateTime date;
  final bool synced;

  const Savings({
    required this.id,
    required this.montant,
    required this.motif,
    required this.date,
    this.synced = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'montant': montant,
      'motif': motif,
      'date': date.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Savings.fromFirestore(Map<String, dynamic> data, String id) {
    return Savings(
      id: id,
      montant: data['montant'] as int,
      motif: data['motif'] as String,
      date: DateTime.parse(data['date'] as String),
      synced: true,
    );
  }

  @override
  List<Object?> get props => [id, montant, motif, date, synced];
}