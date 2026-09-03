import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAddTransactionDialog({
  required BuildContext context,
  required int amount,
  required TransactionType type,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddTransactionDialog(amount: amount, type: type),
  );
}

class AddTransactionDialog extends ConsumerStatefulWidget {
  final int amount;
  final TransactionType type;

  const AddTransactionDialog({
    super.key,
    required this.amount,
    required this.type,
  });

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _motifController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_motifControllerFocusNode);
    });
  }

  final _motifControllerFocusNode = FocusNode();

  @override
  void dispose() {
    _motifController.dispose();
    _motifControllerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.type == TransactionType.depense ? 'Ajouter une dépense' : 'Ajouter un revenu',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.type == TransactionType.depense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: widget.type == TransactionType.depense ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrencyWithSymbol(widget.amount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.type == TransactionType.depense ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Motif de la transaction',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motifController,
                focusNode: _motifControllerFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.type == TransactionType.depense ? 'Ex: Tomate, Recharge CIE...' : 'Ex: Salaire, Business...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit_note),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir un motif';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: widget.type == TransactionType.depense ? Colors.red : Colors.green,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final motif = _capitalizeFirstLetter(_motifController.text.trim());
      final repository = ref.read(transactionRepositoryProvider);
      
      await repository.addTransaction(
        montant: widget.amount,
        motif: motif,
        type: widget.type,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.type == TransactionType.depense
                  ? 'Dépense de ${formatCurrencyWithSymbol(widget.amount)} enregistrée'
                  : 'Revenu de ${formatCurrencyWithSymbol(widget.amount)} enregistré',
            ),
            backgroundColor: widget.type == TransactionType.depense ? Colors.red : Colors.green,
          ),
        );
      }
    }
  }
}