// This backup file has been removed to prevent compilation errors
import 'package:provider/provider.dart';
import '../helpers/database_helper.dart';
import '../models/expense.dart';
import '../providers/currency_provider.dart';
import 'add_edit_expense_screen.dart';
import 'expense_list_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  double _monthlyExpenses = 0.0;
  List<Expense> _recentExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final results = await Future.wait([
        _databaseHelper.getTotalExpensesInDateRange(firstDayOfMonth, lastDayOfMonth),
        _databaseHelper.getRecentExpenses(5),
      ]);

      setState(() {
        _monthlyExpenses = results[0] as double;
        _recentExpenses = results[1] as List<Expense>;
        _isLoading = false;
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
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Beautiful blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mes Dépenses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildExpensesList(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Total des Dépenses',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyProvider.formatAmount(_monthlyExpenses),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTime.now().day.toString().padLeft(2, '0')} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }

  Widget _buildExpensesList() {
    if (_recentExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aucune dépense récente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _recentExpenses.map((expense) => _buildExpenseCard(expense)).toList(),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getExpenseCategoryColor(expense.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getExpenseCategoryIcon(expense.category),
                color: _getExpenseCategoryColor(expense.category),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getExpenseCategoryDisplayName(expense.category),
                    style: TextStyle(
                      fontSize: 14,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.date.day.toString().padLeft(2, '0')} ${_getMonthName(expense.date.month)} ${expense.date.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
                },
              ),
              void IconButton(
                icon = const Icon(Icons.refresh, color: Colors.white),
                onPressed = _loadDashboardData,
              ),
              void IconButton(
                icon = const Icon(Icons.settings, color: Colors.white),
                onPressed = () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          // Main Content
          void SliverToBoxAdapter(
            child = Container(
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
      bottomNavigationBar: void BottomNavigationBar(
        type = BottomNavigationBarType.fixed,
        currentIndex = 0,
        selectedItemColor = Theme.of(context).colorScheme.primary,
        unselectedItemColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor = Theme.of(context).colorScheme.surface,
        onTap = (index) {
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
        items = const [
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
      floatingActionButton: void Column(
        mainAxisAlignment = MainAxisAlignment.end,
        children = [
          // Debt Management FAB
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "debt_fab",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebtManagementScreen(),
                ),
              ),
              backgroundColor: Colors.orange,
              mini: true,
              child: const Icon(Icons.account_balance),
            ),
          ),
          const SizedBox(height: 16),
          // Receipt Scanner FAB
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "receipt_fab",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiptScanScreen(),
                ),
              ),
              backgroundColor: Colors.blue,
              mini: true,
              child: const Icon(Icons.document_scanner),
            ),
          ),
          const SizedBox(height: 16),
          // Main Add Expense FAB
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "main_fab",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditExpenseScreen(),
                ),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            ),
          ),
        ],
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
                localeProvider.formatDate(expense.date),
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
    );
  }

  Widget _buildModernFinancialOverview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
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
                  'Vue d\'ensemble financi\u00e8re',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white.withOpacity(0.8),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                
                return isSmallScreen
                    ? Column(
                        children: [
                          _buildFinancialMetric(
                            'Revenus du mois',
                            '${_monthlyIncome.toStringAsFixed(0)} FCFA',
                            Icons.arrow_upward,
                            Colors.green[300]!,
                          ),
                          const SizedBox(height: 12),
                          _buildFinancialMetric(
                            'Dépenses du mois',
                            '${_monthlyExpenses.toStringAsFixed(0)} FCFA',
                            Icons.arrow_downward,
                            Colors.red[300]!,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildFinancialMetric(
                              'Revenus du mois',
                              '${_monthlyIncome.toStringAsFixed(0)} FCFA',
                              Icons.arrow_upward,
                              Colors.green[300]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFinancialMetric(
                              'Dépenses du mois',
                              '${_monthlyExpenses.toStringAsFixed(0)} FCFA',
                              Icons.arrow_downward,
                              Colors.red[300]!,
                            ),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Solde total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalBalance.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use 2 columns on small screens, 4 on large screens
              final isSmallScreen = constraints.maxWidth < 400;
              final actions = [
                _buildModernActionButton(
                  icon: Icons.add_circle,
                  label: 'Dépense',
                  color: Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
                  ),
                ),
                _buildModernActionButton(
                  icon: Icons.camera_alt,
                  label: 'Scanner',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraReceiptScreen()),
                  ),
                ),
                _buildModernActionButton(
                  icon: Icons.analytics,
                  label: 'Revenus',
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IncomeListScreen()),
                  ),
                ),
                _buildModernActionButton(
                  icon: Icons.pie_chart,
                  label: 'Stats',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                  ),
                ),
              ];

              return isSmallScreen
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: actions.take(2).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: actions.skip(2).toList(),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actions,
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
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
    final categoryColors = {
      'food': Colors.orange,
      'transport': Colors.blue,
      'shopping': Colors.pink,
      'entertainment': Colors.purple,
      'health': Colors.green,
      'education': Colors.indigo,
    };

    final categoryIcons = {
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'shopping': Icons.shopping_bag,
      'entertainment': Icons.movie,
      'health': Icons.medical_services,
      'education': Icons.school,
    };

    final color = categoryColors[expense.category.toLowerCase()] ?? Colors.grey;
    final icon = categoryIcons[expense.category.toLowerCase()] ?? Icons.category;

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
                '-${expense.amount.toStringAsFixed(0)} FCFA',
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

  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    ).then((_) => _loadDashboardData());
  }

  IconData _getExpenseCategoryIcon(String category) {
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
    switch (category.toLowerCase()) {
      case 'food':
      case 'alimentation':
        return const Color(0xFFFF9800);
      case 'transportation':
      case 'transport':
      case 'carburant':
        return const Color(0xFFE53935);
      case 'entertainment':
      case 'divertissement':
        return const Color(0xFF9C27B0);
      case 'shopping':
        return const Color(0xFFE91E63);
      case 'health':
      case 'santé':
        return const Color(0xFFF44336);
      case 'education':
      case 'éducation':
        return const Color(0xFF4CAF50);
      case 'internet':
      case 'forfait internet':
        return const Color(0xFF2196F3);
      case 'donation':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF607D8B);
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
        return 'Carburant';
      case 'forfait internet':
        return 'Forfait Internet';
      case 'donation':
        return 'Donation';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }
}