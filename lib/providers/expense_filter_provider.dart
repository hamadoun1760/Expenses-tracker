import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../helpers/database_helper.dart';
import '../utils/theme.dart';

class ExpenseFilterProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  
  // Filter parameters
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'date'; // 'date', 'amount', 'title', 'category'
  bool _sortAscending = false;

  // Getters
  List<Expense> get allExpenses => _allExpenses;
  List<Expense> get filteredExpenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  bool get hasActiveFilters => 
      _searchQuery.isNotEmpty ||
      _selectedCategory != 'All' ||
      _startDate != null ||
      _endDate != null ||
      _minAmount != null ||
      _maxAmount != null;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allExpenses = await _databaseHelper.getExpenses();
      _applyFilters();
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
    notifyListeners();
  }

  void setAmountRange(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    _applyFilters();
    notifyListeners();
  }

  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _sortBy = 'date';
    _sortAscending = false;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredExpenses = List.from(_allExpenses);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredExpenses = _filteredExpenses.where((expense) {
        return expense.title.toLowerCase().contains(_searchQuery) ||
               (expense.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      _filteredExpenses = _filteredExpenses
          .where((expense) => expense.category == _selectedCategory)
          .toList();
    }

    // Apply date range filter
    if (_startDate != null || _endDate != null) {
      _filteredExpenses = _filteredExpenses.where((expense) {
        if (_startDate != null && expense.date.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && expense.date.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply amount range filter
    if (_minAmount != null || _maxAmount != null) {
      _filteredExpenses = _filteredExpenses.where((expense) {
        if (_minAmount != null && expense.amount < _minAmount!) {
          return false;
        }
        if (_maxAmount != null && expense.amount > _maxAmount!) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    _filteredExpenses.sort((a, b) {
      late int comparison;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        default:
          comparison = a.date.compareTo(b.date);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  // Helper method to get category display name
  String getCategoryDisplayName(String category, Function(String) localizationGetter) {
    switch (category) {
      case 'food':
        return localizationGetter('food');
      case 'transportation':
        return localizationGetter('transportation');
      case 'entertainment':
        return localizationGetter('entertainment');
      case 'shopping':
        return localizationGetter('shopping');
      case 'health':
        return localizationGetter('health');
      case 'education':
        return localizationGetter('education');
      case 'other':
        return localizationGetter('other');
      default:
        return category;
    }
  }

  // Get available categories including "All"
  List<String> getAvailableCategories() {
    final categories = ['All'];
    categories.addAll(CategoryConfig.categories);
    return categories;
  }
}