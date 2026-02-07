import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';
import '../utils/theme.dart';
import '../utils/currency_formatter.dart';

import 'add_edit_expense_screen.dart';
import 'camera_receipt_screen.dart';
import 'statistics_screen.dart';
import 'budget_screen.dart';
import 'income_list_screen.dart';
import 'export_dialog.dart';
import 'settings_screen.dart';
import 'recurring_transactions_screen.dart';
import 'home_dashboard_screen.dart';
import 'category_management_screen.dart';
import 'account_management_screen.dart';
import 'goal_management_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Expense> _allExpenses = [];
  List<Expense> _expenses = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;
  
  // Animation controllers for modern UI
  late AnimationController _fabController;
  late AnimationController _listController;
  
  String _selectedCategory = 'All';
  double _totalExpenses = 0.0;
  double _totalIncomes = 0.0;
  
  // Search and filtering variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'date'; // 'date', 'amount', 'title'
  bool _sortAscending = false;
  Set<String> _selectedCategories = {'All'};
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fabController = AnimationController(
      duration: AppColors.normalAnimation,
      vsync: this,
    );
    _listController = AnimationController(
      duration: AppColors.normalAnimation,
      vsync: this,
    );
    
    _loadExpenses();
    _loadTotalExpenses();
    _loadTotalIncomes();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(BuildContext context, String categoryKey) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == categoryKey,
      orElse: () => CustomCategory(name: '', type: 'expense', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      return customCategory.name;
    }
    
    // Handle default categories
    final localizations = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case 'food':
        return localizations.food;
      case 'transportation':
        return localizations.transportation;
      case 'shopping':
        return localizations.shopping;
      case 'entertainment':
        return localizations.entertainment;
      case 'health':
        return localizations.health;
      case 'education':
        return localizations.education;
      case 'other':
        return localizations.other;
      default:
        return categoryKey;
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allExpenses = await _databaseHelper.getExpenses();
      final customCategories = await _databaseHelper.getCustomCategories(type: 'expense');
      setState(() {
        _allExpenses = allExpenses;
        _customCategories = customCategories;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingExpenses}: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Expense> filteredExpenses = List.from(_allExpenses);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filteredExpenses = filteredExpenses
          .where((expense) => 
              expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (expense.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }

    // Apply category filter
    if (!_selectedCategories.contains('All')) {
      filteredExpenses = filteredExpenses
          .where((expense) => _selectedCategories.contains(expense.category))
          .toList();
    }

    // Apply date range filter
    if (_startDate != null) {
      filteredExpenses = filteredExpenses
          .where((expense) => expense.date.isAfter(_startDate!) || expense.date.isAtSameMomentAs(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      filteredExpenses = filteredExpenses
          .where((expense) => expense.date.isBefore(_endDate!.add(Duration(days: 1))))
          .toList();
    }

    // Apply amount range filter
    if (_minAmount != null) {
      filteredExpenses = filteredExpenses
          .where((expense) => expense.amount >= _minAmount!)
          .toList();
    }
    if (_maxAmount != null) {
      filteredExpenses = filteredExpenses
          .where((expense) => expense.amount <= _maxAmount!)
          .toList();
    }

    // Apply sorting
    filteredExpenses.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'amount':
          result = a.amount.compareTo(b.amount);
          break;
        case 'title':
          result = a.title.compareTo(b.title);
          break;
        case 'date':
        default:
          result = a.date.compareTo(b.date);
          break;
      }
      return _sortAscending ? result : -result;
    });

    setState(() {
      _expenses = filteredExpenses;
    });
  }

  Future<void> _loadTotalExpenses() async {
    final total = await _databaseHelper.getTotalExpenses();
    setState(() {
      _totalExpenses = total;
    });
  }

  Future<void> _loadTotalIncomes() async {
    final total = await _databaseHelper.getTotalIncomes();
    setState(() {
      _totalIncomes = total;
    });
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        !_selectedCategories.contains('All') ||
        _startDate != null ||
        _endDate != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (!_selectedCategories.contains('All')) count++;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    if (_minAmount != null) count++;
    if (_maxAmount != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategories = {'All'};
      _selectedCategory = 'All';
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _sortBy = 'date';
      _sortAscending = false;
    });
    _applyFilters();
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AdvancedFiltersSheet(
        selectedCategories: _selectedCategories,
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        onFiltersChanged: (categories, startDate, endDate, minAmount, maxAmount, sortBy, sortAscending) {
          setState(() {
            _selectedCategories = categories;
            _selectedCategory = categories.contains('All') ? 'All' : categories.first;
            _startDate = startDate;
            _endDate = endDate;
            _minAmount = minAmount;
            _maxAmount = maxAmount;
            _sortBy = sortBy;
            _sortAscending = sortAscending;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: Colors.green[700]),
                ),
                title: const Text('Ajouter une d\u00e9pense'),
                subtitle: const Text('Cr\u00e9er une nouvelle entr\u00e9e'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddExpense();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue[700]),
                ),
                title: const Text('Scanner re\u00e7u'),
                subtitle: const Text('Capturer d\u00e9pense depuis photo'),
                onTap: () {
                  Navigator.pop(context);
                  _scanReceipt();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.upload_file, color: Colors.orange[700]),
                ),
                title: const Text('Importer donn\u00e9es'),
                subtitle: const Text('Importer depuis fichier'),
                onTap: () {
                  Navigator.pop(context);
                  _importExpenses();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await _databaseHelper.deleteExpense(id);
      _loadExpenses();
      _loadTotalExpenses();
      _loadTotalIncomes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.expenseDeletedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingExpense}: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteExpense),
          content: Text(AppLocalizations.of(context)!.confirmDelete(expense.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExpense(expense.id!);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    );
    if (result == true) {
      _loadExpenses();
      _loadTotalExpenses();
      _loadTotalIncomes();
    }
  }

  void _navigateToEditExpense(Expense expense) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(expense: expense),
      ),
    );
    if (result == true) {
      _loadExpenses();
      _loadTotalExpenses();
      _loadTotalIncomes();
    }
  }

  void _scanReceipt() {
    // Navigate to camera/receipt scanning screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraReceiptScreen(),
      ),
    ).then((_) {
      _loadExpenses();
      _loadTotalExpenses();
      _loadTotalIncomes();
    });
  }

  void _importExpenses() {
    // Show import dialog or navigate to import screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Expenses'),
        content: const Text('Import functionality will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.25, 0.5, 0.85],
          colors: [
            const Color(0xFF1976D2),
            const Color(0xFF42A5F5),
            const Color(0xFFBBDEFB),
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              if (_showSearchBar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  color: Theme.of(context).colorScheme.surface,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par titre ou description...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: AppColors.primary),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    cursorColor: AppColors.primary,
                  ),
                ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildExpensesSummary(context),
                    ),
                    _buildExpensesList(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildAnimatedFAB(context),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.onPrimary,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.appTitle,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.manageFinances,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: Text(AppLocalizations.of(context)!.allExpenses),
                selected: true,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up_rounded),
                title: const Text('Revenus'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const IncomeListScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: Text(AppLocalizations.of(context)!.statistics),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(AppLocalizations.of(context)!.budgets),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_rounded),
                title: const Text('Objectifs'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GoalManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat_rounded),
                title: const Text('Transactions Récurrentes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecurringTransactionsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Catégories'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoryManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Comptes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(AppLocalizations.of(context)!.settings),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 1,
              selectedItemColor: const Color(0xFF1976D2),
              unselectedItemColor: Colors.grey[600],
              backgroundColor: Colors.white,
              elevation: 0,
              selectedFontSize: 13,
              unselectedFontSize: 12,
              iconSize: 24,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
                    );
                    break;
                  case 1:
                    // Already on expenses screen
                    break;
                  case 2:
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                    );
                    break;
                  case 3:
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const IncomeListScreen()),
                    );
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.dashboard_rounded),
                  ),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.receipt_long_rounded),
                  ),
                  label: 'Dépenses',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.analytics_rounded),
                  ),
                  label: 'Statistiques',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.monetization_on_rounded),
                  ),
                  label: 'Revenus',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes Dépenses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Gérez vos dépenses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                  _applyFilters();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: Colors.red.shade300,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Dépenses',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatWithCurrency(_totalExpenses),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.green.shade300,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Revenus',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatWithCurrency(_totalIncomes),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverList _buildExpensesList(BuildContext context) {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
        ]),
      );
    }

    if (_expenses.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune dépense trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _buildExpenseItemCard(_expenses[index]);
        },
        childCount: _expenses.length,
      ),
    );
  }

  Widget _buildExpenseItemCard(Expense expense) {
    final icon = _getExpenseCategoryIcon(expense.category);
    final color = _getExpenseCategoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          expense.description ?? 'Dépense',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getExpenseCategoryDisplayName(expense.category),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              DateFormat('dd MMM yyyy', 'fr_FR').format(expense.date),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.formatWithCurrency(expense.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.red,
          ),
        ),
        onTap: () => _editExpense(expense),
      ),
    );
  }

  Widget _buildAnimatedFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showQuickActions(context),
      backgroundColor: const Color(0xFF1976D2),
      elevation: 6,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _editExpense(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(expense: expense),
      ),
    ).then((_) => _loadExpenses());
  }

  IconData _getExpenseCategoryIcon(String category) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == category,
      orElse: () => CustomCategory(name: '', type: 'expense', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      // Map icon names to actual icons
      const iconMap = {
        'category': Icons.category,
        'food': Icons.restaurant,
        'transport': Icons.directions_car,
        'shopping': Icons.shopping_cart,
        'entertainment': Icons.movie,
        'health': Icons.local_hospital,
        'education': Icons.school,
        'bills': Icons.receipt_long,
        'work': Icons.work,
        'business': Icons.business,
        'investment': Icons.trending_up,
        'gift': Icons.card_giftcard,
        'home': Icons.home,
        'utilities': Icons.electrical_services,
        'insurance': Icons.security,
        'travel': Icons.flight,
        'clothing': Icons.checkroom,
        'pets': Icons.pets,
        'sports': Icons.sports_soccer,
        'technology': Icons.devices,
        'music': Icons.music_note,
        'gaming': Icons.games,
        'beauty': Icons.spa,
        'fitness': Icons.fitness_center,
        'social': Icons.people,
        'books': Icons.menu_book,
        'coffee': Icons.local_cafe,
        'pharmacy': Icons.local_pharmacy,
        'gas': Icons.local_gas_station,
        'bank': Icons.account_balance,
      };
      return iconMap[customCategory.iconName] ?? Icons.category;
    }
    
    // Fall back to default category handling
    switch (category.toLowerCase()) {
      case 'food':
      case 'alimentation':
        return Icons.restaurant;
      case 'transportation':
      case 'transport':
      case 'carburant':
        return Icons.local_gas_station;
      case 'entertainment':
      case 'divertissement':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
      case 'santé':
        return Icons.medical_services;
      case 'education':
      case 'éducation':
        return Icons.school;
      case 'internet':
      case 'forfait internet':
        return Icons.wifi;
      case 'donation':
        return Icons.volunteer_activism;
      default:
        return Icons.receipt;
    }
  }

  Color _getExpenseCategoryColor(String category) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == category,
      orElse: () => CustomCategory(name: '', type: 'expense', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      return Color(customCategory.colorValue);
    }
    
    // Fall back to default category handling
    switch (category.toLowerCase()) {
      case 'food':
      case 'alimentation':
        return const Color(0xFFFF6B6B); // Red for food
      case 'transportation':
      case 'transport':
      case 'carburant':
        return const Color(0xFF4ECDC4); // Teal for transport
      case 'entertainment':
      case 'divertissement':
        return const Color(0xFF95E1D3); // Mint for entertainment
      case 'shopping':
        return const Color(0xFFE91E63); // Pink for shopping
      case 'health':
      case 'santé':
        return const Color(0xFFF38181); // Light red for health
      case 'education':
      case 'éducation':
        return const Color(0xFF4CAF50); // Green for education
      case 'internet':
      case 'forfait internet':
        return const Color(0xFF5DADE2); // Blue for internet
      case 'donation':
        return const Color(0xFF3498DB); // Bright blue for donation
      default:
        return const Color(0xFF9E9E9E); // Grey for others
    }
  }

  String _getExpenseCategoryDisplayName(String category) {
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
      case 'carburant':
        return 'Transport';
      case 'forfait internet':
        return 'Divertissement';
      case 'donation':
        return 'donation';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }
}

