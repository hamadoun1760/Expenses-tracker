import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _localeKey = 'selected_locale';
  static const String _dateFormatKey = 'date_format_preference';
  static const String _numberFormatKey = 'number_format_preference';
  
  static String? _selectedLocale;
  static String? _dateFormatPreference;
  static String? _numberFormatPreference;

  /// Supported locales for the app
  static const List<Map<String, String>> supportedLocales = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'pt', 'name': 'Portuguese', 'nativeName': 'Português'},
    {'code': 'sw', 'name': 'Swahili', 'nativeName': 'Kiswahili'},
  ];

  /// Date format options
  static const List<Map<String, String>> dateFormats = [
    {'code': 'system', 'name': 'System Default', 'example': 'Auto'},
    {'code': 'dmy', 'name': 'DD/MM/YYYY', 'example': '25/01/2026'},
    {'code': 'mdy', 'name': 'MM/DD/YYYY', 'example': '01/25/2026'},
    {'code': 'ymd', 'name': 'YYYY-MM-DD', 'example': '2026-01-25'},
    {'code': 'long', 'name': 'Long Format', 'example': 'January 25, 2026'},
  ];

  /// Number format options
  static const List<Map<String, String>> numberFormats = [
    {'code': 'system', 'name': 'System Default', 'example': 'Auto'},
    {'code': 'comma_dot', 'name': 'Comma Thousands, Dot Decimal', 'example': '1,234.56'},
    {'code': 'space_comma', 'name': 'Space Thousands, Comma Decimal', 'example': '1 234,56'},
    {'code': 'dot_comma', 'name': 'Dot Thousands, Comma Decimal', 'example': '1.234,56'},
    {'code': 'no_separator', 'name': 'No Thousands Separator', 'example': '1234.56'},
  ];

  /// Get selected locale
  static Future<String> getSelectedLocale() async {
    if (_selectedLocale != null) return _selectedLocale!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLocale = prefs.getString(_localeKey) ?? 'fr'; // Default to French for African context
      return _selectedLocale!;
    } catch (e) {
      return 'fr';
    }
  }

  /// Set selected locale
  static Future<void> setSelectedLocale(String locale) async {
    _selectedLocale = locale;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Get date format preference
  static Future<String> getDateFormatPreference() async {
    if (_dateFormatPreference != null) return _dateFormatPreference!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _dateFormatPreference = prefs.getString(_dateFormatKey) ?? 'system';
      return _dateFormatPreference!;
    } catch (e) {
      return 'system';
    }
  }

  /// Set date format preference
  static Future<void> setDateFormatPreference(String format) async {
    _dateFormatPreference = format;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateFormatKey, format);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Get number format preference
  static Future<String> getNumberFormatPreference() async {
    if (_numberFormatPreference != null) return _numberFormatPreference!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _numberFormatPreference = prefs.getString(_numberFormatKey) ?? 'system';
      return _numberFormatPreference!;
    } catch (e) {
      return 'system';
    }
  }

  /// Set number format preference
  static Future<void> setNumberFormatPreference(String format) async {
    _numberFormatPreference = format;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_numberFormatKey, format);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Format date according to user preference
  static Future<String> formatDate(DateTime date) async {
    final format = await getDateFormatPreference();
    final locale = await getSelectedLocale();
    
    try {
      switch (format) {
        case 'dmy':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'mdy':
          return DateFormat('MM/dd/yyyy').format(date);
        case 'ymd':
          return DateFormat('yyyy-MM-dd').format(date);
        case 'long':
          return DateFormat.yMMMMd(locale).format(date);
        case 'system':
        default:
          return DateFormat.yMd(locale).format(date);
      }
    } catch (e) {
      // Fallback to ISO format
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  /// Format time according to locale
  static Future<String> formatTime(DateTime time) async {
    final locale = await getSelectedLocale();
    
    try {
      return DateFormat.Hm(locale).format(time);
    } catch (e) {
      return DateFormat('HH:mm').format(time);
    }
  }

  /// Format date and time
  static Future<String> formatDateTime(DateTime dateTime) async {
    final date = await formatDate(dateTime);
    final time = await formatTime(dateTime);
    return '$date $time';
  }

  /// Format number according to user preference
  static Future<String> formatNumber(double number, {int? decimalPlaces}) async {
    final format = await getNumberFormatPreference();
    final locale = await getSelectedLocale();
    
    try {
      switch (format) {
        case 'comma_dot':
          return NumberFormat('#,##0${decimalPlaces != null ? '.${'0' * decimalPlaces}' : ''}', 'en_US').format(number);
        case 'space_comma':
          return NumberFormat('#,##0${decimalPlaces != null ? ',${'0' * decimalPlaces}' : ''}', 'fr_FR').format(number);
        case 'dot_comma':
          return NumberFormat('#,##0${decimalPlaces != null ? ',${'0' * decimalPlaces}' : ''}', 'de_DE').format(number);
        case 'no_separator':
          return decimalPlaces != null ? number.toStringAsFixed(decimalPlaces) : number.toString();
        case 'system':
        default:
          return NumberFormat('#,##0${decimalPlaces != null ? '.${'0' * decimalPlaces}' : ''}', locale).format(number);
      }
    } catch (e) {
      // Fallback formatting
      return decimalPlaces != null ? number.toStringAsFixed(decimalPlaces) : number.toString();
    }
  }

  /// Parse date string according to user preference
  static Future<DateTime?> parseDate(String dateString) async {
    final format = await getDateFormatPreference();
    
    try {
      switch (format) {
        case 'dmy':
          return DateFormat('dd/MM/yyyy').parse(dateString);
        case 'mdy':
          return DateFormat('MM/dd/yyyy').parse(dateString);
        case 'ymd':
          return DateFormat('yyyy-MM-dd').parse(dateString);
        case 'long':
          return DateFormat.yMMMMd().parse(dateString);
        case 'system':
        default:
          // Try multiple common formats
          final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'dd-MM-yyyy', 'MM-dd-yyyy'];
          for (final fmt in formats) {
            try {
              return DateFormat(fmt).parse(dateString);
            } catch (e) {
              continue;
            }
          }
          return DateTime.tryParse(dateString);
      }
    } catch (e) {
      return DateTime.tryParse(dateString);
    }
  }

  /// Get locale display name
  static String getLocaleDisplayName(String localeCode) {
    final locale = supportedLocales.firstWhere(
      (l) => l['code'] == localeCode,
      orElse: () => {'code': localeCode, 'name': localeCode, 'nativeName': localeCode},
    );
    return locale['nativeName'] ?? locale['name'] ?? localeCode;
  }

  /// Get date format display name
  static String getDateFormatDisplayName(String formatCode) {
    final format = dateFormats.firstWhere(
      (f) => f['code'] == formatCode,
      orElse: () => {'code': formatCode, 'name': formatCode, 'example': ''},
    );
    return format['name'] ?? formatCode;
  }

  /// Get number format display name
  static String getNumberFormatDisplayName(String formatCode) {
    final format = numberFormats.firstWhere(
      (f) => f['code'] == formatCode,
      orElse: () => {'code': formatCode, 'name': formatCode, 'example': ''},
    );
    return format['name'] ?? formatCode;
  }

  /// Check if locale is RTL (Right-to-Left)
  static bool isRTL(String localeCode) {
    return ['ar', 'he', 'fa', 'ur'].contains(localeCode);
  }

  /// Reset all localization settings to defaults
  static Future<void> resetToDefaults() async {
    _selectedLocale = null;
    _dateFormatPreference = null;
    _numberFormatPreference = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localeKey);
      await prefs.remove(_dateFormatKey);
      await prefs.remove(_numberFormatKey);
    } catch (e) {
      // Ignore errors
    }
  }
}