import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/models/savings.dart';
import 'package:pata/screens/add_transaction_dialog.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:pata/utils/date_formatter.dart';
import 'package:pata/widgets/amount_button.dart';
import 'package:pata/widgets/date_selector.dart';
import 'package:pata/widgets/period_tabs.dart';
import 'package:pata/widgets/profile_menu.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final repository = ref.read(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Revenus'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.savings, color: Colors.white),
            onPressed: () => _showAddSavingsDialog(),
            tooltip: 'Épargner',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _currentDate = DateTime.now();
              });
            },
            tooltip: "Aujourd'hui",
          ),
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
                          // ✅ Carte Revenus + Épargne (liée à la période)
                          _buildRevenusAndSavingsCard(userId, repository),
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
                // ✅ Liste des revenus
                _buildRevenusList(repository),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE REVENUS + ÉPARGNE (liée à la période)
  // ============================================================
  Widget _buildRevenusAndSavingsCard(String userId, TransactionRepository repository) {
    // ✅ Calculer les dates selon la période sélectionnée
    late DateTime startDate, endDate;

    switch (_selectedPeriod) {
      case Period.day:
        startDate = DateFormatter.getStartOfDay(_currentDate);
        endDate = DateFormatter.getEndOfDay(_currentDate);
        break;
      case Period.week:
        startDate = DateFormatter.getStartOfWeek(_currentDate);
        endDate = DateFormatter.getEndOfWeek(_currentDate);
        break;
      case Period.month:
        startDate = DateFormatter.getStartOfMonth(_currentDate);
        endDate = DateFormatter.getEndOfMonth(_currentDate);
        break;
      case Period.year:
        startDate = DateFormatter.getStartOfYear(_currentDate);
        endDate = DateFormatter.getEndOfYear(_currentDate);
        break;
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StreamBuilder<List<Transaction>>(
              stream: repository.watchTransactionsByPeriod(
                startDate: startDate,
                endDate: endDate,
                type: TransactionType.revenu,
              ),
              builder: (context, snapshot) {
                final revenus = snapshot.data ?? [];
                final totalRevenus = revenus.fold<int>(0, (sum, t) => sum + t.montant);

                return Column(
                  children: [
                    Text(
                      'Total des revenus',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrencyWithSymbol(totalRevenus),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildSavingsSection(userId, startDate, endDate, totalRevenus),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION ÉPARGNE (liée à la période)
  // ============================================================
  Widget _buildSavingsSection(String userId, DateTime startDate, DateTime endDate, int totalRevenus) {
    return StreamBuilder<firestore.QuerySnapshot>(
      stream: firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        int totalEpargne = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = DateTime.parse(data['date'] as String);
            // ✅ Filtrer par période
            final transactionDate = DateTime(date.year, date.month, date.day);
            final start = DateTime(startDate.year, startDate.month, startDate.day);
            final end = DateTime(endDate.year, endDate.month, endDate.day);
            final isInPeriod = transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
                               transactionDate.isBefore(end.add(const Duration(days: 1)));
            if (isInPeriod) {
              totalEpargne += data['montant'] as int;
            }
          }
        }

        final pourcentage = totalRevenus > 0
            ? (totalEpargne / totalRevenus * 100).clamp(0.0, 100.0)
            : 0.0;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Épargne :',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrencyWithSymbol(totalEpargne),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.teal, size: 20),
                  onPressed: () => _showAddSavingsDialog(),
                  tooltip: 'Ajouter une épargne',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
              child: totalEpargne > 0
                  ? Container(
                      width: pourcentage,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : null,
            ),
            if (totalEpargne > 0 && totalRevenus > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${pourcentage.toStringAsFixed(0)}% des revenus épargnés',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LISTE DES REVENUS
  // ============================================================
  Widget _buildRevenusList(TransactionRepository repository) {
    late DateTime startDate, endDate;

    switch (_selectedPeriod) {
      case Period.day:
        startDate = DateFormatter.getStartOfDay(_currentDate);
        endDate = DateFormatter.getEndOfDay(_currentDate);
        break;
      case Period.week:
        startDate = DateFormatter.getStartOfWeek(_currentDate);
        endDate = DateFormatter.getEndOfWeek(_currentDate);
        break;
      case Period.month:
        startDate = DateFormatter.getStartOfMonth(_currentDate);
        endDate = DateFormatter.getEndOfMonth(_currentDate);
        break;
      case Period.year:
        startDate = DateFormatter.getStartOfYear(_currentDate);
        endDate = DateFormatter.getEndOfYear(_currentDate);
        break;
    }

    return StreamBuilder<List<Transaction>>(
      stream: repository.watchTransactionsByPeriod(
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.revenu,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final revenus = snapshot.data ?? [];

        if (revenus.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_money, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun revenu pour cette période',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
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
        );
      },
    );
  }

  // ============================================================
  // BOUTON PERSONNALISÉ
  // ============================================================
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

  // ============================================================
  // AJOUTER UNE ÉPARGNE
  // ============================================================
  void _showAddSavingsDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.savings, color: Colors.teal),
            SizedBox(width: 8),
            Text('Ajouter une épargne'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant (FCFA)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final montant = int.tryParse(controller.text);
              if (montant != null && montant > 0) {
                Navigator.pop(context);

                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  final savings = Savings(
                    id: const Uuid().v4(),
                    montant: montant,
                    motif: 'Épargne',
                    date: DateTime.now(),
                  );

                  await firestore.FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('savings')
                      .doc(savings.id)
                      .set(savings.toFirestore());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${formatCurrencyWithSymbol(montant)} épargné'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir un montant valide'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Épargner'),
          ),
        ],
      ),
    );
  }
}