import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../models/custom_category.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/notification_bell.dart';
import 'add_edit_expense_screen.dart';
import 'camera_receipt_screen.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';
import 'statistics_screen.dart';
import 'goal_management_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';
import 'west_african_debt_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  double _totalBalance = 0.0;
  double _monthlyExpenses = 0.0;
  double _monthlyIncome = 0.0;
  List<Expense> _recentExpenses = [];
  List<Goal> _activeGoals = [];
  List<Account> _accounts = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;
  bool _isFabExpanded = false;
  
  // Animation controllers for modern UI
  late AnimationController _cardAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animation controllers
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _fabAnimationController.forward();
    
    _loadDashboardData();
    // Sample notifications auto-creation disabled to prevent persisting
    // notifications after uninstall/reinstall cycles
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cardAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load current month date range
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));

      // Load all expenses and incomes to check for data availability
      final allExpenses = await _databaseHelper.getExpenses();
      final allIncomes = await _databaseHelper.getIncomes();

      // Check if we have any data in current month, if not use the most recent month with data
      DateTime effectiveStartDate = firstDayOfMonth;
      DateTime effectiveEndDate = lastDayOfMonth;
      
      final currentMonthExpenses = await _databaseHelper.getTotalExpensesInDateRange(firstDayOfMonth, lastDayOfMonth);
      final currentMonthIncome = await _databaseHelper.getTotalIncomeInDateRange(firstDayOfMonth, lastDayOfMonth);
      
      // If current month has no data, find the most recent month with data
      if (currentMonthExpenses == 0.0 && currentMonthIncome == 0.0 && (allExpenses.isNotEmpty || allIncomes.isNotEmpty)) {
        // Find the most recent expense or income date
        DateTime? mostRecentDate;
        
        if (allExpenses.isNotEmpty) {
          final recentExpenseDate = allExpenses.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
          mostRecentDate = recentExpenseDate;
        }
        
        if (allIncomes.isNotEmpty) {
          final recentIncomeDate = allIncomes.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
          if (mostRecentDate == null || recentIncomeDate.isAfter(mostRecentDate)) {
            mostRecentDate = recentIncomeDate;
          }
        }
        
        if (mostRecentDate != null) {
          effectiveStartDate = DateTime(mostRecentDate.year, mostRecentDate.month, 1);
          effectiveEndDate = DateTime(mostRecentDate.year, mostRecentDate.month + 1, 1).subtract(const Duration(milliseconds: 1));
        }
      }

      // Load all data concurrently
      final results = await Future.wait([
        _databaseHelper.getTotalBalance(),
        _databaseHelper.getTotalExpensesInDateRange(effectiveStartDate, effectiveEndDate),
        _databaseHelper.getTotalIncomeInDateRange(effectiveStartDate, effectiveEndDate),
        _databaseHelper.getRecentExpenses(5),
        _databaseHelper.getActiveGoals(),
        _databaseHelper.getAccounts(),
        _databaseHelper.getCustomCategories(),
      ]);

      setState(() {
        _totalBalance = results[0] as double;
        _monthlyExpenses = results[1] as double;
        _monthlyIncome = results[2] as double;
        _recentExpenses = results[3] as List<Expense>;
        _activeGoals = results[4] as List<Goal>;
        _accounts = results[5] as List<Account>;
        _customCategories = results[6] as List<CustomCategory>;
        _isLoading = false;
        
        // Dashboard data loaded successfully
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.25, 0.5, 0.85],
          colors: [
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
            Color(0xFFBBDEFB),
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1976D2),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tableau de Bord',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestion Financière',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Notification Bell
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: NotificationBell(),
              ),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.currentUser;
                  return IconButton(
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: user?.profilePicture != null
                          ? ClipOval(
                              child: Image.memory(
                                user!.profilePicture!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadDashboardData,
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          // Main Content
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isTablet = constraints.maxWidth >= 768;
                              final isDesktop = constraints.maxWidth >= 1200;
                              final padding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
                              
                              return Container(
                                constraints: BoxConstraints(
                                  maxWidth: isDesktop ? 1200 : double.infinity,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(padding),
                                  child: Column(
                                    children: [
                                      _buildModernFinancialOverview(),
                                      const SizedBox(height: 16),
                                      _buildModernQuickActions(),
                                      const SizedBox(height: 16),
                                      _buildModernRecentExpenses(),
                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
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
              currentIndex: 0,
              selectedItemColor: const Color(0xFF1565C0),
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
              // Already on home
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
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
        floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Add Expense FAB - only show when expanded
          if (_isFabExpanded)
            ScaleTransition(
              scale: _fabAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: "add_expense_fab",
                  onPressed: () {
                    setState(() {
                      _isFabExpanded = false;
                    });
                    _fabAnimationController.reset();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditExpenseScreen(),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  mini: true,
                  child: const Icon(Icons.attach_money, color: Colors.white),
                ),
              ),
            ),
          if (_isFabExpanded) const SizedBox(height: 16),
          // Debt Management FAB - only show when expanded
          if (_isFabExpanded)
            ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                heroTag: "debt_fab",
                onPressed: () {
                  setState(() {
                    _isFabExpanded = false;
                  });
                  _fabAnimationController.reset();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WestAfricanDebtScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
                backgroundColor: Colors.orange,
                mini: true,
                child: const Icon(Icons.account_balance),
              ),
            ),
          if (_isFabExpanded) const SizedBox(height: 16),
          // Main Toggle FAB with blue gradient
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "main_fab",
              onPressed: () {
                setState(() {
                  _isFabExpanded = !_isFabExpanded;
                });
                if (_isFabExpanded) {
                  _fabAnimationController.forward();
                } else {
                  _fabAnimationController.reset();
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedRotation(
                turns: _isFabExpanded ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.add_rounded,
                    label: 'Dépense',
                    color: Colors.red,
                    onTap: () => _addExpense(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Photo',
                    color: Colors.blue,
                    onTap: () => _scanReceipt(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.trending_up_rounded,
                    label: 'Revenus',
                    color: Colors.green,
                    onTap: () => _addIncome(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Reçus',
                    color: Colors.orange,
                    onTap: () => _viewReceipts(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? theme.colorScheme.surface : Colors.white,
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverviewCard() {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble financière',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModernFinancialCard(
                    'Solde total',
                    currencyProvider.formatAmount(_totalBalance),
                    Icons.account_balance_wallet,
                    _totalBalance >= 0 ? Colors.green : Colors.red,
                    _totalBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernFinancialCard(
                    'Dépenses du mois',
                    currencyProvider.formatAmount(_monthlyExpenses),
                    Icons.trending_down,
                    Colors.red,
                    Colors.red.shade50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModernFinancialCard(
                    'Revenus du mois',
                    currencyProvider.formatAmount(_monthlyIncome),
                    Icons.trending_up,
                    Colors.green,
                    Colors.green.shade50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentExpensesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dépenses récentes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
                  ),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentExpenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Aucune dépense récente'),
                ),
              )
            else
              ..._recentExpenses.map((expense) => _buildExpenseListItem(expense)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseListItem(Expense expense) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.receipt,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  expense.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyProvider.formatAmount(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                RelativeDateUtils.formatCompactDate(expense.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgressCard() {
    if (_activeGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Objectifs en cours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GoalManagementScreen()),
                  ),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activeGoals.take(3).map((goal) => _buildGoalProgressItem(goal)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressItem(Goal goal) {
    final progress = goal.currentAmount / goal.targetAmount;
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currencyProvider.formatAmount(goal.currentAmount)} / ${currencyProvider.formatAmount(goal.targetAmount)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsOverviewCard() {
    if (_accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comptes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._accounts.take(3).map((account) => _buildAccountItem(account)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem(Account account) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(account.colorValue).withOpacity(0.2),
            child: Icon(
              account.defaultIcon,
              color: Color(account.colorValue),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              account.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            currencyProvider.formatAmount(account.currentBalance),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: account.currentBalance >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey[600],
      currentIndex: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Transactions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Statistiques',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Revenus',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatisticsScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IncomeListScreen()),
            );
            break;
        }
      },
    );
  }

  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _addIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncomeListScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _scanReceipt() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraReceiptScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _viewReceipts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
    ).then((_) => _loadDashboardData());
  }

  Widget _buildModernFinancialOverview() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vue d\'ensemble financière',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Always display cards side by side (inline)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Revenus du mois',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatWithCurrency(_monthlyIncome),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.arrow_downward,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dépenses du mois',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatWithCurrency(_monthlyExpenses),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Total balance centered
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Solde total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatWithCurrency(_totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2E),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularActionButton(
                icon: Icons.remove_circle,
                label: 'Dépenses',
                color: const Color(0xFFE74C3C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
                ).then((_) => _loadDashboardData()),
              ),
              _buildCircularActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scanner',
                color: const Color(0xFF3498DB),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraReceiptScreen()),
                ).then((_) => _loadDashboardData()),
              ),
              _buildCircularActionButton(
                icon: Icons.add_circle,
                label: 'Revenus',
                color: const Color(0xFF27AE60),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncomeListScreen()),
                ).then((_) => _loadDashboardData()),
              ),
              _buildCircularActionButton(
                icon: Icons.bar_chart,
                label: 'Statistiques',
                color: const Color(0xFF9B59B6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                ).then((_) => _loadDashboardData()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRecentExpenses() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'D\u00e9penses r\u00e9centes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
                ),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune d\u00e9pense r\u00e9cente',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_recentExpenses.take(5).map((expense) => _buildModernExpenseItem(expense)).toList()),
        ],
      ),
    );
  }

  Widget _buildModernExpenseItem(Expense expense) {
    // Helper function to get icon for any category (including custom)
    IconData getCategoryIcon(String categoryName) {
      // First check if it's a custom category
      final customCategory = _customCategories.firstWhere(
        (cat) => cat.name == categoryName,
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
      
      // Fall back to hardcoded default categories
      final categoryIcons = {
        'food': Icons.restaurant,
        'transport': Icons.directions_car,
        'shopping': Icons.shopping_bag,
        'entertainment': Icons.movie,
        'health': Icons.medical_services,
        'education': Icons.school,
        'transportation': Icons.directions_car,
      };
      return categoryIcons[categoryName.toLowerCase()] ?? Icons.category;
    }

    // Helper function to get color for any category (including custom)
    Color getCategoryColor(String categoryName) {
      // First check if it's a custom category
      final customCategory = _customCategories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => CustomCategory(name: '', type: 'expense', iconName: '', colorValue: 0, createdAt: DateTime.now()),
      );
      
      if (customCategory.name.isNotEmpty) {
        return Color(customCategory.colorValue);
      }
      
      // Fall back to hardcoded default categories
      final categoryColors = {
        'food': Colors.orange,
        'transport': Colors.blue,
        'shopping': Colors.pink,
        'entertainment': Colors.purple,
        'health': Colors.green,
        'education': Colors.indigo,
        'transportation': Colors.blue,
      };
      return categoryColors[categoryName.toLowerCase()] ?? Colors.grey;
    }

    final color = getCategoryColor(expense.category);
    final icon = getCategoryIcon(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${CurrencyFormatter.formatWithCurrency(expense.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${expense.date.day}/${expense.date.month}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernFinancialCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor,
            iconColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}