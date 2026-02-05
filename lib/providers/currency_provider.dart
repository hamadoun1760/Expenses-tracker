import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  Currency? _defaultCurrency;
  Currency? _displayCurrency;
  bool _showCurrencySymbol = true;

  Currency? get defaultCurrency => _defaultCurrency;
  Currency? get displayCurrency => _displayCurrency;
  bool get showCurrencySymbol => _showCurrencySymbol;

  CurrencyProvider() {
    _loadCurrencySettings();
  }

  Future<void> _loadCurrencySettings() async {
    try {
      _defaultCurrency = await CurrencyService.getDefaultCurrency();
      _displayCurrency = await CurrencyService.getDisplayCurrency();
      _showCurrencySymbol = await CurrencyService.getShowCurrencySymbol();
      
      notifyListeners();
    } catch (e) {
      // Handle error, keep defaults
      _defaultCurrency = SupportedCurrencies.defaultCurrency;
      _displayCurrency = SupportedCurrencies.defaultCurrency;
    }
  }

  Future<void> setDefaultCurrency(Currency currency) async {
    _defaultCurrency = currency;
    await CurrencyService.setDefaultCurrency(currency);
    notifyListeners();
  }

  Future<void> setDisplayCurrency(Currency currency) async {
    _displayCurrency = currency;
    await CurrencyService.setDisplayCurrency(currency);
    notifyListeners();
  }

  Future<void> setShowCurrencySymbol(bool showSymbol) async {
    _showCurrencySymbol = showSymbol;
    await CurrencyService.setShowCurrencySymbol(showSymbol);
    notifyListeners();
  }

  /// Format an amount using the current display currency and user preferences
  String formatAmount(double amount, {Currency? currency}) {
    final currencyToUse = currency ?? _displayCurrency ?? _defaultCurrency ?? SupportedCurrencies.defaultCurrency;
    return CurrencyService.formatAmountWithCurrency(amount, currencyToUse, useSymbol: _showCurrencySymbol);
  }

  /// Parse an amount string to double
  double parseAmount(String amountText) {
    return CurrencyService.parseAmount(amountText);
  }
}