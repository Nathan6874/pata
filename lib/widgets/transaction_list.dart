import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:pata/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionList extends ConsumerWidget {
  final List<Transaction> transactions;
  final bool showTypeIcon;
  final bool isRevenue;

  const TransactionList({
    super.key,
    required this.transactions,
    this.showTypeIcon = false,
    this.isRevenue = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          return Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer'),
                        content: const Text('Voulez-vous vraiment supprimer cette transaction ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(transactionRepositoryProvider).deleteTransaction(transaction.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction supprimée')),
                        );
                      }
                    }
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Supprimer',
                ),
              ],
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(transaction.categorie),
                  child: Text(
                    transaction.categorie.substring(0, 1),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.motif,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showTypeIcon)
                      Icon(
                        isRevenue ? Icons.trending_up : Icons.trending_down,
                        color: isRevenue ? Colors.green : Colors.red,
                        size: 16,
                      ),
                  ],
                ),
                subtitle: Text(
                  DateFormatter.formatFull(transaction.date),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  formatCurrencyWithSymbol(transaction.montant),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.revenu ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
        childCount: transactions.length,
      ),
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