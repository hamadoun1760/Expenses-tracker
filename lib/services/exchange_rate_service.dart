import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _prefsKey = 'exchange_rates';
  static const String _lastUpdateKey = 'last_exchange_update';
  static const Duration _cacheExpiry = Duration(hours: 1);

  static Map<String, double> _cachedRates = {};
  static DateTime? _lastUpdate;

  /// Get exchange rate from base currency to target currency
  static Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    try {
      await _loadCachedRates();
      
      // Check if cache is valid
      if (_lastUpdate != null && 
          DateTime.now().difference(_lastUpdate!) < _cacheExpiry &&
          _cachedRates.isNotEmpty) {
        return _calculateRate(fromCurrency, toCurrency);
      }

      // Fetch new rates
      await _fetchExchangeRates();
      return _calculateRate(fromCurrency, toCurrency);
    } catch (e) {
      // Fallback to cached rates even if expired
      if (_cachedRates.isNotEmpty) {
        return _calculateRate(fromCurrency, toCurrency);
      }
      // If no cache available, return 1.0 as fallback
      return 1.0;
    }
  }

  /// Convert amount from one currency to another
  static Future<double> convertAmount(
    double amount, 
    String fromCurrency, 
    String toCurrency
  ) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  /// Get all available exchange rates for a base currency
  static Future<Map<String, double>> getAllRates(String baseCurrency) async {
    try {
      await _loadCachedRates();
      
      if (_lastUpdate != null && 
          DateTime.now().difference(_lastUpdate!) < _cacheExpiry &&
          _cachedRates.isNotEmpty) {
        return _getRelativeRates(baseCurrency);
      }

      await _fetchExchangeRates();
      return _getRelativeRates(baseCurrency);
    } catch (e) {
      return _getRelativeRates(baseCurrency);
    }
  }

  static double _calculateRate(String fromCurrency, String toCurrency) {
    // All rates are stored relative to USD
    final fromRate = _cachedRates[fromCurrency] ?? 1.0;
    final toRate = _cachedRates[toCurrency] ?? 1.0;
    
    if (fromCurrency == 'USD') {
      return toRate;
    } else if (toCurrency == 'USD') {
      return 1.0 / fromRate;
    } else {
      return toRate / fromRate;
    }
  }

  static Map<String, double> _getRelativeRates(String baseCurrency) {
    final Map<String, double> relativeRates = {};
    
    for (final currency in SupportedCurrencies.all) {
      if (currency.code != baseCurrency) {
        relativeRates[currency.code] = _calculateRate(baseCurrency, currency.code);
      }
    }
    
    return relativeRates;
  }

  static Future<void> _fetchExchangeRates() async {
    try {
      // Use USD as base currency for the API
      final response = await http.get(
        Uri.parse('$_baseUrl/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedRates = Map<String, double>.from(data['rates']);
        _cachedRates['USD'] = 1.0; // Add USD as base
        _lastUpdate = DateTime.now();
        
        await _saveCachedRates();
      } else {
        throw Exception('Failed to fetch exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      // If API fails, use fallback rates for basic conversion
      _setFallbackRates();
    }
  }

  static void _setFallbackRates() {
    // Basic fallback rates (these should be updated periodically)
    _cachedRates = {
      'USD': 1.0,
      'EUR': 0.85,
      'GBP': 0.73,
      'XAF': 590.0,  // Central African CFA Franc
      'XOF': 590.0,  // West African CFA Franc
      'NGN': 750.0,  // Nigerian Naira
      'ZAR': 18.5,   // South African Rand
      'JPY': 150.0,  // Japanese Yen
      'CNY': 7.3,    // Chinese Yuan
      'INR': 83.0,   // Indian Rupee
      'CAD': 1.35,   // Canadian Dollar
      'AUD': 1.55,   // Australian Dollar
      'CHF': 0.92,   // Swiss Franc
      'BRL': 5.1,    // Brazilian Real
      'EGP': 31.0,   // Egyptian Pound
      'MAD': 10.1,   // Moroccan Dirham
      'KES': 160.0,  // Kenyan Shilling
      'GHS': 12.0,   // Ghanaian Cedi
      'UGX': 3700.0, // Ugandan Shilling
      'TZS': 2500.0, // Tanzanian Shilling
    };
    _lastUpdate = DateTime.now();
  }

  static Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_prefsKey);
      final lastUpdateMillis = prefs.getInt(_lastUpdateKey);
      
      if (ratesJson != null && lastUpdateMillis != null) {
        _cachedRates = Map<String, double>.from(json.decode(ratesJson));
        _lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
      }
    } catch (e) {
      _cachedRates = {};
      _lastUpdate = null;
    }
  }

  static Future<void> _saveCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json.encode(_cachedRates));
      await prefs.setInt(_lastUpdateKey, _lastUpdate!.millisecondsSinceEpoch);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Clear cached exchange rates (useful for testing or manual refresh)
  static Future<void> clearCache() async {
    _cachedRates = {};
    _lastUpdate = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get the last update time for exchange rates
  static DateTime? get lastUpdateTime => _lastUpdate;

  /// Check if exchange rates are cached and valid
  static bool get isCacheValid =>
      _lastUpdate != null && 
      DateTime.now().difference(_lastUpdate!) < _cacheExpiry &&
      _cachedRates.isNotEmpty;
}