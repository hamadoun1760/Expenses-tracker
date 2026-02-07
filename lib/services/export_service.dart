import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense.dart';
import '../models/income.dart';
import '../helpers/database_helper.dart';
import '../utils/currency_formatter.dart';

// Export formats
enum ExportFormat { csv, pdf }

// Export types
enum ExportType { expenses, income, all }

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Clean special characters from text
  String _cleanText(String? text) {
    if (text == null || text.isEmpty) return '';
    
    return text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(',', ' ')
        .replaceAll(';', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();
  }

  // Export data with options
  Future<String?> exportData({
    required ExportFormat format,
    required ExportType type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
  }) async {
    try {
      String filename;
      String content;
      
      // final dateFormatter = DateFormat('yyyy-MM-dd'); // Commented out unused variable
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      
      switch (type) {
        case ExportType.expenses:
          final expenses = await _getFilteredExpenses(startDate, endDate, categories);
          filename = 'expenses_export_$timestamp.${format.name}';
          content = format == ExportFormat.csv 
            ? _generateExpensesCsv(expenses) 
            : '';
          if (format == ExportFormat.pdf) {
            return await _generateExpensesPdf(expenses, filename);
          }
          break;
        case ExportType.income:
          final incomes = await _getFilteredIncomes(startDate, endDate, categories);
          filename = 'income_export_$timestamp.${format.name}';
          content = format == ExportFormat.csv 
            ? _generateIncomesCsv(incomes) 
            : '';
          if (format == ExportFormat.pdf) {
            return await _generateIncomesPdf(incomes, filename);
          }
          break;
        case ExportType.all:
          final expenses = await _getFilteredExpenses(startDate, endDate);
          final incomes = await _getFilteredIncomes(startDate, endDate);
          filename = 'financial_data_export_$timestamp.${format.name}';
          content = format == ExportFormat.csv 
            ? _generateAllDataCsv(expenses, incomes) 
            : '';
          if (format == ExportFormat.pdf) {
            return await _generateAllDataPdf(expenses, incomes, filename);
          }
          break;
      }

      return await _saveAndShareFile(filename, content);
    } catch (e) {
      throw Exception('Erreur lors de l\'exportation: $e');
    }
  }

  // Get filtered expenses
  Future<List<Expense>> _getFilteredExpenses(DateTime? startDate, DateTime? endDate, [List<String>? categories]) async {
    final expenses = await _databaseHelper.getExpenses();
    return expenses.where((expense) {
      bool dateFilter = true;
      bool categoryFilter = true;
      
      if (startDate != null && endDate != null) {
        dateFilter = expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                    expense.date.isBefore(endDate.add(const Duration(days: 1)));
      }
      
      if (categories != null && categories.isNotEmpty) {
        categoryFilter = categories.contains(expense.category);
      }
      
      return dateFilter && categoryFilter;
    }).toList();
  }

  // Get filtered incomes
  Future<List<Income>> _getFilteredIncomes(DateTime? startDate, DateTime? endDate, [List<String>? categories]) async {
    final incomes = await _databaseHelper.getIncomes();
    return incomes.where((income) {
      bool dateFilter = true;
      bool categoryFilter = true;
      
      if (startDate != null && endDate != null) {
        dateFilter = income.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                    income.date.isBefore(endDate.add(const Duration(days: 1)));
      }
      
      if (categories != null && categories.isNotEmpty) {
        categoryFilter = categories.contains(income.category);
      }
      
      return dateFilter && categoryFilter;
    }).toList();
  }

  // Generate Expenses CSV
  String _generateExpensesCsv(List<Expense> expenses) {
    final List<List<String>> csvData = [
      ['Date', 'Titre', 'Montant (FCFA)', 'Categorie', 'Description'], // Header
    ];

    for (final expense in expenses) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        _cleanText(expense.title),
        CurrencyFormatter.format(expense.amount),
        _cleanText(expense.category),
        _cleanText(expense.description),
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  // Generate Income CSV
  String _generateIncomesCsv(List<Income> incomes) {
    final List<List<String>> csvData = [
      ['Date', 'Titre', 'Montant (FCFA)', 'Categorie', 'Description'], // Header
    ];

    for (final income in incomes) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(income.date),
        _cleanText(income.title),
        CurrencyFormatter.format(income.amount),
        _cleanText(income.category),
        _cleanText(income.description),
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  // Generate All Data CSV
  String _generateAllDataCsv(List<Expense> expenses, List<Income> incomes) {
    final List<List<String>> csvData = [
      ['Date', 'Type', 'Titre', 'Montant (FCFA)', 'Categorie', 'Description'], // Header
    ];

    // Add expenses
    for (final expense in expenses) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        'Depense',
        _cleanText(expense.title),
        '-${CurrencyFormatter.format(expense.amount)}', // Negative for expenses
        _cleanText(expense.category),
        _cleanText(expense.description),
      ]);
    }

    // Add incomes
    for (final income in incomes) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(income.date),
        'Revenu',
        _cleanText(income.title),
        '+${CurrencyFormatter.format(income.amount)}', // Positive for income
        _cleanText(income.category),
        _cleanText(income.description),
      ]);
    }

    // Sort by date
    csvData.sort((a, b) {
      if (a == csvData.first) return -1; // Keep header first
      if (b == csvData.first) return 1;
      return DateTime.parse(b[0]).compareTo(DateTime.parse(a[0])); // Most recent first
    });

    return const ListToCsvConverter().convert(csvData);
  }

  // Generate Expenses PDF
  Future<String> _generateExpensesPdf(List<Expense> expenses, String filename) async {
    final pdf = pw.Document();
    final totalAmount = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RAPPORT DE DEPENSES',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Genere le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('NOMBRE DE TRANSACTIONS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${expenses.length}'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL DEPENSES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${CurrencyFormatter.formatWithCurrency(totalAmount)}', style: pw.TextStyle(color: PdfColors.red)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
              headers: ['Date', 'Titre', 'Montant (FCFA)', 'Categorie'],
              data: expenses.map((expense) => [
                DateFormat('dd/MM/yyyy').format(expense.date),
                _cleanText(expense.title),
                CurrencyFormatter.format(expense.amount),
                _cleanText(expense.category),
              ]).toList(),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Rapport de depenses');
    return file.path;
  }

  // Generate Income PDF
  Future<String> _generateIncomesPdf(List<Income> incomes, String filename) async {
    final pdf = pw.Document();
    final totalAmount = incomes.fold<double>(0, (sum, income) => sum + income.amount);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RAPPORT DE REVENUS',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Genere le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('NOMBRE DE TRANSACTIONS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${incomes.length}'),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL REVENUS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${CurrencyFormatter.formatWithCurrency(totalAmount)}', style: pw.TextStyle(color: PdfColors.green)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
              headers: ['Date', 'Titre', 'Montant (FCFA)', 'Categorie'],
              data: incomes.map((income) => [
                DateFormat('dd/MM/yyyy').format(income.date),
                _cleanText(income.title),
                CurrencyFormatter.format(income.amount),
                _cleanText(income.category),
              ]).toList(),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Rapport de revenus');
    return file.path;
  }

  // Generate All Data PDF
  Future<String> _generateAllDataPdf(List<Expense> expenses, List<Income> incomes, String filename) async {
    final pdf = pw.Document();
    final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalIncomes = incomes.fold<double>(0, (sum, income) => sum + income.amount);
    final netIncome = totalIncomes - totalExpenses;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RAPPORT FINANCIER COMPLET',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Genere le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('REVENUS TOTAUX:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${CurrencyFormatter.formatWithCurrency(totalIncomes)}', style: pw.TextStyle(color: PdfColors.green)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('DEPENSES TOTALES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${CurrencyFormatter.formatWithCurrency(totalExpenses)}', style: pw.TextStyle(color: PdfColors.red)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('SOLDE NET:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text('${CurrencyFormatter.formatWithCurrency(netIncome)}', 
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, 
                          fontSize: 16,
                          color: netIncome >= 0 ? PdfColors.green : PdfColors.red
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            // Combined transactions table
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
              headers: ['Date', 'Type', 'Titre', 'Montant (FCFA)', 'Categorie'],
              data: [
                // Add expenses
                ...expenses.map((expense) => [
                  DateFormat('dd/MM/yyyy').format(expense.date),
                  'Depense',
                  _cleanText(expense.title),
                  '-${CurrencyFormatter.format(expense.amount)}',
                  _cleanText(expense.category),
                ]),
                // Add incomes
                ...incomes.map((income) => [
                  DateFormat('dd/MM/yyyy').format(income.date),
                  'Revenu',
                  _cleanText(income.title),
                  '+${CurrencyFormatter.format(income.amount)}',
                  _cleanText(income.category),
                ]),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Rapport financier complet');
    return file.path;
  }

  // Save file and share
  Future<String> _saveAndShareFile(String filename, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    
    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Export des données financières - Expenses Tracking',
    );
    
    return file.path;
  }

  // Get export summary
  Future<Map<String, dynamic>> getExportSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenses = await _getFilteredExpenses(startDate, endDate);
    final incomes = await _getFilteredIncomes(startDate, endDate);
    
    final double totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final double totalIncomes = incomes.fold<double>(0, (sum, income) => sum + income.amount);
    
    return {
      'expenses_count': expenses.length,
      'incomes_count': incomes.length,
      'total_expenses': totalExpenses,
      'total_incomes': totalIncomes,
      'net_income': totalIncomes - totalExpenses,
      'date_range': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
    };
  }
}