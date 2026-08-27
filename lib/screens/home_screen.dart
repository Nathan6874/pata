import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/screens/add_transaction_dialog.dart';
import 'package:pata/screens/revenues_screen.dart';
import 'package:pata/services/update_service.dart';
import 'package:pata/utils/constants.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:pata/utils/date_formatter.dart';
import 'package:pata/widgets/amount_button.dart';
import 'package:pata/widgets/balance_card.dart';
import 'package:pata/widgets/category_summary.dart';
import 'package:pata/widgets/date_selector.dart';
import 'package:pata/widgets/period_tabs.dart';
import 'package:pata/widgets/profile_menu.dart';
import 'package:pata/widgets/transaction_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;   
import 'package:firebase_auth/firebase_auth.dart';  
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Period _selectedPeriod = Period.day;
  int _selectedIndex = 0;
  DateTime _currentDate = DateTime.now();
  
  late Stream<List<Transaction>> _transactionsStream;

  @override
  void initState() {
    super.initState();
    
    // ✅ Ne vérifier les mises à jour que sur Android (pas sur Web)
    if (!kIsWeb) {
      _checkForUpdate();
    }
    
    // ✅ Initialiser le stream Firestore
    _initFirestoreStream();
  }

  // ✅ Méthode pour initialiser le stream Firestore
  void _initFirestoreStream() {
    final firestoreInstance = firestore.FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId != null) {
      _transactionsStream = firestoreInstance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return Transaction(
                id: doc.id,
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
            }).toList();
          });
    } else {
      _transactionsStream = Stream.value([]);
    }
  }

  Future<void> _checkForUpdate() async {
    final isUpdateAvailable = await UpdateService.checkForUpdate();
    if (isUpdateAvailable && mounted) {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📱 Mise à jour disponible'),
        content: const Text(
          'Une nouvelle version de PATA est disponible.\n\n'
          'Voulez-vous l\'installer maintenant ?\n'
          '(Recommandé pour profiter des dernières fonctionnalités)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await UpdateService.startUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Installer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0 ? _buildDepensesScreen() : const RevenuesScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_down),
            label: 'Dépenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Revenus',
          ),
        ],
      ),
    );
  }

  Widget _buildDepensesScreen() {
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

    return StreamBuilder<List<Transaction>>(
      stream: _transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allTransactions = snapshot.data!;
        
        final depenses = allTransactions.where((t) {
          final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          
          final isInPeriod = transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
                            transactionDate.isBefore(end.add(const Duration(days: 1)));
          return isInPeriod && t.type == TransactionType.depense;
        }).toList()..sort((a, b) => b.date.compareTo(a.date));
        
        final totalDepenses = depenses.fold(0, (sum, t) => sum + t.montant);
        
        final revenus = allTransactions.where((t) {
          final transactionDate = DateTime(t.date.year, t.date.month, t.date.day);
          final start = DateTime(startDate.year, startDate.month, startDate.day);
          final end = DateTime(endDate.year, endDate.month, endDate.day);
          
          final isInPeriod = transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
                            transactionDate.isBefore(end.add(const Duration(days: 1)));
          return isInPeriod && t.type == TransactionType.revenu;
        }).toList();
        
        final totalRevenus = revenus.fold(0, (sum, t) => sum + t.montant);

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Mes Dépenses'),
              floating: true,
              centerTitle: true,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              actions: [
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BalanceCard(
                      revenus: totalRevenus,
                      depenses: totalDepenses,
                      periodLabel: periodTitle,
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Ajout rapide',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ...AppConstants.presetAmounts.map((amount) => AmountButton(
                            amount: amount,
                            onTap: () => showAddTransactionDialog(
                              context: context,
                              amount: amount,
                              type: TransactionType.depense,
                            ),
                          )),
                          _buildCustomAmountButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CategorySummary(
                      startDate: startDate,
                      endDate: endDate,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historique',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          depenses.isEmpty
                              ? 'Aucune dépense pour cette période'
                              : '${depenses.length} dépense(s)',
                          style: TextStyle(
                            color: depenses.isEmpty ? Colors.red.shade400 : Colors.grey.shade600,
                            fontWeight: depenses.isEmpty ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (depenses.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune dépense pour cette période',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              TransactionList(transactions: depenses, showTypeIcon: false),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildCustomAmountButton() {
    return SizedBox(
      width: 100,
      height: 70,
      child: OutlinedButton(
        onPressed: () => _showCustomAmountDialog(),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.teal.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.teal.shade700, size: 24),
            Text(
              'Autre',
              style: TextStyle(color: Colors.teal.shade700, fontSize: 12),
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
                  type: TransactionType.depense,
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}