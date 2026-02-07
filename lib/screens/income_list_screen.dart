import 'package:flutter/material.dart';
import '../models/income.dart';
import '../helpers/database_helper.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart';
import '../utils/currency_formatter.dart';
import '../config/income_config.dart';
import 'add_edit_income_screen.dart';
import 'export_dialog.dart';
import 'home_dashboard_screen.dart';
import 'expense_list_screen.dart';
import 'statistics_screen.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Income> _allIncomes = [];
  List<Income> _incomes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  double _totalIncomes = 0.0;
  
  // Search and filtering variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'date';
  bool _sortAscending = false;
  Set<String> _selectedCategories = {'All'};
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
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
    super.dispose();
  }

  String _getIncomeDisplayName(BuildContext context, String categoryKey) {
    switch (categoryKey) {
      case 'salary':
        return 'Salaire';
      case 'freelance':
        return 'Freelance';
      case 'investment':
        return 'Investissement';
      case 'business':
        return 'Business';
      case 'rental':
        return 'Location';
      case 'gift':
        return 'Cadeau';
      case 'bonus':
        return 'Bonus';
      case 'other':
        return 'Autre';
      default:
        return categoryKey;
    }
  }

  Future<void> _loadIncomes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allIncomes = await _databaseHelper.getIncomes();
      setState(() {
        _allIncomes = allIncomes;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des revenus: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Income> filteredIncomes = List.from(_allIncomes);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filteredIncomes = filteredIncomes
          .where((income) => 
              income.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (income.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }

    // Apply category filter
    if (!_selectedCategories.contains('All')) {
      filteredIncomes = filteredIncomes
          .where((income) => _selectedCategories.contains(income.category))
          .toList();
    }

    // Apply date range filter
    if (_startDate != null) {
      filteredIncomes = filteredIncomes
          .where((income) => income.date.isAfter(_startDate!) || income.date.isAtSameMomentAs(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      filteredIncomes = filteredIncomes
          .where((income) => income.date.isBefore(_endDate!.add(Duration(days: 1))))
          .toList();
    }

    // Apply amount range filter
    if (_minAmount != null) {
      filteredIncomes = filteredIncomes
          .where((income) => income.amount >= _minAmount!)
          .toList();
    }
    if (_maxAmount != null) {
      filteredIncomes = filteredIncomes
          .where((income) => income.amount <= _maxAmount!)
          .toList();
    }

    // Apply sorting
    filteredIncomes.sort((a, b) {
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
      _incomes = filteredIncomes;
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  Future<void> _deleteIncome(int id) async {
    try {
      await _databaseHelper.deleteIncome(id);
      _loadIncomes();
      _loadTotalIncomes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revenu supprimé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Income income) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le revenu'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${income.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteIncome(income.id!);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddIncome() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditIncomeScreen(),
      ),
    );
    if (result == true) {
      _loadIncomes();
      _loadTotalIncomes();
    }
  }

  void _navigateToEditIncome(Income income) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditIncomeScreen(income: income),
      ),
    );
    if (result == true) {
      _loadIncomes();
      _loadTotalIncomes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Revenus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                  _applyFilters();
                }
              });
            },
            icon: Icon(
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppColors.onPrimary,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_filters') {
                  _clearAllFilters();
                } else if (value == 'export_data') {
                  _showExportDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export_data',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Exporter les revenus'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_filters',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Effacer les filtres'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.filter_list_rounded, size: 24),
            ),
          ),
        ],
        bottom: _showSearchBar ? PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
              cursorColor: AppColors.primary,
            ),
          ),
        ) : null,
      ),
      body: Column(
        children: [
          // Total Income Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Total des Revenus',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(_totalIncomes),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  if (_hasActiveFilters())
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[800]?.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_alt_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              '${_getActiveFiltersCount()} filtre(s) actif(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: _clearAllFilters,
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Income List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _incomes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasActiveFilters() 
                                  ? 'Aucun revenu trouvé avec ces filtres'
                                  : 'Aucun revenu enregistré',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Appuyez sur le bouton + pour ajouter votre premier revenu',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _incomes.length,
                        itemBuilder: (context, index) {
                          final income = _incomes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: IncomeConfig.incomeColors[income.category] ?? Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      IncomeConfig.incomeIcons[income.category] ?? Icons.monetization_on_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          income.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getIncomeDisplayName(context, income.category),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (income.description != null && income.description!.isNotEmpty)
                                          Text(
                                            income.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatWithSign(income.amount),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        RelativeDateUtils.formatRelativeDate(income.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _navigateToEditIncome(income),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.edit_rounded,
                                                size: 18,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _showDeleteConfirmation(income),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.delete_rounded,
                                                size: 18,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddIncome,
        tooltip: 'Ajouter un revenu',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // Income tab
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeDashboardScreen()),
              );
              break;
            case 1:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ExpenseListScreen()),
              );
              break;
            case 2:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => StatisticsScreen()),
              );
              break;
            case 3:
              // Already on income screen
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Dépenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_rounded),
            label: 'Revenus',
          ),
        ],
      ),
    );
  }
}