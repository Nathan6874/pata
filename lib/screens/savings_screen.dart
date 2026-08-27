import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pata/models/transaction.dart';
import 'package:pata/utils/currency_formatter.dart';
import 'package:pata/utils/date_formatter.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  double _savingsGoal = 50000; // Objectif par défaut
  final TextEditingController _goalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Épargne intelligente'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<firestore.QuerySnapshot>(
        stream: firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Ajoutez vos premières transactions',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Récupérer toutes les transactions
          final allDocs = snapshot.data!.docs;
          final allTransactions = allDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Transaction(
              id: doc.id,
              montant: data['montant'] as int? ?? 0,
              motif: data['motif'] as String? ?? '',
              categorie: data['categorie'] as String? ?? 'Autre',
              type: data['type'] == 'revenu'
                  ? TransactionType.revenu
                  : TransactionType.depense,
              date: DateTime.parse(data['date'] as String),
              synced: true,
            );
          }).toList();

          // Analyser les données
          final analysis = _analyzeTransactions(allTransactions);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Carte de résumé
                      _buildSummaryCard(analysis),

                      const SizedBox(height: 16),

                      // 2. Objectif d'épargne
                      _buildSavingsGoalCard(analysis),

                      const SizedBox(height: 16),

                      // 3. Conseils intelligents
                      _buildAdviceCard(analysis),

                      const SizedBox(height: 16),

                      // 4. Analyse par catégorie
                      _buildCategoryAnalysis(analysis),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ANALYSE DES DONNÉES
  // ============================================================
  Map<String, dynamic> _analyzeTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    // Filtrer les 30 derniers jours
    final recent = transactions.where((t) => t.date.isAfter(last30Days)).toList();

    // Revenus et dépenses
    final totalRevenus = recent
        .where((t) => t.type == TransactionType.revenu)
        .fold(0, (sum, t) => sum + t.montant);

    final totalDepenses = recent
        .where((t) => t.type == TransactionType.depense)
        .fold(0, (sum, t) => sum + t.montant);

    // Dépenses par catégorie
    final Map<String, int> depensesParCategorie = {};
    for (final t in recent.where((t) => t.type == TransactionType.depense)) {
      depensesParCategorie[t.categorie] =
          (depensesParCategorie[t.categorie] ?? 0) + t.montant;
    }

    // Dépenses par jour
    final Map<String, int> depensesParJour = {};
    for (final t in recent.where((t) => t.type == TransactionType.depense)) {
      final key = DateFormatter.formatDay(t.date);
      depensesParJour[key] = (depensesParJour[key] ?? 0) + t.montant;
    }

    // Moyenne quotidienne
    final totalDays = depensesParJour.keys.length;
    final moyenneQuotidienne = totalDays > 0 ? totalDepenses / totalDays : 0;

    // Épargne potentielle
    final epargnePotentielle = totalRevenus - totalDepenses;

    return {
      'totalRevenus': totalRevenus,
      'totalDepenses': totalDepenses,
      'depensesParCategorie': depensesParCategorie,
      'depensesParJour': depensesParJour,
      'moyenneQuotidienne': moyenneQuotidienne,
      'epargnePotentielle': epargnePotentielle,
      'totalTransactions': recent.length,
      'nbJours': totalDays,
    };
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildSummaryCard(Map<String, dynamic> analysis) {
    final totalRevenus = analysis['totalRevenus'] as int;
    final totalDepenses = analysis['totalDepenses'] as int;
    final epargne = analysis['epargnePotentielle'] as int;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '📊 Résumé des 30 derniers jours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Revenus', formatCurrencyWithSymbol(totalRevenus), Colors.green),
                _buildStat('Dépenses', formatCurrencyWithSymbol(totalDepenses), Colors.red),
                _buildStat('Épargne', formatCurrencyWithSymbol(epargne), Colors.teal),
              ],
            ),
            if (epargne > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.teal, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tu peux épargner ${formatCurrencyWithSymbol(epargne)} sur cette période !',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tu dépenses plus que tes revenus',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsGoalCard(Map<String, dynamic> analysis) {
    final epargne = analysis['epargnePotentielle'] as int;
    final progress = epargne > 0 ? (epargne / _savingsGoal).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Objectif d\'épargne',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Objectif (FCFA)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _savingsGoal = parsed.toDouble();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Réinitialiser à 50000
                    setState(() {
                      _savingsGoal = 50000;
                      _goalController.text = '50000';
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: progress >= 1 ? Colors.green : Colors.teal,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${formatCurrencyWithSymbol(epargne)} / ${formatCurrencyWithSymbol(_savingsGoal.toInt())}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard(Map<String, dynamic> analysis) {
    final depensesParCategorie = analysis['depensesParCategorie'] as Map<String, int>;
    final totalDepenses = analysis['totalDepenses'] as int;

    // Trouver la catégorie avec le plus de dépenses
    String maxCategorie = 'Autre';
    int maxMontant = 0;
    depensesParCategorie.forEach((categorie, montant) {
      if (montant > maxMontant) {
        maxMontant = montant;
        maxCategorie = categorie;
      }
    });

    // Conseils personnalisés
    final conseils = <String>[];
    if (maxMontant > 0) {
      final pourcentage = (maxMontant / totalDepenses * 100).toStringAsFixed(0);
      conseils.add(
        '📌 Tu as dépensé $pourcentage% de ton budget en "$maxCategorie" ce mois-ci.',
      );
    }

    if (maxCategorie == 'Nourriture') {
      conseils.add('🥗 Astuce : Essaie de cuisiner à la maison 2 fois de plus par semaine.');
    } else if (maxCategorie == 'Transport') {
      conseils.add('🚌 Astuce : Le covoiturage pourrait te faire économiser jusqu\'à 30% sur tes frais de transport.');
    } else if (maxCategorie == 'Factures') {
      conseils.add('💡 Astuce : Vérifie si tu peux réduire ta consommation d\'électricité et d\'eau.');
    } else if (maxCategorie == 'Télécom') {
      conseils.add('📱 Astuce : Compare les forfaits pour trouver une meilleure offre.');
    }

    if (analysis['epargnePotentielle'] < 0) {
      conseils.add('⚠️ Attention : Tes dépenses dépassent tes revenus. Essaie de réduire les dépenses non essentielles.');
    }

    if (conseils.isEmpty) {
      conseils.add('💪 Continue comme ça ! Tu gères bien ton budget.');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧠 Conseils personnalisés',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...conseils.map((conseil) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.teal)),
                  Expanded(child: Text(conseil)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAnalysis(Map<String, dynamic> analysis) {
    final depensesParCategorie = analysis['depensesParCategorie'] as Map<String, int>;
    final totalDepenses = analysis['totalDepenses'] as int;

    if (depensesParCategorie.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Répartition des dépenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...depensesParCategorie.entries.map((entry) {
              final pourcentage = (entry.value / totalDepenses * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text(
                      '${formatCurrencyWithSymbol(entry.value)} ($pourcentage%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
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