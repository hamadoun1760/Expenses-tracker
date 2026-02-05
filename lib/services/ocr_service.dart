import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file using Google ML Kit OCR
  static Future<OCRResult> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return _parseReceiptText(recognizedText.text);
    } catch (e) {
      throw OCRException('Erreur lors de la reconnaissance du texte: $e');
    }
  }

  /// Parse the extracted text to identify receipt information
  static OCRResult _parseReceiptText(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // Initialize result
    String? merchant;
    DateTime? date;
    double? totalAmount;
    List<ReceiptItem> items = [];
    String category = 'other';

    // Patterns for parsing
    final amountPattern = RegExp(r'(\d+[,.]?\d*)\s*€?', multiLine: true);
    final datePattern = RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', multiLine: true);
    final totalKeywords = ['total', 'somme', 'montant', 'à payer', 'net à payer'];

    // Extract merchant name (usually one of the first lines)
    if (lines.isNotEmpty) {
      merchant = lines.first.trim();
      // Clean up merchant name
      merchant = merchant.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    }

    // Extract date
    for (final line in lines) {
      final dateMatch = datePattern.firstMatch(line.toLowerCase());
      if (dateMatch != null) {
        date = _parseDate(dateMatch.group(1)!);
        break;
      }
    }

    // Extract total amount
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toLowerCase();
      
      // Check if line contains total keywords
      final containsTotal = totalKeywords.any((keyword) => line.contains(keyword));
      
      if (containsTotal) {
        final amounts = amountPattern.allMatches(line);
        if (amounts.isNotEmpty) {
          final amountStr = amounts.last.group(1)!.replaceAll(',', '.');
          totalAmount = double.tryParse(amountStr);
          break;
        }
      }
    }

    // If no total found with keywords, try to find the largest amount
    if (totalAmount == null) {
      double maxAmount = 0.0;
      for (final line in lines) {
        final amounts = amountPattern.allMatches(line);
        for (final match in amounts) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > maxAmount) {
            maxAmount = amount;
          }
        }
      }
      if (maxAmount > 0) {
        totalAmount = maxAmount;
      }
    }

    // Extract individual items (simplified version)
    for (final line in lines) {
      if (line.length > 3 && line.contains(RegExp(r'\d'))) {
        final amounts = amountPattern.allMatches(line);
        if (amounts.isNotEmpty) {
          final amountStr = amounts.last.group(1)!.replaceAll(',', '.');
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount != totalAmount) {
            // Extract item name (text before the amount)
            final itemName = line.replaceAll(amountPattern, '').trim();
            if (itemName.isNotEmpty) {
              items.add(ReceiptItem(
                name: itemName,
                amount: amount,
              ));
            }
          }
        }
      }
    }

    // Determine category based on merchant name
    category = _categorizeByMerchant(merchant ?? '');

    return OCRResult(
      merchant: merchant,
      date: date ?? DateTime.now(),
      totalAmount: totalAmount,
      items: items,
      category: category,
      rawText: text,
    );
  }

  /// Parse date string to DateTime
  static DateTime? _parseDate(String dateStr) {
    try {
      // Handle different date formats
      final cleanDate = dateStr.replaceAll(RegExp(r'[^\d\/\-\.]'), '');
      final parts = cleanDate.split(RegExp(r'[\/\-\.]'));
      
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        
        // Handle 2-digit years
        if (year < 100) {
          year += (year < 50) ? 2000 : 1900;
        }
        
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  /// Categorize expense based on merchant name
  static String _categorizeByMerchant(String merchant) {
    final merchantLower = merchant.toLowerCase();
    
    // Food and restaurants
    if (merchantLower.contains(RegExp(r'restaurant|cafe|mcdo|burger|pizza|boulang|super|market|carrefour|leclerc|auchan|intermarche'))) {
      return 'food';
    }
    
    // Transportation
    if (merchantLower.contains(RegExp(r'station|essence|total|shell|bp|esso|sncf|ratp|uber|taxi'))) {
      return 'transportation';
    }
    
    // Shopping
    if (merchantLower.contains(RegExp(r'magasin|boutique|store|zara|h&m|fnac|amazon|cdiscount'))) {
      return 'shopping';
    }
    
    // Health
    if (merchantLower.contains(RegExp(r'pharmacie|medecin|hopital|clinique|dentiste'))) {
      return 'health';
    }
    
    // Entertainment
    if (merchantLower.contains(RegExp(r'cinema|theatre|concert|sport|gym|netflix|spotify'))) {
      return 'entertainment';
    }
    
    return 'other';
  }

  /// Dispose of resources
  static void dispose() {
    _textRecognizer.close();
  }
}

class OCRResult {
  final String? merchant;
  final DateTime date;
  final double? totalAmount;
  final List<ReceiptItem> items;
  final String category;
  final String rawText;

  OCRResult({
    required this.merchant,
    required this.date,
    required this.totalAmount,
    required this.items,
    required this.category,
    required this.rawText,
  });

  @override
  String toString() {
    return 'OCRResult(merchant: $merchant, date: $date, totalAmount: $totalAmount, items: ${items.length}, category: $category)';
  }
}

class ReceiptItem {
  final String name;
  final double amount;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
  });

  @override
  String toString() {
    return 'ReceiptItem(name: $name, amount: $amount, quantity: $quantity)';
  }
}

class OCRException implements Exception {
  final String message;
  
  OCRException(this.message);
  
  @override
  String toString() => 'OCRException: $message';
}