import 'package:url_launcher/url_launcher.dart';
import '../utils/currency_formatter.dart';

/// Service for WhatsApp integration
/// Allows users to send reminders and messages to contacts via WhatsApp
class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  /// Send a debt reminder via WhatsApp
  /// [phoneNumber]: Contact's phone number (format: +243xxxxxxxxx)
  /// [name]: Contact's name
  /// [amount]: Debt amount
  /// [description]: Debt description/title
  Future<void> sendDebtReminder({
    required String phoneNumber,
    required String name,
    required double amount,
    required String description,
  }) async {
    final message = _buildDebtReminderMessage(
      name: name,
      amount: amount,
      description: description,
    );
    
    await sendMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Send income reminder (money owed to user) via WhatsApp
  /// [phoneNumber]: Contact's phone number (format: +243xxxxxxxxx)
  /// [name]: Contact's name
  /// [amount]: Amount owed to user
  /// [description]: Income description/title
  Future<void> sendIncomeReminder({
    required String phoneNumber,
    required String name,
    required double amount,
    required String description,
  }) async {
    final message = _buildIncomeReminderMessage(
      name: name,
      amount: amount,
      description: description,
    );
    
    await sendMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Send a custom message via WhatsApp
  /// [phoneNumber]: Contact's phone number (format: +243xxxxxxxxx)
  /// [message]: Custom message to send
  Future<void> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number - remove any spaces, dashes, or parentheses
      final cleanedPhone = _cleanPhoneNumber(phoneNumber);
      
      // Create WhatsApp URL
      // Format: https://wa.me/{phone_number}?text={message}
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$cleanedPhone?text=$encodedMessage';
      
      // Try to launch URL
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch WhatsApp. Make sure WhatsApp is installed.');
      }
    } catch (e) {
      throw Exception('Error opening WhatsApp: ${e.toString()}');
    }
  }

  /// Build financial summary message (for groups or export)
  /// Formats a summary of financial data to share via WhatsApp
  String buildFinancialSummary({
    required double totalExpenses,
    required double totalIncomes,
  }) {
    final netIncome = totalIncomes - totalExpenses;
    final sign = netIncome >= 0 ? '+' : '';
    
    return '''📊 Résumé Financier

💰 Revenus: ${CurrencyFormatter.formatWithCurrency(totalIncomes)}
💸 Dépenses: ${CurrencyFormatter.formatWithCurrency(totalExpenses)}
📈 Solde Net: $sign${CurrencyFormatter.formatWithCurrency(netIncome)}''';
  }

  /// Build debt reminder message
  String _buildDebtReminderMessage({
    required String name,
    required double amount,
    required String description,
  }) {
    return '''Salut $name, 👋

Je t'envoie ce petit rappel pour le reliquat de ${CurrencyFormatter.formatWithCurrency(amount)} FCFA concernant "$description". 

Merci de régulariser au plus vite! 🙏

#AppExpensesTracking''';
  }

  /// Build income reminder message (money owed to user)
  String _buildIncomeReminderMessage({
    required String name,
    required double amount,
    required String description,
  }) {
    return '''Salut $name, 👋

Juste un petit rappel: tu me dois ${CurrencyFormatter.formatWithCurrency(amount)} FCFA pour "$description".

Quand peux-tu me rembourser? Merci! 🙏

#AppExpensesTracking''';
  }

  /// Clean phone number - remove spaces, dashes, parentheses, and plus sign formatting
  /// Convert to format: 243xxxxxxxxx (without +)
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except leading +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Remove leading + if present
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    
    // If number starts with 0, replace with country code (243 for DRC)
    if (cleaned.startsWith('0')) {
      cleaned = '243${cleaned.substring(1)}';
    }
    
    // If it's just digits without country code, add 243
    if (!cleaned.startsWith('243') && !cleaned.startsWith('+')) {
      cleaned = '243$cleaned';
    }
    
    return cleaned;
  }
}
