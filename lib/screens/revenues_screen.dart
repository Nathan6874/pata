import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/screens/add_transaction_dialog.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:pata/utils/date_formatter.dart';
import 'package:pata/widgets/amount_button.dart';
import 'package:pata/widgets/date_selector.dart';
import 'package:pata/widgets/period_tabs.dart';
import 'package:pata/widgets/profile_menu.dart';  // ← AJOUTER
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RevenuesScreen extends ConsumerStatefulWidget {
  const RevenuesScreen({super.key});

  @override
  ConsumerState<RevenuesScreen> createState() => _RevenuesScreenState();
}

class _RevenuesScreenState extends ConsumerState<RevenuesScreen> {
  Period _selectedPeriod = Period.month;
  DateTime _currentDate = DateTime.now();

  final List<int> _revenuePresets = [5000, 10000, 25000, 50000, 100000, 200000];

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(transactionRepositoryProvider);
    
    late DateTime startDate;
    late DateTime endDate;
    late String periodTitle;
    
    switch (_selectedPeriod) {
      case Period.day:
        startDate = DateFormatter.getStartOfDay(_currentDate);
        endDate = DateFormatter.getEndOfDay(_currentDate);
        periodTitle = DateFormatter.formatDay(_currentDate);
        break;
      case Period.week:
        startDate = DateFormatter.getStartOfWeek(_currentDate);
        endDate = DateFormatter.getEndOfWeek(_currentDate);
        periodTitle = DateFormatter.formatWeek(_currentDate);
        break;
      case Period.month:
        startDate = DateFormatter.getStartOfMonth(_currentDate);
        endDate = DateFormatter.getEndOfMonth(_currentDate);
        periodTitle = DateFormatter.formatMonth(_currentDate);
        break;
      case Period.year:
        startDate = DateFormatter.getStartOfYear(_currentDate);
        endDate = DateFormatter.getEndOfYear(_currentDate);
        periodTitle = DateFormatter.formatYear(_currentDate);
        break;
    }

    final revenus = repository.getTransactionsByPeriod(
      startDate: startDate,
      endDate: endDate,
      type: TransactionType.revenu,
    );
    
    final totalRevenus = repository.getTotalRevenus(
      startDate: startDate,
      endDate: endDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Revenus'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Bouton Aujourd'hui
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _currentDate = DateTime.now();
              });
            },
            tooltip: "Aujourd'hui",
          ),
          // ← AJOUTER LE PROFIL
          const ProfileMenu(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(
                                    'Total des revenus',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatCurrencyWithSymbol(totalRevenus),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    periodTitle,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: DateSelector(
                              selectedDate: _currentDate,
                              onDateChanged: (newDate) {
                                setState(() {
                                  _currentDate = newDate;
                                });
                              },
                              periodType: _selectedPeriod,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PeriodTabs(
                            selectedPeriod: _selectedPeriod,
                            onPeriodChanged: (period) {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ajout rapide',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ..._revenuePresets.map((amount) => AmountButton(
                                amount: amount,
                                onTap: () => showAddTransactionDialog(
                                  context: context,
                                  amount: amount,
                                  type: TransactionType.revenu,
                                ),
                                isCompact: true,
                              )),
                              _buildCustomRevenueButton(),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                if (revenus.isEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_money, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun revenu enregistré',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ajoutez vos premiers revenus',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = revenus[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(Icons.trending_up, color: Colors.green, size: 20),
                            ),
                            title: Text(transaction.motif),
                            subtitle: Text(
                              DateFormatter.formatFull(transaction.date),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              formatCurrencyWithSymbol(transaction.montant),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: revenus.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRevenueButton() {
    return SizedBox(
      width: 90,
      height: 60,
      child: OutlinedButton(
        onPressed: () => _showCustomAmountDialog(),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20, color: Colors.green.shade700),
            Text(
              'Autre',
              style: TextStyle(color: Colors.green.shade700, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomAmountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Montant personnalisé'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant en FCFA',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                showAddTransactionDialog(
                  context: context,
                  amount: amount,
                  type: TransactionType.revenu,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}