class Currency {
  final String code;
  final String name;
  final String symbol;
  final String locale;
  final int decimalPlaces;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
    this.decimalPlaces = 2,
  });

  @override
  String toString() => '$code ($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class SupportedCurrencies {
  static const List<Currency> all = [
    // African Currencies
    Currency(
      code: 'XAF',
      name: 'Central African CFA Franc',
      symbol: 'FCFA',
      locale: 'fr_CM',
      decimalPlaces: 0,
    ),
    Currency(
      code: 'XOF',
      name: 'West African CFA Franc',
      symbol: 'FCFA',
      locale: 'fr_SN',
      decimalPlaces: 0,
    ),
    Currency(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      locale: 'en_NG',
    ),
    Currency(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      locale: 'en_ZA',
    ),
    Currency(
      code: 'EGP',
      name: 'Egyptian Pound',
      symbol: 'E£',
      locale: 'ar_EG',
    ),
    Currency(
      code: 'MAD',
      name: 'Moroccan Dirham',
      symbol: 'د.م.',
      locale: 'ar_MA',
    ),
    Currency(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      locale: 'en_KE',
    ),
    Currency(
      code: 'GHS',
      name: 'Ghanaian Cedi',
      symbol: '₵',
      locale: 'en_GH',
    ),
    Currency(
      code: 'UGX',
      name: 'Ugandan Shilling',
      symbol: 'USh',
      locale: 'en_UG',
      decimalPlaces: 0,
    ),
    Currency(
      code: 'TZS',
      name: 'Tanzanian Shilling',
      symbol: 'TSh',
      locale: 'en_TZ',
    ),
    
    // Major International Currencies
    Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      locale: 'en_US',
    ),
    Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      locale: 'fr_FR',
    ),
    Currency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      locale: 'en_GB',
    ),
    Currency(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      locale: 'ja_JP',
      decimalPlaces: 0,
    ),
    Currency(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      locale: 'zh_CN',
    ),
    Currency(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      locale: 'en_IN',
    ),
    Currency(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      locale: 'en_CA',
    ),
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      locale: 'en_AU',
    ),
    Currency(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'Fr.',
      locale: 'de_CH',
    ),
    Currency(
      code: 'BRL',
      name: 'Brazilian Real',
      symbol: 'R\$',
      locale: 'pt_BR',
    ),
  ];

  static Currency? getCurrency(String code) {
    try {
      return all.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  static Currency get defaultCurrency => all.first; // XAF (Central African CFA Franc)
  
  static List<Currency> get africancurrencies => all.where((c) => [
    'XAF', 'XOF', 'NGN', 'ZAR', 'EGP', 'MAD', 'KES', 'GHS', 'UGX', 'TZS'
  ].contains(c.code)).toList();
  
  static List<Currency> get internationalCurrencies => all.where((c) => [
    'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'CAD', 'AUD', 'CHF', 'BRL'
  ].contains(c.code)).toList();
}