class _AdvancedFiltersSheet extends StatefulWidget {
  final Set<String> selectedCategories;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final bool sortAscending;
  final Function(Set<String>, DateTime?, DateTime?, double?, double?, String, bool) onFiltersChanged;

  const _AdvancedFiltersSheet({
    required this.selectedCategories,
    required this.startDate,
    required this.endDate,
    required this.minAmount,
    required this.maxAmount,
    required this.sortBy,
    required this.sortAscending,
    required this.onFiltersChanged,
  });

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late Set<String> _selectedCategories;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late double? _minAmount;
  late double? _maxAmount;
  late String _sortBy;
  late bool _sortAscending;
  
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.selectedCategories);
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;
    _sortBy = widget.sortBy;
    _sortAscending = widget.sortAscending;
    
    if (_minAmount != null) {
      _minAmountController.text = _minAmount!.toStringAsFixed(0);
    }
    if (_maxAmount != null) {
      _maxAmountController.text = _maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(BuildContext context, String categoryKey) {
    final localizations = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case 'food':
        return localizations.food;
      case 'transportation':
        return localizations.transportation;
      case 'shopping':
        return localizations.shopping;
      case 'entertainment':
        return localizations.entertainment;
      case 'health':
        return localizations.health;
      case 'education':
        return localizations.education;
      case 'other':
        return localizations.other;
      default:
        return categoryKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres avancés',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories = {'All'};
                      _startDate = null;
                      _endDate = null;
                      _minAmount = null;
                      _maxAmount = null;
                      _minAmountController.clear();
                      _maxAmountController.clear();
                      _sortBy = 'date';
                      _sortAscending = false;
                    });
                  },
                  child: Text('Effacer tout'),
                ),
              ],
            ),
          ),
          Divider(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  Text(
                    'Catégories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text('Toutes'),
                        selected: _selectedCategories.contains('All'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories = {'All'};
                            } else {
                              _selectedCategories.remove('All');
                            }
                          });
                        },
                      ),
                      ...CategoryConfig.categories.map((category) => FilterChip(
                        label: Text(_getCategoryDisplayName(context, category)),
                        selected: _selectedCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategories.remove('All');
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                            if (_selectedCategories.isEmpty) {
                              _selectedCategories.add('All');
                            }
                          });
                        },
                      )),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Date Range
                  Text(
                    'Période',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                          icon: Icon(Icons.calendar_today_rounded),
                          label: Text(_startDate != null 
                              ? DateFormat('dd/MM/yyyy').format(_startDate!)
                              : 'Date début'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          icon: Icon(Icons.calendar_today_rounded),
                          label: Text(_endDate != null 
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : 'Date fin'),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Amount Range
                  Text(
                    'Montant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Montant min',
                            prefixIcon: Icon(Icons.monetization_on_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            _minAmount = double.tryParse(value);
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Montant max',
                            prefixIcon: Icon(Icons.monetization_on_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            _maxAmount = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Sort Options
                  Text(
                    'Tri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelText: 'Trier par',
                          ),
                          items: [
                            DropdownMenuItem(value: 'date', child: Text('Date')),
                            DropdownMenuItem(value: 'amount', child: Text('Montant')),
                            DropdownMenuItem(value: 'title', child: Text('Titre')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<bool>(
                          initialValue: _sortAscending,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelText: 'Ordre',
                          ),
                          items: [
                            DropdownMenuItem(value: false, child: Text('Décroissant')),
                            DropdownMenuItem(value: true, child: Text('Croissant')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortAscending = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Container(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(
                    _selectedCategories,
                    _startDate,
                    _endDate,
                    _minAmount,
                    _maxAmount,
                    _sortBy,
                    _sortAscending,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Appliquer les filtres',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}