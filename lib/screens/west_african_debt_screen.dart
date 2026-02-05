import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../models/custom_debt_type.dart';
import '../providers/debt_provider.dart';
import '../helpers/database_helper.dart';
import 'simple_add_debt_screen.dart';
import 'debt_details_screen.dart';

class WestAfricanDebtScreen extends StatefulWidget {
  const WestAfricanDebtScreen({super.key});

  @override
  State<WestAfricanDebtScreen> createState() => _WestAfricanDebtScreenState();
}

class _WestAfricanDebtScreenState extends State<WestAfricanDebtScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<CustomDebtType> _customDebtTypes = [];
  
  int _selectedTab = 0; // 0: Dettes, 1: Créances

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
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Load custom debt types first, then debts
    await _loadCustomDebtTypes();
    if (mounted) {
      Provider.of<DebtProvider>(context, listen: false).loadDebts();
      _fadeController.forward();
    }
  }

  Future<void> _loadCustomDebtTypes() async {
    try {
      final customDebtTypes = await _databaseHelper.getCustomDebtTypes();
      setState(() {
        _customDebtTypes = customDebtTypes;
      });
    } catch (e) {
      debugPrint('Error loading custom debt types: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  IconData _getDebtIcon(Debt debt) {
    if (debt.customDebtTypeId != null) {
      final customType = _customDebtTypes.firstWhere(
        (ct) => ct.id == debt.customDebtTypeId,
        orElse: () => CustomDebtType(
          id: debt.customDebtTypeId,
          name: 'Custom Type',
          iconName: 'account_balance',
          colorValue: 0xFF1976D2,
          createdAt: DateTime.now(),
        ),
      );
      return _getIconFromName(customType.iconName);
    }
    return debt.typeIcon;
  }

  Color _getDebtIconColor(Debt debt) {
    if (debt.customDebtTypeId != null) {
      final customType = _customDebtTypes.firstWhere(
        (ct) => ct.id == debt.customDebtTypeId,
        orElse: () => CustomDebtType(
          id: debt.customDebtTypeId,
          name: 'Custom Type',
          iconName: 'account_balance',
          colorValue: 0xFF1976D2,
          createdAt: DateTime.now(),
        ),
      );
      return customType.color;
    }
    
    // Use the debt type's color
    return debt.typeColor;
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
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'account_balance':
      default:
        return Icons.account_balance;
    }
  }

  String _getDebtTypeDisplayName(Debt debt) {
    if (debt.customDebtTypeId != null) {
      try {
        final customType = _customDebtTypes.firstWhere(
          (ct) => ct.id == debt.customDebtTypeId,
        );
        return customType.name;
      } catch (e) {
        return 'Type personnalisé';
      }
    }
    return debt.typeDisplayName;
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
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              _buildSummaryCards(),
              Expanded(child: _buildDebtsList()),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleAddDebtScreen(
                      transactionType: _selectedTab == 0 
                          ? DebtTransactionType.dette 
                          : DebtTransactionType.creance,
                    ),
                  ),
                ).then((_) {
                  Provider.of<DebtProvider>(context, listen: false).loadDebts();
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Dettes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Dettes & Créances FCFA',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: const Color(0xFFFFB74D),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 
                      ? Colors.red.shade600 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Dettes (Ce que je dois)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 
                      ? Colors.green.shade600 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Créances (Ce qu\'on me doit)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<DebtProvider>(
      builder: (context, debtProvider, child) {
        final debts = debtProvider.debts;
        final dettes = debts.where((d) => d.transactionType == DebtTransactionType.dette).toList();
        final creances = debts.where((d) => d.transactionType == DebtTransactionType.creance).toList();
        
        final currentDebts = _selectedTab == 0 ? dettes : creances;
        final totalAmount = currentDebts.fold(0.0, (sum, debt) => sum + debt.currentBalance);
        final activeCount = currentDebts.where((d) => d.status == DebtStatus.active).length;
        
        return Container(
          margin: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: _selectedTab == 0 ? 'Total Dettes' : 'Total Créances',
                  amount: totalAmount,
                  color: _selectedTab == 0 ? Colors.red.shade600 : Colors.green.shade600,
                  icon: _selectedTab == 0 ? Icons.trending_down : Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'En Cours',
                  amount: activeCount.toDouble(),
                  color: const Color(0xFFFFB74D),
                  icon: Icons.access_time,
                  isCount: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCount 
                ? amount.toInt().toString()
                : '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]} ')} FCFA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList() {
    return Consumer<DebtProvider>(
      builder: (context, debtProvider, child) {
        final debts = debtProvider.debts;
        final filteredDebts = debts.where((debt) {
          return _selectedTab == 0 
              ? debt.transactionType == DebtTransactionType.dette
              : debt.transactionType == DebtTransactionType.creance;
        }).toList();

        if (filteredDebts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredDebts.length,
          itemBuilder: (context, index) {
            final debt = filteredDebts[index];
            return _buildDebtCard(debt);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A000000),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _selectedTab == 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              size: 64,
              color: _selectedTab == 0 ? const Color(0xFF1976D2) : const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedTab == 0 
                ? 'Aucune dette enregistrée'
                : 'Aucune créance enregistrée',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 0
                ? 'Commencez par ajouter une dette'
                : 'Commencez par ajouter une créance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isCreance = debt.transactionType == DebtTransactionType.creance;
    final baseColor = _getDebtIconColor(debt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDebtDetails(context, debt),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          baseColor,
                          baseColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getDebtIcon(debt),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                debt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getDebtIconColor(debt).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getDebtIconColor(debt).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getDebtTypeDisplayName(debt),
                                style: TextStyle(
                                  color: _getDebtIconColor(debt),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: const Color(0xFF718096),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                debt.contactName ?? 'Contact non spécifié',
                                style: const TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant',
                          style: TextStyle(
                            color: const Color(0xFF718096),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          debt.formattedCurrentBalance,
                          style: TextStyle(
                            color: debt.transactionType == DebtTransactionType.creance ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (debt.echeance != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Échéance',
                            style: TextStyle(
                              color: const Color(0xFF718096),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${debt.echeance!.day}/${debt.echeance!.month}/${debt.echeance!.year}',
                            style: TextStyle(
                              color: DateTime.now().isAfter(debt.echeance!) 
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2D3748),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddDebt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleAddDebtScreen(
          transactionType: _selectedTab == 0 
              ? DebtTransactionType.dette 
              : DebtTransactionType.creance,
        ),
      ),
    ).then((_) {
      Provider.of<DebtProvider>(context, listen: false).loadDebts();
    });
  }

  void _navigateToDebtDetails(BuildContext context, Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebtDetailsScreen(debt: debt),
      ),
    ).then((_) {
      Provider.of<DebtProvider>(context, listen: false).loadDebts();
    });
  }
}