import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class CurrencyService {
  static const String _defaultCurrencyKey = 'default_currency';
  static const String _displayCurrencyKey = 'display_currency';
  static const String _showCurrencySymbolKey = 'show_currency_symbol';
  
  static Currency? _defaultCurrency;
  static Currency? _displayCurrency;
  static bool _showCurrencySymbol = true;

  /// Get the default currency for the app
  static Future<Currency> getDefaultCurrency() async {
    if (_defaultCurrency != null) return _defaultCurrency!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_defaultCurrencyKey);
      
      if (currencyCode != null) {
        _defaultCurrency = SupportedCurrencies.getCurrency(currencyCode);
      }
      
      _defaultCurrency ??= SupportedCurrencies.defaultCurrency;
      return _defaultCurrency!;
    } catch (e) {
      _defaultCurrency = SupportedCurrencies.defaultCurrency;
      return _defaultCurrency!;
    }
  }

  /// Set the default currency for the app
  static Future<void> setDefaultCurrency(Currency currency) async {
    _defaultCurrency = currency;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultCurrencyKey, currency.code);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Get the display currency (may be different from default for viewing purposes)
  static Future<Currency> getDisplayCurrency() async {
    if (_displayCurrency != null) return _displayCurrency!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_displayCurrencyKey);
      
      if (currencyCode != null) {
        _displayCurrency = SupportedCurrencies.getCurrency(currencyCode);
      }
      
      // Default to the default currency if no display currency is set
      _displayCurrency ??= await getDefaultCurrency();
      return _displayCurrency!;
    } catch (e) {
      _displayCurrency = await getDefaultCurrency();
      return _displayCurrency!;
    }
  }

  /// Set the display currency
  static Future<void> setDisplayCurrency(Currency currency) async {
    _displayCurrency = currency;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_displayCurrencyKey, currency.code);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Get currency symbol display preference
  static Future<bool> getShowCurrencySymbol() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showCurrencySymbol = prefs.getBool(_showCurrencySymbolKey) ?? true;
      return _showCurrencySymbol;
    } catch (e) {
      return true;
    }
  }

  /// Set currency symbol display preference
  static Future<void> setShowCurrencySymbol(bool show) async {
    _showCurrencySymbol = show;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showCurrencySymbolKey, show);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Format amount with currency
  static Future<String> formatAmount(double amount, {Currency? currency, bool useSymbol = true}) async {
    currency ??= await getDisplayCurrency();
    final showSymbol = useSymbol && await getShowCurrencySymbol();
    
    try {
      // Create number format based on currency locale
      final numberFormat = NumberFormat.currency(
        locale: currency.locale,
        symbol: showSymbol ? currency.symbol : '',
        decimalDigits: currency.decimalPlaces,
      );
      
      String formatted = numberFormat.format(amount);
      
      // For currencies that don't use symbols, append currency code
      if (!showSymbol || currency.symbol == currency.code) {
        formatted = '${amount.toStringAsFixed(currency.decimalPlaces)} ${currency.code}';
      }
      
      return formatted;
    } catch (e) {
      // Fallback formatting
      return '${amount.toStringAsFixed(currency.decimalPlaces)} ${showSymbol ? currency.symbol : currency.code}';
    }
  }

  /// Format amount with specific currency (useful for multi-currency display)
  static String formatAmountWithCurrency(double amount, Currency currency, {bool useSymbol = true}) {
    try {
      if (useSymbol && currency.symbol != currency.code) {
        final numberFormat = NumberFormat.currency(
          locale: currency.locale,
          symbol: currency.symbol,
          decimalDigits: currency.decimalPlaces,
        );
        return numberFormat.format(amount);
      } else {
        return '${amount.toStringAsFixed(currency.decimalPlaces)} ${currency.code}';
      }
    } catch (e) {
      // Fallback formatting
      return '${amount.toStringAsFixed(currency.decimalPlaces)} ${useSymbol ? currency.symbol : currency.code}';
    }
  }

  /// Parse amount string to double (handles different decimal separators)
  static double parseAmount(String amountString) {
    try {
      // Remove currency symbols and codes
      String cleanAmount = amountString.trim();
      
      // Remove common currency symbols
      cleanAmount = cleanAmount.replaceAll(RegExp(r'[€\$£¥₹₦₵]'), '');
      
      // Remove currency codes
      for (final currency in SupportedCurrencies.all) {
        cleanAmount = cleanAmount.replaceAll(currency.code, '');
        cleanAmount = cleanAmount.replaceAll(currency.symbol, '');
      }
      
      cleanAmount = cleanAmount.trim();
      
      // Handle different decimal separators
      if (cleanAmount.contains(',') && cleanAmount.contains('.')) {
        // European format: 1.234,56
        if (cleanAmount.lastIndexOf(',') > cleanAmount.lastIndexOf('.')) {
          cleanAmount = cleanAmount.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (cleanAmount.contains(',')) {
        // Could be European decimal: 123,45 or thousands separator: 1,234
        final commaIndex = cleanAmount.lastIndexOf(',');
        final afterComma = cleanAmount.substring(commaIndex + 1);
        
        if (afterComma.length <= 2) {
          // Decimal separator
          cleanAmount = cleanAmount.replaceAll(',', '.');
        } else {
          // Thousands separator
          cleanAmount = cleanAmount.replaceAll(',', '');
        }
      }
      
      return double.parse(cleanAmount);
    } catch (e) {
      return 0.0;
    }
  }

  /// Get currency by code
  static Currency? getCurrencyByCode(String code) {
    return SupportedCurrencies.getCurrency(code);
  }

  /// Get all supported currencies
  static List<Currency> getAllCurrencies() {
    return SupportedCurrencies.all;
  }

  /// Get African currencies
  static List<Currency> getAfricanCurrencies() {
    return SupportedCurrencies.africancurrencies;
  }

  /// Get international currencies
  static List<Currency> getInternationalCurrencies() {
    return SupportedCurrencies.internationalCurrencies;
  }

  /// Reset all currency settings to defaults
  static Future<void> resetToDefaults() async {
    _defaultCurrency = null;
    _displayCurrency = null;
    _showCurrencySymbol = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_defaultCurrencyKey);
      await prefs.remove(_displayCurrencyKey);
      await prefs.remove(_showCurrencySymbolKey);
    } catch (e) {
      // Ignore errors
    }
  }
}