import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('fr', '');
  String _dateFormatPreference = 'system';
  String _numberFormatPreference = 'system';

  Locale get currentLocale => _currentLocale;
  String get dateFormatPreference => _dateFormatPreference;
  String get numberFormatPreference => _numberFormatPreference;

  LocaleProvider() {
    _loadLocaleSettings();
  }

  Future<void> _loadLocaleSettings() async {
    try {
      final localeCode = await LocalizationService.getSelectedLocale();
      final dateFormat = await LocalizationService.getDateFormatPreference();
      final numberFormat = await LocalizationService.getNumberFormatPreference();
      
      _currentLocale = Locale(localeCode, '');
      _dateFormatPreference = dateFormat;
      _numberFormatPreference = numberFormat;
      
      notifyListeners();
    } catch (e) {
      // Handle error, keep defaults
    }
  }

  Future<void> setLocale(String localeCode) async {
    _currentLocale = Locale(localeCode, '');
    await LocalizationService.setSelectedLocale(localeCode);
    notifyListeners();
  }

  Future<void> setDateFormatPreference(String format) async {
    _dateFormatPreference = format;
    await LocalizationService.setDateFormatPreference(format);
    notifyListeners();
  }

  Future<void> setNumberFormatPreference(String format) async {
    _numberFormatPreference = format;
    await LocalizationService.setNumberFormatPreference(format);
    notifyListeners();
  }

  /// Format a date according to the user's preference
  String formatDate(DateTime date) {
    try {
      switch (_dateFormatPreference) {
        case 'dmy':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'mdy':
          return DateFormat('MM/dd/yyyy').format(date);
        case 'ymd':
          return DateFormat('yyyy-MM-dd').format(date);
        case 'long':
          return DateFormat('MMMM dd, yyyy').format(date);
        default:
          return DateFormat.yMd(_currentLocale.languageCode).format(date);
      }
    } catch (e) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  /// Format a number according to the user's preference
  String formatNumber(double number) {
    try {
      switch (_numberFormatPreference) {
        case 'comma_dot':
          return NumberFormat('#,##0.00', 'en_US').format(number);
        case 'space_comma':
          return NumberFormat('#,##0.00', 'fr_FR').format(number);
        case 'dot_comma':
          return NumberFormat('#,##0.00', 'de_DE').format(number);
        case 'no_separator':
          return NumberFormat('0.00').format(number);
        default:
          return NumberFormat.decimalPattern(_currentLocale.languageCode).format(number);
      }
    } catch (e) {
      return NumberFormat('#,##0.00').format(number);
    }
  }
}