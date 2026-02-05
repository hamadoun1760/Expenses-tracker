import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../models/expense.dart';
import '../models/income.dart';

class CsvExportHelper {
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static String _sanitizeText(String? text) {
    if (text == null || text.isEmpty) return '';
    // Remove special characters that might cause issues in CSV
    return text
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('"', '""')
        .trim();
  }

  static String _getCategoryInFrench(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return 'Alimentation';
      case 'transportation':
        return 'Transport';
      case 'entertainment':
        return 'Divertissement';
      case 'shopping':
        return 'Shopping';
      case 'health':
        return 'Santé';
      case 'education':
        return 'Éducation';
      case 'bills':
        return 'Factures';
      case 'other':
        return 'Autre';
      default:
        return category;
    }
  }

  static Future<String?> exportExpensesToCsv(List<Expense> expenses) async {
    try {
      if (!await requestStoragePermission()) {
        throw Exception('Permission de stockage refusée');
      }

      final List<List<String>> csvData = [
        ['Date', 'Titre', 'Montant', 'Catégorie', 'Description'],
      ];

      for (final expense in expenses) {
        csvData.add([
          '${expense.date.day.toString().padLeft(2, '0')}/${expense.date.month.toString().padLeft(2, '0')}/${expense.date.year}',
          _sanitizeText(expense.title),
          '${expense.amount.toStringAsFixed(2)} €',
          _getCategoryInFrench(expense.category),
          _sanitizeText(expense.description ?? ''),
        ]);
      }

      final String csvString = const ListToCsvConverter().convert(csvData);

      // Create file path
      final downloadsPath = Platform.isAndroid 
          ? '/storage/emulated/0/Download'
          : '/Users/${Platform.environment['HOME'] ?? 'user'}/Downloads';
      
      final fileName = 'depenses_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = path.join(downloadsPath, fileName);

      final file = File(filePath);
      await file.writeAsString(csvString, encoding: utf8);

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'exportation CSV: $e');
      }
      rethrow;
    }
  }

  static Future<String?> exportIncomesToCsv(List<Income> incomes) async {
    try {
      if (!await requestStoragePermission()) {
        throw Exception('Permission de stockage refusée');
      }

      final List<List<String>> csvData = [
        ['Date', 'Titre', 'Montant', 'Catégorie', 'Description'],
      ];

      for (final income in incomes) {
        csvData.add([
          '${income.date.day.toString().padLeft(2, '0')}/${income.date.month.toString().padLeft(2, '0')}/${income.date.year}',
          _sanitizeText(income.title),
          '${income.amount.toStringAsFixed(2)} €',
          _sanitizeText(income.category),
          _sanitizeText(income.description ?? ''),
        ]);
      }

      final String csvString = const ListToCsvConverter().convert(csvData);

      // Create file path
      final downloadsPath = Platform.isAndroid 
          ? '/storage/emulated/0/Download'
          : '/Users/${Platform.environment['HOME'] ?? 'user'}/Downloads';
      
      final fileName = 'revenus_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = path.join(downloadsPath, fileName);

      final file = File(filePath);
      await file.writeAsString(csvString, encoding: utf8);

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'exportation CSV: $e');
      }
      rethrow;
    }
  }
}