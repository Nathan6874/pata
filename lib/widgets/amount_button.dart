import 'package:flutter/material.dart';
import 'package:pata/utils/currency_formatter.dart';

class AmountButton extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  final bool isCompact;

  const AmountButton({
    super.key,
    required this.amount,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isCompact ? 90 : 100,
      height: isCompact ? 60 : 70,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade50,
          foregroundColor: Colors.teal.shade900,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.teal.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatCurrency(amount),
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            if (!isCompact)
              Text(
                'FCFA',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.teal.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}