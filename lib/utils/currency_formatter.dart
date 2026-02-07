import 'package:intl/intl.dart';

/// Utility class for consistent currency formatting throughout the app
/// Uses French locale for proper thousands separator (space: 25 000 FCFA)
class CurrencyFormatter {
  static final _formatter = NumberFormat('#,##0', 'fr_FR');

  /// Format a number as currency with thousands separator
  /// Example: 25000 -> "25 000"
  static String format(num amount) {
    try {
      return _formatter.format(amount);
    } catch (e) {
      return amount.toStringAsFixed(0);
    }
  }

  /// Format amount with FCFA suffix
  /// Example: 25000 -> "25 000 FCFA"
  static String formatWithCurrency(num amount) {
    return '${format(amount)} FCFA';
  }

  /// Format amount with sign and FCFA suffix
  /// Example: 25000 -> "+25 000 FCFA" (for income)
  /// Example: -25000 -> "-25 000 FCFA" (for expenses)
  static String formatWithSign(num amount) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${formatWithCurrency(amount)}';
  }
}
