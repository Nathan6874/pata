import 'package:intl/intl.dart';

String formatCurrency(int amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return formatter.format(amount);
}

String formatCurrencyWithSymbol(int amount) {
  return '${formatCurrency(amount)} FCFA';
}