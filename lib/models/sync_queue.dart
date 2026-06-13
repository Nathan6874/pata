import 'package:equatable/equatable.dart';
import 'package:pata/models/transaction.dart';

enum SyncAction { create, update, delete }

class SyncQueueItem extends Equatable {
  final String id;
  final SyncAction action;
  final Transaction transaction;
  final DateTime createdAt;

  const SyncQueueItem({
    required this.id,
    required this.action,
    required this.transaction,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, action, transaction, createdAt];
}