import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/budget.dart';
import '../helpers/database_helper.dart';

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  factory ExportImportService() => _instance;
  ExportImportService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Export expenses to CSV
  Future<String?> exportExpensesToCSV({List<Expense>? expenses}) async {
    try {
      final expensesList = expenses ?? await _databaseHelper.getExpenses();
      
      if (expensesList.isEmpty) {
        throw Exception('Aucune dépense à exporter');
      }

      final List<List<dynamic>> csvData = [
        ['ID', 'Titre', 'Montant', 'Catégorie', 'Date', 'Description'], // Headers in French
      ];

      for (final expense in expensesList) {
        csvData.add([
          expense.id ?? '',
          expense.title,
          expense.amount,
          expense.category,
          DateFormat('dd/MM/yyyy').format(expense.date),
          expense.description ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      
      if (kIsWeb) {
        return csvString;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        final fileName = 'depenses_$timestamp.csv';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsString(csvString, encoding: utf8);
        
        return filePath;
      }
    } catch (e) {
      print('Erreur lors de l\'export CSV: $e');
      return null;
    }
  }

  // Export budgets to CSV
  Future<String?> exportBudgetsToCSV({List<Budget>? budgets}) async {
    try {
      final budgetsList = budgets ?? await _databaseHelper.getBudgets();
      
      if (budgetsList.isEmpty) {
        throw Exception('Aucun budget à exporter');
      }

      final List<List<dynamic>> csvData = [
        ['ID', 'Catégorie', 'Montant', 'Période', 'Date de création', 'Date de mise à jour'], // Headers in French
      ];

      for (final budget in budgetsList) {
        csvData.add([
          budget.id ?? '',
          budget.category,
          budget.amount,
          budget.period,
          DateFormat('dd/MM/yyyy').format(budget.createdDate),
          budget.updatedDate != null 
              ? DateFormat('dd/MM/yyyy').format(budget.updatedDate!) 
              : '',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      
      if (kIsWeb) {
        return csvString;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        final fileName = 'budgets_$timestamp.csv';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsString(csvString, encoding: utf8);
        
        return filePath;
      }
    } catch (e) {
      print('Erreur lors de l\'export CSV des budgets: $e');
      return null;
    }
  }

  // Share exported file
  Future<void> shareFile(String filePath, String title) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: title);
    } catch (e) {
      print('Erreur lors du partage: $e');
    }
  }

  // Import expenses from CSV
  Future<ImportResult> importExpensesFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'Aucun fichier sélectionné');
      }

      final file = result.files.first;
      String csvContent;

      if (kIsWeb) {
        if (file.bytes == null) {
          return ImportResult(success: false, message: 'Impossible de lire le fichier');
        }
        csvContent = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) {
          return ImportResult(success: false, message: 'Chemin du fichier invalide');
        }
        final fileObj = File(file.path!);
        csvContent = await fileObj.readAsString(encoding: utf8);
      }

      final csvData = const CsvToListConverter().convert(csvContent);
      
      if (csvData.isEmpty) {
        return ImportResult(success: false, message: 'Le fichier CSV est vide');
      }

      // Skip header row
      final dataRows = csvData.skip(1);
      final List<Expense> expenses = [];
      int errorCount = 0;

      for (int i = 0; i < dataRows.length; i++) {
        try {
          final row = dataRows.elementAt(i);
          if (row.length < 5) {
            errorCount++;
            continue;
          }

          final expense = Expense(
            title: row[1].toString().trim(),
            amount: double.parse(row[2].toString()),
            category: row[3].toString().trim(),
            date: DateFormat('dd/MM/yyyy').parse(row[4].toString().trim()),
            description: row.length > 5 ? row[5]?.toString().trim() : null,
          );

          await _databaseHelper.insertExpense(expense);
          expenses.add(expense);
        } catch (e) {
          errorCount++;
          print('Erreur ligne ${i + 2}: $e');
        }
      }

      final successCount = expenses.length;
      String message = 'Importé avec succès: $successCount dépenses';
      if (errorCount > 0) {
        message += ', $errorCount erreurs';
      }

      return ImportResult(
        success: true,
        message: message,
        importedCount: successCount,
        errorCount: errorCount,
      );
    } catch (e) {
      print('Erreur lors de l\'import CSV: $e');
      return ImportResult(
        success: false, 
        message: 'Erreur lors de l\'import: ${e.toString()}',
      );
    }
  }

  // Export full data as JSON (backup)
  Future<String?> exportFullBackup() async {
    try {
      final expenses = await _databaseHelper.getExpenses();
      final budgets = await _databaseHelper.getBudgets();

      final backupData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
      };

      final jsonString = jsonEncode(backupData);

      if (kIsWeb) {
        return jsonString;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        final fileName = 'sauvegarde_complete_$timestamp.json';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsString(jsonString, encoding: utf8);
        
        return filePath;
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde complète: $e');
      return null;
    }
  }

  // Import full backup from JSON
  Future<ImportResult> importFullBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'Aucun fichier sélectionné');
      }

      final file = result.files.first;
      String jsonContent;

      if (kIsWeb) {
        if (file.bytes == null) {
          return ImportResult(success: false, message: 'Impossible de lire le fichier');
        }
        jsonContent = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) {
          return ImportResult(success: false, message: 'Chemin du fichier invalide');
        }
        final fileObj = File(file.path!);
        jsonContent = await fileObj.readAsString(encoding: utf8);
      }

      final backupData = jsonDecode(jsonContent);

      // Validate backup format
      if (!backupData.containsKey('version') || 
          !backupData.containsKey('expenses') || 
          !backupData.containsKey('budgets')) {
        return ImportResult(success: false, message: 'Format de sauvegarde invalide');
      }

      int expenseCount = 0;
      int budgetCount = 0;
      int errorCount = 0;

      // Import expenses
      final expensesData = backupData['expenses'] as List;
      for (final expenseMap in expensesData) {
        try {
          final expense = Expense.fromMap(expenseMap);
          await _databaseHelper.insertExpense(expense);
          expenseCount++;
        } catch (e) {
          errorCount++;
          print('Erreur import dépense: $e');
        }
      }

      // Import budgets
      final budgetsData = backupData['budgets'] as List;
      for (final budgetMap in budgetsData) {
        try {
          final budget = Budget.fromMap(budgetMap);
          await _databaseHelper.insertBudget(budget);
          budgetCount++;
        } catch (e) {
          errorCount++;
          print('Erreur import budget: $e');
        }
      }

      String message = 'Sauvegarde restaurée: $expenseCount dépenses, $budgetCount budgets';
      if (errorCount > 0) {
        message += ', $errorCount erreurs';
      }

      return ImportResult(
        success: true,
        message: message,
        importedCount: expenseCount + budgetCount,
        errorCount: errorCount,
      );
    } catch (e) {
      print('Erreur lors de l\'import de sauvegarde: $e');
      return ImportResult(
        success: false,
        message: 'Erreur lors de l\'import: ${e.toString()}',
      );
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int errorCount;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.errorCount = 0,
  });
}