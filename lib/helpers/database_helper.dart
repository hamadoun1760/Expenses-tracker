import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/income.dart';
import '../models/recurring_transaction.dart';
import '../models/custom_category.dart';
import '../models/custom_debt_type.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../models/debt.dart';
import '../models/notification.dart';
import '../config/category_config.dart';
import '../config/income_config.dart';
import '../services/reminder_manager.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static SharedPreferences? _prefs;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<dynamic> get database async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!;
    } else {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expenses.db');
    return await openDatabase(
      path,
      version: 16, // Added action_type field to notifications table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        account_id INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        created_date TEXT NOT NULL,
        updated_date TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        account_id INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        frequency TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        max_occurrences INTEGER,
        current_occurrences INTEGER DEFAULT 0,
        next_due_date INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');
    
    await db.execute('''
      CREATE TABLE custom_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE custom_debt_types(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL DEFAULT 0.0,
        current_balance REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'FCFA',
        description TEXT,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0.0,
        start_date INTEGER NOT NULL,
        target_date INTEGER NOT NULL,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'active',
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        account_id INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone_number TEXT,
        profile_picture BLOB,
        date_of_birth INTEGER,
        address TEXT,
        bio TEXT,
        default_currency TEXT DEFAULT 'EUR',
        language TEXT DEFAULT 'fr',
        theme TEXT DEFAULT 'system',
        notifications_enabled INTEGER DEFAULT 1,
        biometric_enabled INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        custom_debt_type_id INTEGER,
        original_amount REAL NOT NULL,
        current_balance REAL NOT NULL,
        interest_rate REAL NOT NULL,
        start_date INTEGER NOT NULL,
        target_payoff_date INTEGER,
        minimum_payment REAL NOT NULL,
        strategy TEXT NOT NULL DEFAULT 'snowball',
        status TEXT NOT NULL DEFAULT 'active',
        creditor_name TEXT,
        account_number TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        transaction_type TEXT NOT NULL DEFAULT 'dette',
        contact_name TEXT NOT NULL DEFAULT '',
        contact_phone TEXT,
        echeance INTEGER,
        category TEXT NOT NULL DEFAULT 'autre',
        custom_category_name TEXT,
        FOREIGN KEY (custom_debt_type_id) REFERENCES custom_debt_types (id) ON DELETE SET NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE debt_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date INTEGER NOT NULL,
        description TEXT,
        is_extra_payment INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_read INTEGER DEFAULT 0,
        payload TEXT,
        action_text TEXT,
        action_type TEXT,
        icon TEXT
      )
    ''');
    
    // Insert default categories and accounts
    await _insertDefaultCategories(db);
    await _insertDefaultAccounts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add budgets table for existing databases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          period TEXT NOT NULL,
          created_date TEXT NOT NULL,
          updated_date TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add incomes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS incomes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          description TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add recurring transactions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          frequency TEXT NOT NULL,
          start_date INTEGER NOT NULL,
          end_date INTEGER,
          max_occurrences INTEGER,
          current_occurrences INTEGER DEFAULT 0,
          next_due_date INTEGER NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 5) {
      // Add custom categories table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          icon_name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          is_default INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
      
      // Insert default categories
      await _insertDefaultCategories(db);
    }
    if (oldVersion < 6) {
      // Add accounts table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          initial_balance REAL DEFAULT 0.0,
          current_balance REAL DEFAULT 0.0,
          currency TEXT DEFAULT 'FCFA',
          description TEXT,
          icon_name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
      
      // Insert default accounts
      await _insertDefaultAccounts(db);
    }
    if (oldVersion < 7) {
      // Add account_id columns to existing tables
      try {
        await db.execute('ALTER TABLE expenses ADD COLUMN account_id INTEGER');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE incomes ADD COLUMN account_id INTEGER');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE recurring_transactions ADD COLUMN account_id INTEGER');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 8) {
      // Add goals table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL DEFAULT 0.0,
          start_date INTEGER NOT NULL,
          target_date INTEGER NOT NULL,
          priority TEXT DEFAULT 'medium',
          status TEXT DEFAULT 'active',
          icon_name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          account_id INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
    }
    if (oldVersion < 9) {
      // Add users table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          phone_number TEXT,
          profile_picture BLOB,
          date_of_birth INTEGER,
          address TEXT,
          bio TEXT,
          default_currency TEXT DEFAULT 'EUR',
          language TEXT DEFAULT 'fr',
          theme TEXT DEFAULT 'system',
          notifications_enabled INTEGER DEFAULT 1,
          biometric_enabled INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
    }
    if (oldVersion < 10) {
      // Add debts table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          original_amount REAL NOT NULL,
          current_balance REAL NOT NULL,
          interest_rate REAL NOT NULL,
          start_date INTEGER NOT NULL,
          target_payoff_date INTEGER,
          minimum_payment REAL NOT NULL,
          strategy TEXT NOT NULL DEFAULT 'snowball',
          status TEXT NOT NULL DEFAULT 'active',
          creditor_name TEXT,
          account_number TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
      
      // Add debt payments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          debt_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          payment_date INTEGER NOT NULL,
          description TEXT,
          is_extra_payment INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 11) {
      // Add notifications table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          category TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          is_read INTEGER DEFAULT 0,
          payload TEXT,
          action_text TEXT,
          icon TEXT
        )
      ''');
    }
    if (oldVersion < 12) {
      // Add custom debt types table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_debt_types(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          icon_name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          is_default INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');
    }
    if (oldVersion < 13) {
      // Add custom_debt_type_id column to debts table
      await db.execute('''
        ALTER TABLE debts ADD COLUMN custom_debt_type_id INTEGER
      ''');
    }
    if (oldVersion < 14) {
      // Add West African context fields to debts table
      await db.execute('''
        ALTER TABLE debts ADD COLUMN transaction_type TEXT NOT NULL DEFAULT 'dette'
      ''');
      await db.execute('''
        ALTER TABLE debts ADD COLUMN contact_name TEXT NOT NULL DEFAULT ''
      ''');
      await db.execute('''
        ALTER TABLE debts ADD COLUMN contact_phone TEXT
      ''');
      await db.execute('''
        ALTER TABLE debts ADD COLUMN echeance INTEGER
      ''');
      await db.execute('''
        ALTER TABLE debts ADD COLUMN category TEXT NOT NULL DEFAULT 'autre'
      ''');
    }
    if (oldVersion < 15) {
      // Add custom category name field to debts table
      await db.execute('''
        ALTER TABLE debts ADD COLUMN custom_category_name TEXT
      ''');
    }
    if (oldVersion < 16) {
      // Add action_type field to notifications table
      try {
        await db.execute('''
          ALTER TABLE notifications ADD COLUMN action_type TEXT
        ''');
      } catch (e) {
        // Column might already exist
      }
    }
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final expenses = await _getExpensesFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newExpense = expense.copyWith(id: newId);
      expenses.add(newExpense);
      await _saveExpensesToPrefs(prefs, expenses);
      return newId;
    } else {
      final db = await database as Database;
      return await db.insert('expenses', expense.toMap());
    }
  }

  Future<List<Expense>> getExpenses() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final expenses = await _getExpensesFromPrefs(prefs);
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    }
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    final allExpenses = await getExpenses();
    return allExpenses.where((expense) => expense.category == category).toList();
  }

  Future<double> getTotalExpenses() async {
    final expenses = await getExpenses();
    double total = 0.0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  Future<Map<String, double>> getExpensesByMonth() async {
    final expenses = await getExpenses();
    Map<String, double> monthlyExpenses = {};
    
    for (var expense in expenses) {
      final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0.0) + expense.amount;
    }
    
    return monthlyExpenses;
  }

  Future<int> updateExpense(Expense expense) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final expenses = await _getExpensesFromPrefs(prefs);
      final index = expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        expenses[index] = expense;
        await _saveExpensesToPrefs(prefs, expenses);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    }
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final expenses = await _getExpensesFromPrefs(prefs);
      final initialLength = expenses.length;
      expenses.removeWhere((expense) => expense.id == id);
      await _saveExpensesToPrefs(prefs, expenses);
      return initialLength - expenses.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteAllExpenses() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      await prefs.remove('expenses');
    } else {
      final db = await database as Database;
      await db.delete('expenses');
    }
  }

  // Budget operations
  Future<int> insertBudget(Budget budget) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final budgets = await _getBudgetsFromPrefs(prefs);
      final newBudget = budget.copyWith(
        id: budgets.isEmpty ? 1 : budgets.map((b) => b.id!).reduce((a, b) => a > b ? a : b) + 1,
      );
      budgets.add(newBudget);
      await _saveBudgetsToPrefs(prefs, budgets);
      return newBudget.id!;
    } else {
      final db = await database as Database;
      return await db.insert('budgets', budget.toMap());
    }
  }

  Future<List<Budget>> getBudgets() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getBudgetsFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'budgets',
        orderBy: 'created_date DESC',
      );
      return List.generate(maps.length, (i) {
        return Budget.fromMap(maps[i]);
      });
    }
  }

  Future<Budget?> getBudgetByCategory(String category) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final budgets = await _getBudgetsFromPrefs(prefs);
      return budgets.where((b) => b.category == category).firstOrNull;
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'budgets',
        where: 'category = ?',
        whereArgs: [category],
      );
      if (maps.isNotEmpty) {
        return Budget.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateBudget(Budget budget) async {
    final updatedBudget = budget.copyWith(updatedDate: DateTime.now());
    
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final budgets = await _getBudgetsFromPrefs(prefs);
      final index = budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        budgets[index] = updatedBudget;
        await _saveBudgetsToPrefs(prefs, budgets);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'budgets',
        updatedBudget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    }
  }

  Future<int> deleteBudget(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final budgets = await _getBudgetsFromPrefs(prefs);
      budgets.removeWhere((b) => b.id == id);
      await _saveBudgetsToPrefs(prefs, budgets);
      return 1;
    } else {
      final db = await database as Database;
      return await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Helper methods for web storage
  Future<List<Expense>> _getExpensesFromPrefs(SharedPreferences prefs) async {
    final expensesJson = prefs.getStringList('expenses') ?? [];
    return expensesJson.map((json) => Expense.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveExpensesToPrefs(SharedPreferences prefs, List<Expense> expenses) async {
    final expensesJson = expenses.map((expense) => jsonEncode(expense.toMap())).toList();
    await prefs.setStringList('expenses', expensesJson);
  }

  Future<List<Budget>> _getBudgetsFromPrefs(SharedPreferences prefs) async {
    final budgetsJson = prefs.getStringList('budgets') ?? [];
    return budgetsJson.map((json) => Budget.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveBudgetsToPrefs(SharedPreferences prefs, List<Budget> budgets) async {
    final budgetsJson = budgets.map((budget) => jsonEncode(budget.toMap())).toList();
    await prefs.setStringList('budgets', budgetsJson);
  }

  // Income operations
  Future<int> insertIncome(Income income) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      final newIncome = income.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      incomes.add(newIncome);
      await _saveIncomesToPrefs(prefs, incomes);
      return newIncome.id!;
    } else {
      final db = await database as Database;
      return await db.insert('incomes', income.toMap());
    }
  }

  Future<List<Income>> getIncomes() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getIncomesFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query('incomes', orderBy: 'date DESC');
      return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
    }
  }

  Future<List<Income>> getIncomesByCategory(String category) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      return incomes.where((income) => income.category == category).toList();
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'incomes',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
    }
  }

  Future<double> getTotalIncomes() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      return incomes.fold<double>(0.0, (sum, income) => sum + income.amount);
    } else {
      final db = await database as Database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM incomes');
      return (result.first['total'] as double?) ?? 0.0;
    }
  }

  Future<double> getIncomeByMonth(int year, int month) async {
    String startDate = DateTime(year, month, 1).toIso8601String();
    String endDate = DateTime(year, month + 1, 1).toIso8601String();
    
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      return incomes
          .where((income) => income.date.isAfter(DateTime.parse(startDate)) && 
                 income.date.isBefore(DateTime.parse(endDate)))
          .fold<double>(0.0, (sum, income) => sum + income.amount);
    } else {
      final db = await database as Database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM incomes WHERE date >= ? AND date < ?',
        [startDate, endDate],
      );
      return (result.first['total'] as double?) ?? 0.0;
    }
  }

  Future<Map<String, double>> getIncomesByCategoryGrouped() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      Map<String, double> categoryTotals = {};
      for (var income in incomes) {
        categoryTotals[income.category] = 
            (categoryTotals[income.category] ?? 0.0) + income.amount;
      }
      return categoryTotals;
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM incomes GROUP BY category'
      );
      Map<String, double> categoryTotals = {};
      for (var row in result) {
        categoryTotals[row['category']] = (row['total'] as double?) ?? 0.0;
      }
      return categoryTotals;
    }
  }

  Future<int> updateIncome(Income income) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      final index = incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        incomes[index] = income;
        await _saveIncomesToPrefs(prefs, incomes);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'incomes',
        income.toMap(),
        where: 'id = ?',
        whereArgs: [income.id],
      );
    }
  }

  Future<int> deleteIncome(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final incomes = await _getIncomesFromPrefs(prefs);
      incomes.removeWhere((income) => income.id == id);
      await _saveIncomesToPrefs(prefs, incomes);
      return 1;
    } else {
      final db = await database as Database;
      return await db.delete(
        'incomes',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Helper methods for income web storage
  Future<List<Income>> _getIncomesFromPrefs(SharedPreferences prefs) async {
    final incomesJson = prefs.getStringList('incomes') ?? [];
    return incomesJson.map((json) => Income.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveIncomesToPrefs(SharedPreferences prefs, List<Income> incomes) async {
    final incomesJson = incomes.map((income) => jsonEncode(income.toMap())).toList();
    await prefs.setStringList('incomes', incomesJson);
  }

  // Recurring Transaction CRUD methods
  Future<int> insertRecurringTransaction(RecurringTransaction transaction) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final transactions = await _getRecurringTransactionsFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newTransaction = transaction.copyWith(id: newId);
      transactions.add(newTransaction);
      await _saveRecurringTransactionsToPrefs(prefs, transactions);
      return newId;
    } else {
      final db = await database as Database;
      return await db.insert('recurring_transactions', transaction.toMap());
    }
  }

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getRecurringTransactionsFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query('recurring_transactions');
      return List.generate(maps.length, (i) {
        return RecurringTransaction.fromMap(maps[i]);
      });
    }
  }

  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final transactions = await _getRecurringTransactionsFromPrefs(prefs);
      return transactions.where((t) => t.isActive).toList();
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'recurring_transactions',
        where: 'is_active = ?',
        whereArgs: [1],
      );
      return List.generate(maps.length, (i) {
        return RecurringTransaction.fromMap(maps[i]);
      });
    }
  }

  Future<List<RecurringTransaction>> getDueRecurringTransactions() async {
    final transactions = await getActiveRecurringTransactions();
    final now = DateTime.now();
    return transactions.where((t) => 
      t.nextDueDate.isBefore(now) || 
      t.nextDueDate.isAtSameMomentAs(now)
    ).toList();
  }

  Future<int> updateRecurringTransaction(RecurringTransaction transaction) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final transactions = await _getRecurringTransactionsFromPrefs(prefs);
      final index = transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        transactions[index] = transaction;
        await _saveRecurringTransactionsToPrefs(prefs, transactions);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'recurring_transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    }
  }

  Future<int> deleteRecurringTransaction(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final transactions = await _getRecurringTransactionsFromPrefs(prefs);
      transactions.removeWhere((transaction) => transaction.id == id);
      await _saveRecurringTransactionsToPrefs(prefs, transactions);
      return 1;
    } else {
      final db = await database as Database;
      return await db.delete(
        'recurring_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Process due recurring transactions and create actual expense/income entries
  Future<List<String>> processDueRecurringTransactions() async {
    final dueTransactions = await getDueRecurringTransactions();
    final List<String> processedTitles = [];

    for (final transaction in dueTransactions) {
      try {
        // Create the actual expense or income
        if (transaction.type == 'expense') {
          final expense = Expense(
            title: transaction.title,
            amount: transaction.amount,
            category: transaction.category,
            date: transaction.nextDueDate,
            description: '${transaction.description ?? ''} (Récurrence)',
          );
          await insertExpense(expense);
        } else {
          final income = Income(
            title: transaction.title,
            amount: transaction.amount,
            category: transaction.category,
            date: transaction.nextDueDate,
            description: '${transaction.description ?? ''} (Récurrence)',
          );
          await insertIncome(income);
        }

        // Update the recurring transaction
        final updatedTransaction = transaction.copyWith(
          currentOccurrences: transaction.currentOccurrences + 1,
          nextDueDate: transaction.calculateNextDueDate(),
        );

        // Check if we should deactivate it
        bool shouldDeactivate = false;
        if (transaction.maxOccurrences != null && 
            updatedTransaction.currentOccurrences >= transaction.maxOccurrences!) {
          shouldDeactivate = true;
        }
        if (transaction.endDate != null && 
            updatedTransaction.nextDueDate.isAfter(transaction.endDate!)) {
          shouldDeactivate = true;
        }

        final finalTransaction = shouldDeactivate 
          ? updatedTransaction.copyWith(isActive: false)
          : updatedTransaction;

        await updateRecurringTransaction(finalTransaction);
        processedTitles.add(transaction.title);
      } catch (e) {
        // Continue processing other transactions even if one fails
        continue;
      }
    }

    return processedTitles;
  }

  // Helper methods for recurring transactions web storage
  Future<List<RecurringTransaction>> _getRecurringTransactionsFromPrefs(SharedPreferences prefs) async {
    final transactionsJson = prefs.getStringList('recurring_transactions') ?? [];
    return transactionsJson.map((json) => RecurringTransaction.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveRecurringTransactionsToPrefs(SharedPreferences prefs, List<RecurringTransaction> transactions) async {
    final transactionsJson = transactions.map((transaction) => jsonEncode(transaction.toMap())).toList();
    await prefs.setStringList('recurring_transactions', transactionsJson);
  }

  // Custom Categories Methods
  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Insert default expense categories
    for (int i = 0; i < CategoryConfig.categories.length; i++) {
      final category = CategoryConfig.categories[i];
      try {
        await db.insert(
          'custom_categories',
          {
            'name': category,
            'type': 'expense',
            'icon_name': CategoryConfig.categoryIcons[category] ?? 'category',
            'color_value': (CategoryConfig.categoryColors[category] ?? const Color(0xFF2196F3)).value,
            'is_default': 1,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // Ignore duplicate errors
      }
    }
    
    // Insert default income categories
    for (int i = 0; i < IncomeConfig.incomeCategories.length; i++) {
      final category = IncomeConfig.incomeCategories[i];
      try {
        await db.insert(
          'custom_categories',
          {
            'name': category,
            'type': 'income',
            'icon_name': IncomeConfig.incomeIcons[category] ?? 'work',
            'color_value': (IncomeConfig.incomeColors[category] ?? const Color(0xFF4CAF50)).value,
            'is_default': 1,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // Ignore duplicate errors
      }
    }
  }

  Future<int> insertCustomCategory(CustomCategory category) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final categories = await _getCustomCategoriesFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newCategory = category.copyWith(id: newId);
      categories.add(newCategory);
      await _saveCustomCategoriesToPrefs(prefs, categories);
      return newId;
    } else {
      final db = await database as Database;
      return await db.insert('custom_categories', category.toMap());
    }
  }

  Future<List<CustomCategory>> getCustomCategories({String? type}) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final categories = await _getCustomCategoriesFromPrefs(prefs);
      if (type != null) {
        return categories.where((cat) => cat.type == type).toList();
      }
      return categories;
    } else {
      final db = await database as Database;
      final whereClause = type != null ? 'type = ?' : null;
      final whereArgs = type != null ? [type] : null;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'custom_categories',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'is_default DESC, name ASC',
      );
      
      return List.generate(maps.length, (i) => CustomCategory.fromMap(maps[i]));
    }
  }

  Future<CustomCategory?> getCustomCategory(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final categories = await _getCustomCategoriesFromPrefs(prefs);
      try {
        return categories.firstWhere((cat) => cat.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'custom_categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return CustomCategory.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateCustomCategory(CustomCategory category) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final categories = await _getCustomCategoriesFromPrefs(prefs);
      final index = categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        categories[index] = category.copyWith(updatedAt: DateTime.now());
        await _saveCustomCategoriesToPrefs(prefs, categories);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'custom_categories',
        category.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
  }

  Future<int> deleteCustomCategory(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final categories = await _getCustomCategoriesFromPrefs(prefs);
      final initialLength = categories.length;
      categories.removeWhere((cat) => cat.id == id && !cat.isDefault);
      await _saveCustomCategoriesToPrefs(prefs, categories);
      return initialLength - categories.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'custom_categories',
        where: 'id = ? AND is_default = 0', // Don't allow deleting default categories
        whereArgs: [id],
      );
    }
  }

  // Helper methods for custom categories web storage
  Future<List<CustomCategory>> _getCustomCategoriesFromPrefs(SharedPreferences prefs) async {
    final categoriesJson = prefs.getStringList('custom_categories') ?? [];
    return categoriesJson.map((json) => CustomCategory.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveCustomCategoriesToPrefs(SharedPreferences prefs, List<CustomCategory> categories) async {
    final categoriesJson = categories.map((category) => jsonEncode(category.toMap())).toList();
    await prefs.setStringList('custom_categories', categoriesJson);
  }

  // Accounts Methods
  Future<void> _insertDefaultAccounts(Database db) async {
    final defaultAccounts = Account.getDefaultAccounts();
    
    for (final account in defaultAccounts) {
      try {
        await db.insert(
          'accounts',
          account.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        // Ignore duplicate errors
      }
    }
  }

  Future<int> insertAccount(Account account) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final accounts = await _getAccountsFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newAccount = account.copyWith(id: newId);
      accounts.add(newAccount);
      await _saveAccountsToPrefs(prefs, accounts);
      return newId;
    } else {
      final db = await database as Database;
      return await db.insert('accounts', account.toMap());
    }
  }

  Future<List<Account>> getAccounts({bool activeOnly = false}) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final accounts = await _getAccountsFromPrefs(prefs);
      if (activeOnly) {
        return accounts.where((account) => account.isActive).toList();
      }
      return accounts;
    } else {
      final db = await database as Database;
      final whereClause = activeOnly ? 'is_active = 1' : null;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'accounts',
        where: whereClause,
        orderBy: 'name ASC',
      );
      
      return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
    }
  }

  Future<Account?> getAccount(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final accounts = await _getAccountsFromPrefs(prefs);
      try {
        return accounts.firstWhere((account) => account.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Account.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateAccount(Account account) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final accounts = await _getAccountsFromPrefs(prefs);
      final index = accounts.indexWhere((acc) => acc.id == account.id);
      if (index != -1) {
        accounts[index] = account.copyWith(updatedAt: DateTime.now());
        await _saveAccountsToPrefs(prefs, accounts);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'accounts',
        account.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );
    }
  }

  Future<int> deleteAccount(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final accounts = await _getAccountsFromPrefs(prefs);
      final initialLength = accounts.length;
      accounts.removeWhere((acc) => acc.id == id);
      await _saveAccountsToPrefs(prefs, accounts);
      return initialLength - accounts.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'accounts',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> updateAccountBalance(int accountId, double newBalance) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final accounts = await _getAccountsFromPrefs(prefs);
      final index = accounts.indexWhere((acc) => acc.id == accountId);
      if (index != -1) {
        accounts[index] = accounts[index].copyWith(
          currentBalance: newBalance,
          updatedAt: DateTime.now(),
        );
        await _saveAccountsToPrefs(prefs, accounts);
      }
    } else {
      final db = await database as Database;
      await db.update(
        'accounts',
        {
          'current_balance': newBalance,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [accountId],
      );
    }
  }

  // Helper methods for accounts web storage
  Future<List<Account>> _getAccountsFromPrefs(SharedPreferences prefs) async {
    final accountsJson = prefs.getStringList('accounts') ?? [];
    return accountsJson.map((json) => Account.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveAccountsToPrefs(SharedPreferences prefs, List<Account> accounts) async {
    final accountsJson = accounts.map((account) => jsonEncode(account.toMap())).toList();
    await prefs.setStringList('accounts', accountsJson);
  }

  // Goals Methods
  Future<int> insertGoal(Goal goal) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final goals = await _getGoalsFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newGoal = goal.copyWith(id: newId);
      goals.add(newGoal);
      await _saveGoalsToPrefs(prefs, goals);
      return newId;
    } else {
      final db = await database as Database;
      return await db.insert('goals', goal.toMap());
    }
  }

  Future<List<Goal>> getGoals({GoalStatus? status, GoalType? type}) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      var goals = await _getGoalsFromPrefs(prefs);
      
      if (status != null) {
        goals = goals.where((goal) => goal.status == status).toList();
      }
      if (type != null) {
        goals = goals.where((goal) => goal.type == type).toList();
      }
      
      return goals;
    } else {
      final db = await database as Database;
      List<String> whereConditions = [];
      List<dynamic> whereArgs = [];
      
      if (status != null) {
        whereConditions.add('status = ?');
        whereArgs.add(status.name);
      }
      if (type != null) {
        whereConditions.add('type = ?');
        whereArgs.add(type.name);
      }
      
      final whereClause = whereConditions.isNotEmpty 
          ? whereConditions.join(' AND ')
          : null;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'goals',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'target_date ASC, priority DESC',
      );
      
      return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
    }
  }

  Future<Goal?> getGoal(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final goals = await _getGoalsFromPrefs(prefs);
      try {
        return goals.firstWhere((goal) => goal.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'goals',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Goal.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateGoal(Goal goal) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final goals = await _getGoalsFromPrefs(prefs);
      final index = goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        goals[index] = goal.copyWith(updatedAt: DateTime.now());
        await _saveGoalsToPrefs(prefs, goals);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'goals',
        goal.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );
    }
  }

  Future<int> deleteGoal(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final goals = await _getGoalsFromPrefs(prefs);
      final initialLength = goals.length;
      goals.removeWhere((g) => g.id == id);
      await _saveGoalsToPrefs(prefs, goals);
      return initialLength - goals.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> updateGoalProgress(int goalId, double newAmount) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final goals = await _getGoalsFromPrefs(prefs);
      final index = goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        final oldGoal = goals[index];
        goals[index] = goals[index].copyWith(
          currentAmount: newAmount,
          updatedAt: DateTime.now(),
        );
        await _saveGoalsToPrefs(prefs, goals);
        
        // Trigger notification check for goal progress
        try {
          final ReminderManager reminderManager = ReminderManager();
          await reminderManager.updateGoalReminders(goals[index]);
          
          // Check if goal is completed
          if (goals[index].progressPercentage >= 100 && oldGoal.status != GoalStatus.completed) {
            goals[index] = goals[index].copyWith(status: GoalStatus.completed);
            await _saveGoalsToPrefs(prefs, goals);
            await reminderManager.notifyGoalAchievement(goals[index]);
          }
        } catch (e) {
          // Handle notification error silently
        }
        
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      final result = await db.update(
        'goals',
        {
          'current_amount': newAmount,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [goalId],
      );
      
      // Trigger notification check for goal progress
      if (result > 0) {
        try {
          final goal = await getGoal(goalId);
          if (goal != null) {
            final ReminderManager reminderManager = ReminderManager();
            await reminderManager.updateGoalReminders(goal);
            
            // Check if goal is completed
            if (goal.progressPercentage >= 100 && goal.status != GoalStatus.completed) {
              await updateGoal(goal.copyWith(status: GoalStatus.completed));
              await reminderManager.notifyGoalAchievement(goal);
            }
          }
        } catch (e) {
          // Handle notification error silently
        }
      }
      
      return result;
    }
  }

  // Helper methods for goals web storage
  Future<List<Goal>> _getGoalsFromPrefs(SharedPreferences prefs) async {
    final goalsJson = prefs.getStringList('goals') ?? [];
    return goalsJson.map((json) => Goal.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveGoalsToPrefs(SharedPreferences prefs, List<Goal> goals) async {
    final goalsJson = goals.map((goal) => jsonEncode(goal.toMap())).toList();
    await prefs.setStringList('goals', goalsJson);
  }

  // Dashboard helper methods
  Future<double> getTotalBalance() async {
    // Always calculate balance dynamically from actual transactions
    final totalIncome = await getTotalIncomeAllTime();
    final totalExpenses = await getTotalExpensesAllTime();
    return totalIncome - totalExpenses;
  }

  Future<List<Expense>> getRecentExpenses(int limit) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = prefs.getStringList('expenses') ?? [];
      final expenses = expensesJson
          .map((json) => Expense.fromMap(jsonDecode(json)))
          .toList();
      
      // Sort by date descending and take limit
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses.take(limit).toList();
    } else {
      final db = await database;
      final maps = await db.query(
        'expenses',
        orderBy: 'date DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    }
  }

  Future<double> getTotalExpensesInDateRange(DateTime startDate, DateTime endDate) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = prefs.getStringList('expenses') ?? [];
      final expenses = expensesJson
          .map((json) => Expense.fromMap(jsonDecode(json)))
          .toList();
      
      final filteredExpenses = expenses.where((expense) =>
          expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      
      return filteredExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    } else {
      final db = await database;
      // Use simple date string comparison - SQLite handles this well
      final startDateStr = startDate.toIso8601String().substring(0, 10); // YYYY-MM-DD
      final endDateStr = endDate.toIso8601String().substring(0, 10);     // YYYY-MM-DD
      
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM expenses
        WHERE substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?
      ''', [startDateStr, endDateStr]);
      
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<double> getTotalIncomeInDateRange(DateTime startDate, DateTime endDate) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final incomesJson = prefs.getStringList('incomes') ?? [];
      final incomes = incomesJson
          .map((json) => Income.fromMap(jsonDecode(json)))
          .toList();
      
      final filteredIncomes = incomes.where((income) =>
          income.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          income.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      
      return filteredIncomes.fold<double>(0.0, (sum, income) => sum + income.amount);
    } else {
      final db = await database;
      // Use simple date string comparison - SQLite handles this well
      final startDateStr = startDate.toIso8601String().substring(0, 10); // YYYY-MM-DD
      final endDateStr = endDate.toIso8601String().substring(0, 10);     // YYYY-MM-DD
      
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM incomes
        WHERE substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?
      ''', [startDateStr, endDateStr]);
      
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<double> getTotalExpensesAllTime() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = prefs.getStringList('expenses') ?? [];
      final expenses = expensesJson
          .map((json) => Expense.fromMap(jsonDecode(json)))
          .toList();
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    } else {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<double> getTotalIncomeAllTime() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final incomesJson = prefs.getStringList('incomes') ?? [];
      final incomes = incomesJson
          .map((json) => Income.fromMap(jsonDecode(json)))
          .toList();
      return incomes.fold<double>(0.0, (sum, income) => sum + income.amount);
    } else {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM incomes');
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<List<Goal>> getActiveGoals() async {
    final allGoals = await getGoals(status: GoalStatus.active);
    return allGoals;
  }

  // User methods
  Future<int> insertUser(User user) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final users = await _getUsersFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newUser = user.copyWith(id: newId);
      users.add(newUser);
      await _saveUsersToPrefs(prefs, users);
      return newId;
    } else {
      final db = await database as Database;
      return await db.insert('users', user.toMap());
    }
  }

  Future<User?> getUser(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final users = await _getUsersFromPrefs(prefs);
      try {
        return users.firstWhere((user) => user.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<List<User>> getUsers() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getUsersFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query('users');
      return List.generate(maps.length, (i) => User.fromMap(maps[i]));
    }
  }

  Future<int> updateUser(User user) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final users = await _getUsersFromPrefs(prefs);
      final index = users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        users[index] = user;
        await _saveUsersToPrefs(prefs, users);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    }
  }

  Future<int> deleteUser(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final users = await _getUsersFromPrefs(prefs);
      final initialLength = users.length;
      users.removeWhere((user) => user.id == id);
      await _saveUsersToPrefs(prefs, users);
      return initialLength - users.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<User?> getUserByEmail(String email) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final users = await _getUsersFromPrefs(prefs);
      try {
        return users.firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'LOWER(email) = LOWER(?)',
        whereArgs: [email],
      );
      
      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    }
  }

  // Helper methods for web storage
  Future<List<User>> _getUsersFromPrefs(SharedPreferences prefs) async {
    final usersJson = prefs.getStringList('users') ?? [];
    return usersJson.map((json) => User.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveUsersToPrefs(SharedPreferences prefs, List<User> users) async {
    final usersJson = users.map((user) => jsonEncode(user.toMap())).toList();
    await prefs.setStringList('users', usersJson);
  }

  // ===== DEBT MANAGEMENT METHODS =====

  Future<int> insertDebt(Debt debt) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final debts = await _getDebtsFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newDebt = debt.copyWith(id: newId);
      debts.add(newDebt);
      await _saveDebtsToPrefs(prefs, debts);
      return newId;
    } else {
      final db = await database as Database;
      final debtMap = debt.toMap();
      debtMap.remove('id'); // Let database assign ID
      return await db.insert('debts', debtMap);
    }
  }

  Future<List<Debt>> getDebts() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getDebtsFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'debts',
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => Debt.fromMap(maps[i]));
    }
  }

  Future<Debt?> getDebt(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final debts = await _getDebtsFromPrefs(prefs);
      try {
        return debts.firstWhere((debt) => debt.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'debts',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Debt.fromMap(maps.first);
      }
      return null;
    }
  }

  Future<int> updateDebt(Debt debt) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final debts = await _getDebtsFromPrefs(prefs);
      final index = debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        debts[index] = debt;
        await _saveDebtsToPrefs(prefs, debts);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'debts',
        debt.toMap(),
        where: 'id = ?',
        whereArgs: [debt.id],
      );
    }
  }

  Future<int> deleteDebt(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final debts = await _getDebtsFromPrefs(prefs);
      debts.removeWhere((debt) => debt.id == id);
      await _saveDebtsToPrefs(prefs, debts);
      
      // Also delete associated payments
      final payments = await _getDebtPaymentsFromPrefs(prefs);
      payments.removeWhere((payment) => payment.debtId == id);
      await _saveDebtPaymentsToPrefs(prefs, payments);
      
      return 1;
    } else {
      final db = await database as Database;
      return await db.delete(
        'debts',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> insertDebtPayment(DebtPayment payment) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final payments = await _getDebtPaymentsFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newPayment = DebtPayment(
        id: newId,
        debtId: payment.debtId,
        amount: payment.amount,
        paymentDate: payment.paymentDate,
        description: payment.description,
        isExtraPayment: payment.isExtraPayment,
        createdAt: payment.createdAt,
      );
      payments.add(newPayment);
      await _saveDebtPaymentsToPrefs(prefs, payments);
      return newId;
    } else {
      final db = await database as Database;
      final paymentMap = payment.toMap();
      paymentMap.remove('id'); // Let database assign ID
      return await db.insert('debt_payments', paymentMap);
    }
  }

  Future<List<DebtPayment>> getDebtPayments() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getDebtPaymentsFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'debt_payments',
        orderBy: 'payment_date DESC',
      );
      return List.generate(maps.length, (i) => DebtPayment.fromMap(maps[i]));
    }
  }

  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final payments = await _getDebtPaymentsFromPrefs(prefs);
      return payments.where((payment) => payment.debtId == debtId).toList();
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
        orderBy: 'payment_date DESC',
      );
      return List.generate(maps.length, (i) => DebtPayment.fromMap(maps[i]));
    }
  }

  // Helper methods for web storage (debts)
  Future<List<Debt>> _getDebtsFromPrefs(SharedPreferences prefs) async {
    final debtsJson = prefs.getStringList('debts') ?? [];
    return debtsJson.map((json) => Debt.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveDebtsToPrefs(SharedPreferences prefs, List<Debt> debts) async {
    final debtsJson = debts.map((debt) => jsonEncode(debt.toMap())).toList();
    await prefs.setStringList('debts', debtsJson);
  }

  Future<List<DebtPayment>> _getDebtPaymentsFromPrefs(SharedPreferences prefs) async {
    final paymentsJson = prefs.getStringList('debt_payments') ?? [];
    return paymentsJson.map((json) => DebtPayment.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveDebtPaymentsToPrefs(SharedPreferences prefs, List<DebtPayment> payments) async {
    final paymentsJson = payments.map((payment) => jsonEncode(payment.toMap())).toList();
    await prefs.setStringList('debt_payments', paymentsJson);
  }

  // Notification methods
  Future<int> insertNotification(AppNotification notification) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newNotification = notification.copyWith(id: newId);
      notifications.add(newNotification);
      await _saveNotificationsToPrefs(prefs, notifications);
      return newId;
    } else {
      final db = await database as Database;
      final notificationMap = notification.toMap();
      // Convert DateTime to timestamp for SQLite
      notificationMap['timestamp'] = notification.timestamp.millisecondsSinceEpoch;
      return await db.insert('notifications', notificationMap);
    }
  }

  Future<List<AppNotification>> getNotifications({bool unreadOnly = false}) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      if (unreadOnly) {
        return notifications.where((n) => !n.isRead).toList();
      }
      return notifications..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      final db = await database as Database;
      final whereClause = unreadOnly ? 'is_read = 0' : null;
      final List<Map<String, dynamic>> maps = await db.query(
        'notifications',
        where: whereClause,
        orderBy: 'timestamp DESC',
      );
      
      return List.generate(maps.length, (i) {
        final map = Map<String, dynamic>.from(maps[i]);
        // Convert timestamp back to ISO string
        map['timestamp'] = DateTime.fromMillisecondsSinceEpoch(map['timestamp']).toIso8601String();
        return AppNotification.fromMap(map);
      });
    }
  }

  Future<int> getUnreadNotificationCount() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      return notifications.where((n) => !n.isRead).length;
    } else {
      final db = await database as Database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications WHERE is_read = 0');
      return (result.first['count'] as int?) ?? 0;
    }
  }

  Future<int> markNotificationAsRead(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveNotificationsToPrefs(prefs, notifications);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> markAllNotificationsAsRead() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      final updatedNotifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
      await _saveNotificationsToPrefs(prefs, updatedNotifications);
      return notifications.length;
    } else {
      final db = await database as Database;
      return await db.update(
        'notifications',
        {'is_read': 1},
        where: 'is_read = 0',
      );
    }
  }

  Future<int> deleteNotification(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      final initialLength = notifications.length;
      notifications.removeWhere((n) => n.id == id);
      await _saveNotificationsToPrefs(prefs, notifications);
      return initialLength - notifications.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> deleteOldNotifications({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final notifications = await _getNotificationsFromPrefs(prefs);
      final initialLength = notifications.length;
      notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));
      await _saveNotificationsToPrefs(prefs, notifications);
      return initialLength - notifications.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'notifications',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );
    }
  }

  // Helper methods for notification web storage
  Future<List<AppNotification>> _getNotificationsFromPrefs(SharedPreferences prefs) async {
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    return notificationsJson.map((json) => AppNotification.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveNotificationsToPrefs(SharedPreferences prefs, List<AppNotification> notifications) async {
    final notificationsJson = notifications.map((notification) => jsonEncode(notification.toMap())).toList();
    await prefs.setStringList('notifications', notificationsJson);
  }

  // Custom Debt Types methods
  Future<int> insertCustomDebtType(CustomDebtType debtType) async {
    if (kIsWeb) {
      // For web, we'll use SharedPreferences to store custom debt types
      final prefs = await database as SharedPreferences;
      final customDebtTypes = await _getCustomDebtTypesFromPrefs(prefs);
      final maxId = customDebtTypes.isEmpty 
          ? 0 
          : customDebtTypes.map((dt) => dt.id ?? 0).reduce((a, b) => a > b ? a : b);
      debtType = debtType.copyWith(id: maxId + 1);
      customDebtTypes.add(debtType);
      await _saveCustomDebtTypesToPrefs(prefs, customDebtTypes);
      return debtType.id!;
    } else {
      final db = await database as Database;
      return await db.insert('custom_debt_types', debtType.toMap());
    }
  }

  Future<List<CustomDebtType>> getCustomDebtTypes() async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      return await _getCustomDebtTypesFromPrefs(prefs);
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query('custom_debt_types');
      return List.generate(maps.length, (i) => CustomDebtType.fromMap(maps[i]));
    }
  }

  Future<CustomDebtType?> getCustomDebtTypeById(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final customDebtTypes = await _getCustomDebtTypesFromPrefs(prefs);
      try {
        return customDebtTypes.firstWhere((dt) => dt.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database as Database;
      final List<Map<String, dynamic>> maps = await db.query(
        'custom_debt_types',
        where: 'id = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty ? CustomDebtType.fromMap(maps.first) : null;
    }
  }

  Future<int> updateCustomDebtType(CustomDebtType debtType) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final customDebtTypes = await _getCustomDebtTypesFromPrefs(prefs);
      final index = customDebtTypes.indexWhere((dt) => dt.id == debtType.id);
      if (index != -1) {
        customDebtTypes[index] = debtType;
        await _saveCustomDebtTypesToPrefs(prefs, customDebtTypes);
        return 1;
      }
      return 0;
    } else {
      final db = await database as Database;
      return await db.update(
        'custom_debt_types',
        debtType.toMap(),
        where: 'id = ?',
        whereArgs: [debtType.id],
      );
    }
  }

  Future<int> deleteCustomDebtType(int id) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final customDebtTypes = await _getCustomDebtTypesFromPrefs(prefs);
      final initialLength = customDebtTypes.length;
      customDebtTypes.removeWhere((dt) => dt.id == id);
      await _saveCustomDebtTypesToPrefs(prefs, customDebtTypes);
      return initialLength - customDebtTypes.length;
    } else {
      final db = await database as Database;
      return await db.delete(
        'custom_debt_types',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<bool> customDebtTypeNameExists(String name, {int? excludeId}) async {
    if (kIsWeb) {
      final prefs = await database as SharedPreferences;
      final customDebtTypes = await _getCustomDebtTypesFromPrefs(prefs);
      return customDebtTypes.any((dt) => 
        dt.name.toLowerCase() == name.toLowerCase() && 
        (excludeId == null || dt.id != excludeId)
      );
    } else {
      final db = await database as Database;
      String whereClause = 'LOWER(name) = LOWER(?)';
      List<dynamic> whereArgs = [name];
      
      if (excludeId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeId);
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'custom_debt_types',
        where: whereClause,
        whereArgs: whereArgs,
      );
      return maps.isNotEmpty;
    }
  }

  // Helper methods for custom debt types web storage
  Future<List<CustomDebtType>> _getCustomDebtTypesFromPrefs(SharedPreferences prefs) async {
    final customDebtTypesJson = prefs.getStringList('custom_debt_types') ?? [];
    return customDebtTypesJson.map((json) => CustomDebtType.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveCustomDebtTypesToPrefs(SharedPreferences prefs, List<CustomDebtType> customDebtTypes) async {
    final customDebtTypesJson = customDebtTypes.map((debtType) => jsonEncode(debtType.toMap())).toList();
    await prefs.setStringList('custom_debt_types', customDebtTypesJson);
  }
}