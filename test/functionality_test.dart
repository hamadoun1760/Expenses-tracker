import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_tracking/models/expense.dart';
import 'package:expenses_tracking/helpers/database_helper.dart';
import 'package:expenses_tracking/utils/theme.dart';

void main() {
  group('Expense Model Tests', () {
    test('Expense model creation and serialization', () {
      final expense = Expense(
        id: 1,
        title: 'Test Expense',
        amount: 25.50,
        category: 'food',
        date: DateTime(2026, 1, 24),
        description: 'Test description',
      );

      expect(expense.id, 1);
      expect(expense.title, 'Test Expense');
      expect(expense.amount, 25.50);
      expect(expense.category, 'food');
      expect(expense.description, 'Test description');

      // Test toMap
      final map = expense.toMap();
      expect(map['title'], 'Test Expense');
      expect(map['amount'], 25.50);
      expect(map['category'], 'food');

      // Test fromMap
      final newExpense = Expense.fromMap(map);
      expect(newExpense.title, expense.title);
      expect(newExpense.amount, expense.amount);
      expect(newExpense.category, expense.category);
    });

    test('Expense copyWith method', () {
      final expense = Expense(
        id: 1,
        title: 'Original',
        amount: 10.0,
        category: 'food',
        date: DateTime(2026, 1, 24),
      );

      final updated = expense.copyWith(title: 'Updated', amount: 20.0);
      
      expect(updated.id, 1);
      expect(updated.title, 'Updated');
      expect(updated.amount, 20.0);
      expect(updated.category, 'food');
    });
  });

  group('Category Configuration Tests', () {
    test('Category icons and colors are properly defined', () {
      expect(CategoryConfig.categories.length, 7);
      expect(CategoryConfig.categories.contains('food'), true);
      expect(CategoryConfig.categories.contains('transportation'), true);
      expect(CategoryConfig.categories.contains('shopping'), true);
      
      // Test that all categories have icons and colors
      for (String category in CategoryConfig.categories) {
        expect(CategoryConfig.categoryIcons.containsKey(category), true);
        expect(CategoryConfig.categoryColors.containsKey(category), true);
      }
    });
  });

  group('Database Helper Functionality Tests', () {
    test('Database helper instance creation', () {
      final db1 = DatabaseHelper();
      final db2 = DatabaseHelper();
      expect(identical(db1, db2), true); // Singleton pattern test
    });
  });
}