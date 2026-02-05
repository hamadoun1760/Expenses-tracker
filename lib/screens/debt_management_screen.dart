import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../models/custom_category.dart';
import '../providers/debt_provider.dart';
import '../helpers/database_helper.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/modern_animations.dart';
import 'add_edit_debt_screen.dart';
import 'debt_details_screen.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<CustomCategory> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).loadDebts();
      _loadCustomCategories();
      _fadeController.forward();
    });
  }

  Future<void> _loadCustomCategories() async {
    try {
      final customCategories = await _databaseHelper.getCustomCategories(type: 'debt');
      print('DEBUG: Loaded ${customCategories.length} custom categories');
      for (final cat in customCategories) {
        print('DEBUG: Category: ${cat.name}, Icon: ${cat.iconName}, Color: ${cat.colorValue}');
      }
      setState(() {
        _customCategories = customCategories;
      });
    } catch (e) {
      print('DEBUG: Error loading custom categories: $e');
      debugPrint('Error loading custom categories: $e');
    }
  }

  IconData _getDebtIcon(Debt debt) {
    print('DEBUG: Getting icon for debt: ${debt.name}');
    print('DEBUG: customCategoryName: ${debt.customCategoryName}');
    print('DEBUG: _customCategories length: ${_customCategories.length}');
    
    if (debt.customCategoryName != null && debt.customCategoryName!.isNotEmpty) {
      print('DEBUG: Looking for custom category: ${debt.customCategoryName}');
      final customCategory = _customCategories.firstWhere(
        (cat) => cat.name == debt.customCategoryName,
        orElse: () => CustomCategory(
          name: '',
          type: 'debt',
          iconName: 'account_balance',
          colorValue: 0xFF1565C0,
          createdAt: DateTime.now(),
        ),
      );
      
      print('DEBUG: Found custom category: ${customCategory.name}');
      print('DEBUG: Custom category icon: ${customCategory.iconName}');
      
      if (customCategory.name.isNotEmpty) {
        final icon = _getIconFromName(customCategory.iconName);
        print('DEBUG: Returning custom icon: $icon');
        return icon;
      }
    }
    print('DEBUG: Returning default icon: ${debt.typeIcon}');
    return debt.typeIcon; // Use default enum icon
  }

  Color _getDebtIconColor(Debt debt) {
    print('DEBUG: Getting color for debt: ${debt.name}');
    print('DEBUG: customCategoryName: ${debt.customCategoryName}');
    
    if (debt.customCategoryName != null && debt.customCategoryName!.isNotEmpty) {
      final customCategory = _customCategories.firstWhere(
        (cat) => cat.name == debt.customCategoryName,
        orElse: () => CustomCategory(
          name: '',
          type: 'debt',
          iconName: 'account_balance',
          colorValue: 0xFF1565C0,
          createdAt: DateTime.now(),
        ),
      );
      
      print('DEBUG: Found custom category for color: ${customCategory.name}');
      print('DEBUG: Custom category color: ${customCategory.colorValue}');
      
      if (customCategory.name.isNotEmpty) {
        final color = Color(customCategory.colorValue);
        print('DEBUG: Returning custom color: $color');
        return color;
      }
    }
    print('DEBUG: Returning default color: ${debt.statusColor}');
    return debt.statusColor; // Use default status color
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'business':
        return Icons.business;
      case 'home':
        return Icons.home;
      case 'person':
        return Icons.person;
      case 'medical_services':
        return Icons.medical_services;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'phone':
        return Icons.phone;
      case 'wifi':
        return Icons.wifi;
      case 'power':
        return Icons.power;
      case 'credit_card':
        return Icons.credit_card;
      case 'school':
        return Icons.school;
      case 'directions_car':
        return Icons.directions_car;
      case 'build':
        return Icons.build;
      case 'computer':
        return Icons.computer;
      case 'account_balance':
        return Icons.account_balance;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'groups':
        return Icons.groups;
      case 'handshake':
        return Icons.handshake;
      case 'savings':
        return Icons.savings;
      case 'money':
        return Icons.attach_money;
      case 'car':
        return Icons.directions_car;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.account_balance;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Consumer<DebtProvider>(
              builder: (context, debtProvider, child) {
                if (debtProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(context, debtProvider),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildDebtSummaryCards(context, debtProvider),
                          _buildQuickActions(context, debtProvider),
                        ],
                      ),
                    ),
                    _buildDebtsList(context, debtProvider),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: _buildAnimatedFAB(context),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, DebtProvider debtProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Gestion des Dettes',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
    );
  }

  Widget _buildDebtSummaryCards(BuildContext context, DebtProvider debtProvider) {
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedCard(
                  child: GlassmorphicCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.red.shade300,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dette Totale',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${debtProvider.totalDebt.toStringAsFixed(0)} FCFA',
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedCard(
                  delay: 200,
                  child: GlassmorphicCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.green.shade300,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Remboursé',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${debtProvider.totalPaidOff.toStringAsFixed(0)} FCFA',
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCard(
            delay: 400,
            child: GlassmorphicCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progrès Global',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${debtProvider.progressPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: debtProvider.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        debtProvider.progressPercentage > 50 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Dettes Actives', '${debtProvider.activeDebts.length}'),
                      _buildStatItem('Paiements Min.', '${debtProvider.totalMinimumPayments.toStringAsFixed(0)} FCFA'),
                      _buildStatItem('Intérêts Est.', '${debtProvider.totalInterestEstimate.toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, DebtProvider debtProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedCard(
              delay: 600,
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.ac_unit,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Boule de Neige',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Plus petites dettes d\'abord',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedCard(
              delay: 800,
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_down,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Avalanche',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Plus hauts taux d\'abord',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context, DebtProvider debtProvider) {
    if (debtProvider.debts.isEmpty) {
      return SliverToBoxAdapter(
        child: AnimatedCard(
          delay: 1000,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune dette enregistrée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez une dette pour commencer le suivi',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final debt = debtProvider.debts[index];
          return AnimatedCard(
            delay: 1000 + (index * 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GlassmorphicCard(
                child: InkWell(
                  onTap: () => _navigateToDebtDetails(context, debt),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getDebtIconColor(debt).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getDebtIcon(debt),
                            color: _getDebtIconColor(debt),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                debt.typeDisplayName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: debt.paidPercentage,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(debt.statusColor),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${debt.currentBalance.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: debt.statusColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${debt.interestRate.toStringAsFixed(1)}% int.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: debtProvider.debts.length,
      ),
    );
  }

  Widget _buildAnimatedFAB(BuildContext context) {
    return BouncyButton(
      onPressed: () => _navigateToAddDebt(context),
      child: FloatingActionButton(
        heroTag: "debt_fab",
        onPressed: () => _navigateToAddDebt(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddDebt(BuildContext context) async {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    await Navigator.of(context).push(
      ModernPageRoute(
        child: const AddEditDebtScreen(),
        routeName: '/add-debt',
      ),
    );
    // Reload debts and custom categories after returning
    if (mounted) {
      await debtProvider.loadDebts();
      await _loadCustomCategories();
    }
  }

  void _navigateToDebtDetails(BuildContext context, Debt debt) async {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    await Navigator.of(context).push(
      ModernPageRoute(
        child: DebtDetailsScreen(debt: debt),
        routeName: '/debt-details',
      ),
    );
    // Reload debts and custom categories after returning
    if (mounted) {
      await debtProvider.loadDebts();
      await _loadCustomCategories();
    }
  }
}