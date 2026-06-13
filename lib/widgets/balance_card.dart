import 'package:pata/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final int revenus;
  final int depenses;
  final String periodLabel;

  const BalanceCard({
    super.key,
    required this.revenus,
    required this.depenses,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final balance = revenus - depenses;
    final bool isPositive = balance >= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [Colors.teal.shade400, Colors.teal.shade700]
                : [Colors.orange.shade300, Colors.deepOrange.shade400], // ← Couleur apaisante (orange au lieu de rouge)
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              periodLabel,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Revenus', formatCurrencyWithSymbol(revenus), Colors.white),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white30,
                ),
                _buildStatColumn('Dépenses', formatCurrencyWithSymbol(depenses), Colors.white),
              ],
            ),
            const Divider(color: Colors.white30, height: 24),
            _buildStatRow(
              'Balance',
              formatCurrencyWithSymbol(balance.abs()),
              isPositive ? Colors.green.shade300 : Colors.white,
              isPositive ? Icons.trending_up : Icons.trending_down,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}