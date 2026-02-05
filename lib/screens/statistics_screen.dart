import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';
import 'home_dashboard_screen.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  double _totalExpenses = 0;
  double _totalIncomes = 0;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  final int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);
      final expenses = await _databaseHelper.getExpenses();
      final incomes = await _databaseHelper.getIncomes();
      final customCategories = await _databaseHelper.getCustomCategories();
      setState(() {
        _expenses = expenses;
        _incomes = incomes;
        _customCategories = customCategories;
      });
      _calculateStatistics();
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des statistiques: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _getEffectiveDate() {
    final now = DateTime.now();
    
    // Check if current period has data
    bool hasCurrentData = false;
    
    switch (_selectedPeriod) {
      case 'month':
        hasCurrentData = _expenses.any((expense) => 
          expense.date.year == now.year && expense.date.month == now.month) ||
          _incomes.any((income) => 
          income.date.year == now.year && income.date.month == now.month);
        break;
      case 'year':
        hasCurrentData = _expenses.any((expense) => expense.date.year == now.year) ||
          _incomes.any((income) => income.date.year == now.year);
        break;
      default:
        hasCurrentData = _expenses.isNotEmpty || _incomes.isNotEmpty;
    }
    
    // If no data in current period, find most recent period with data
    if (!hasCurrentData && (_expenses.isNotEmpty || _incomes.isNotEmpty)) {
      DateTime? mostRecentDate;
      
      // Find most recent expense date
      if (_expenses.isNotEmpty) {
        final recentExpenseDate = _expenses.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
        mostRecentDate = recentExpenseDate;
      }
      
      // Find most recent income date
      if (_incomes.isNotEmpty) {
        final recentIncomeDate = _incomes.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
        if (mostRecentDate == null || recentIncomeDate.isAfter(mostRecentDate)) {
          mostRecentDate = recentIncomeDate;
        }
      }
      
      if (mostRecentDate != null) {
        return mostRecentDate;
      }
    }
    
    return now;
  }

  void _calculateStatistics() {
    final effectiveDate = _getEffectiveDate();
    

    
    // Filter expenses
    final filteredExpenses = _expenses.where((expense) {
      switch (_selectedPeriod) {
        case 'month':
          return expense.date.year == effectiveDate.year && expense.date.month == effectiveDate.month;
        case 'year':
          return expense.date.year == effectiveDate.year;
        default:
          return true;
      }
    }).toList();
    
    // Filter incomes
    final filteredIncomes = _incomes.where((income) {
      switch (_selectedPeriod) {
        case 'month':
          return income.date.year == effectiveDate.year && income.date.month == effectiveDate.month;
        case 'year':
          return income.date.year == effectiveDate.year;
        default:
          return true;
      }
    }).toList();

    _totalExpenses = filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
    _totalIncomes = filteredIncomes.fold(0, (sum, income) => sum + income.amount);
  }

  String _getCategoryDisplayName(String category) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == category,
      orElse: () => CustomCategory(name: '', type: 'expense', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      return customCategory.name;
    }
    
    // Handle default categories
    switch (category) {
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
      case 'other':
        return 'Autre';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: theme.colorScheme.onSurface,
            ),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _calculateStatistics();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month),
                    SizedBox(width: 8),
                    Text('Ce mois'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'year',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Cette année'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 8),
                    Text('Tout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _buildStatisticsBody(),
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
            currentIndex: 2,
            selectedItemColor: const Color(0xFF1976D2),
            unselectedItemColor: Colors.grey[600],
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            iconSize: 24,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
              );
              break;
            case 1:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
              );
              break;
            case 2:
              // Already on statistics screen
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
        ),
      ),
    );
  }

  Widget _buildStatisticsBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_expenses.isEmpty && _incomes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined, 
              size: 80, 
              color: theme.colorScheme.onSurface.withOpacity(0.5)
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                fontSize: 18, 
                color: theme.colorScheme.onSurface.withOpacity(0.7)
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          _buildOverviewCards(),
          const SizedBox(height: 20),
          _buildPieChartSection(),
          const SizedBox(height: 20),
          _buildTrendChart(),
          const SizedBox(height: 20),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    final theme = Theme.of(context);
    String periodText;
    switch (_selectedPeriod) {
      case 'month':
        periodText = 'Ce mois';
        break;
      case 'year':
        periodText = 'Cette année';
        break;
      default:
        periodText = 'Toutes les périodes';
    }

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today, 
              color: theme.colorScheme.primary
            ),
            const SizedBox(width: 12),
            Text(
              periodText,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.trending_down,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Dépenses',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(_totalExpenses)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Revenus',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(_totalIncomes)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection() {
    final theme = Theme.of(context);
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColors = {};
    final effectiveDate = _getEffectiveDate();
    final filteredExpenses = _expenses.where((expense) {
      switch (_selectedPeriod) {
        case 'month':
          return expense.date.year == effectiveDate.year && expense.date.month == effectiveDate.month;
        case 'year':
          return expense.date.year == effectiveDate.year;
        default:
          return true;
      }
    }).toList();

    // Calculate category totals
    for (final expense in filteredExpenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) {
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Répartition par catégorie',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune donnée disponible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Assign colors to categories
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green  
      const Color(0xFFD32F2F), // Red
      const Color(0xFFF57C00), // Orange
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFF00796B), // Teal
      const Color(0xFFAFB42B), // Lime
      const Color(0xFF5D4037), // Brown
      const Color(0xFF455A64), // Blue Grey
      const Color(0xFFE91E63), // Pink
    ];

    for (int i = 0; i < sortedCategories.length; i++) {
      categoryColors[sortedCategories[i].key] = colors[i % colors.length];
    }

    final total = categoryTotals.values.reduce((a, b) => a + b);

    return Column(
      children: [
        // Pie Chart Section
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1976D2),
                            const Color(0xFF42A5F5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pie_chart,
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
                            'Répartition par catégorie',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                          Text(
                            'Total: ${total.toStringAsFixed(0)} FCFA',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: sortedCategories.map((entry) {
                        final percentage = (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: categoryColors[entry.key]!,
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legends Section
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.legend_toggle,
                        color: const Color(0xFF1976D2),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Légendes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: sortedCategories.map((entry) {
                    final percentage = (entry.value / total) * 100;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: categoryColors[entry.key]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: categoryColors[entry.key]!.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: categoryColors[entry.key]!,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getCategoryDisplayName(entry.key),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: categoryColors[entry.key]!.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(0)} FCFA (${percentage.toStringAsFixed(1)}%)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final theme = Theme.of(context);
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColors = {};
    final effectiveDate = _getEffectiveDate();
    final filteredExpenses = _expenses.where((expense) {
      switch (_selectedPeriod) {
        case 'month':
          return expense.date.year == effectiveDate.year && expense.date.month == effectiveDate.month;
        case 'year':
          return expense.date.year == effectiveDate.year;
        default:
          return true;
      }
    }).toList();

    for (final expense in filteredExpenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) {
      return Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Répartition par catégorie',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Assign colors to categories - same as in pie chart
    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green  
      const Color(0xFFD32F2F), // Red
      const Color(0xFFF57C00), // Orange
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFF00796B), // Teal
      const Color(0xFFAFB42B), // Lime
      const Color(0xFF5D4037), // Brown
      const Color(0xFF455A64), // Blue Grey
      const Color(0xFFE91E63), // Pink
    ];

    for (int i = 0; i < sortedCategories.length; i++) {
      categoryColors[sortedCategories[i].key] = colors[i % colors.length];
    }

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Par catégories',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: categoryColors[entry.key]!,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getCategoryDisplayName(entry.key),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(0)} FCFA',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final theme = Theme.of(context);
    return Card(
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendance Mensuelle',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                                             'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                              if (value.toInt() >= 0 && value.toInt() < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    months[value.toInt()],
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      lineBarsData: [
                        // Expenses line
                        LineChartBarData(
                          spots: _getMonthlyExpenseData().map((spot) => 
                            FlSpot(spot.x, spot.y * _animation.value)).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: Colors.red.shade500,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 5,
                              color: Colors.red.shade500,
                              strokeWidth: 2,
                              strokeColor: theme.colorScheme.surface,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.shade500.withOpacity(0.1),
                          ),
                        ),
                        // Incomes line
                        LineChartBarData(
                          spots: _getMonthlyIncomeData().map((spot) => 
                            FlSpot(spot.x, spot.y * _animation.value)).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: Colors.green.shade500,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          preventCurveOverShooting: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 5,
                              color: Colors.green.shade500,
                              strokeWidth: 2,
                              strokeColor: theme.colorScheme.surface,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.shade500.withOpacity(0.1),
                          ),
                        ),
                      ],
                      minY: 0,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Dépenses', Colors.red.shade500, theme),
                const SizedBox(width: 24),
                _buildLegendItem('Revenus', Colors.green.shade500, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getMonthlyExpenseData() {
    final monthlyData = <int, double>{};
    final currentYear = DateTime.now().year;
    
    for (final expense in _expenses) {
      if (expense.date.year == currentYear) {
        final month = expense.date.month - 1; // 0-based for chart
        monthlyData[month] = (monthlyData[month] ?? 0) + expense.amount;
      }
    }
    
    final spots = <FlSpot>[];
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[i] ?? 0));
    }
    
    return spots;
  }

  List<FlSpot> _getMonthlyIncomeData() {
    final monthlyData = <int, double>{};
    final currentYear = DateTime.now().year;
    
    for (final income in _incomes) {
      if (income.date.year == currentYear) {
        final month = income.date.month - 1; // 0-based for chart
        monthlyData[month] = (monthlyData[month] ?? 0) + income.amount;
      }
    }
    
    final spots = <FlSpot>[];
    for (int i = 0; i < 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[i] ?? 0));
    }
    
    return spots;
  }
}