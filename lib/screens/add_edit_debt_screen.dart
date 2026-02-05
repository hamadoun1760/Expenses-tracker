import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../models/custom_debt_type.dart';
import '../models/custom_category.dart';
import '../providers/debt_provider.dart';
import '../helpers/database_helper.dart';

class AddEditDebtScreen extends StatefulWidget {
  final Debt? debt;
  final DebtTransactionType? transactionType;

  const AddEditDebtScreen({super.key, this.debt, this.transactionType});

  @override
  State<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends State<AddEditDebtScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  final _creditorNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  // New West African context controllers
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  // Form data
  DebtType _selectedType = DebtType.creditCard;
  PaymentStrategy _selectedStrategy = PaymentStrategy.snowball;
  DebtStatus _selectedStatus = DebtStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime? _targetPayoffDate;
  DateTime? _echeance; // Due date
  
  // New West African context fields
  DebtTransactionType _selectedTransactionType = DebtTransactionType.dette;
  DebtCategory _selectedCategory = DebtCategory.autre;
  String _selectedCategoryName = '';
  
  // Custom categories
  List<CustomCategory> _customCategories = [];
  
  // Custom debt type fields
  final bool _showCustomTypeField = false;
  final _customTypeController = TextEditingController();
  String _customTypeIcon = 'account_balance';
  
  // Custom debt types list and selected custom type
  List<CustomDebtType> _customDebtTypes = [];
  CustomDebtType? _selectedCustomDebtType;
  String? _selectedDebtTypeId; // Can be either DebtType.toString() or CustomDebtType.id.toString()
  
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  bool _isLoading = false;
  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Initialize default selection
    _selectedDebtTypeId = 'default_${_selectedType.toString()}';
    _selectedCategoryName = _getDebtCategoryDisplayName(_selectedCategory);
    
    // Set transaction type from widget parameter
    if (widget.transactionType != null) {
      _selectedTransactionType = widget.transactionType!;
    }

    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _loadCustomDebtTypes();
      await _loadCustomCategories();
      if (_isEditing) {
        _populateFields();
      }
    } finally {
      setState(() => _isLoading = false);
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
      // Handle error silently or show a snackbar
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      final customCategories = await _databaseHelper.getCustomCategories(type: 'debt');
      setState(() {
        _customCategories = customCategories;
      });
    } catch (e) {
      print('Error loading custom categories: $e');
    }
  }

  void _populateFields() {
    final debt = widget.debt!;
    _nameController.text = debt.name;
    _descriptionController.text = debt.description ?? '';
    _originalAmountController.text = debt.originalAmount.toString();
    _currentBalanceController.text = debt.currentBalance.toString();
    _interestRateController.text = debt.interestRate.toString();
    _minimumPaymentController.text = debt.minimumPayment.toString();
    _creditorNameController.text = debt.creditorName ?? '';
    _accountNumberController.text = debt.accountNumber ?? '';
    
    _selectedType = debt.type;
    _selectedStrategy = debt.strategy;
    _selectedStatus = debt.status;
    _startDate = debt.startDate;
    _targetPayoffDate = debt.targetPayoffDate;
    _selectedTransactionType = debt.transactionType; // Set transaction type from existing debt
    
    // Handle custom debt type
    if (debt.customDebtTypeId != null) {
      _selectedCustomDebtType = _customDebtTypes.firstWhere(
        (ct) => ct.id == debt.customDebtTypeId,
        orElse: () => CustomDebtType(
          id: debt.customDebtTypeId,
          name: 'Custom Type',
          iconName: 'account_balance',
          colorValue: 0xFF1976D2,
          createdAt: DateTime.now(),
        ),
      );
      _selectedDebtTypeId = 'custom_${debt.customDebtTypeId}';
    } else {
      _selectedCustomDebtType = null;
      _selectedDebtTypeId = 'default_${_selectedType.toString()}';
    }

    // Handle category - properly set both enum and display name
    _selectedCategory = debt.category;
    if (debt.customCategoryName != null && debt.customCategoryName!.isNotEmpty) {
      _selectedCategoryName = debt.customCategoryName!;
    } else {
      _selectedCategoryName = _getDebtCategoryDisplayName(debt.category);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _originalAmountController.dispose();
    _currentBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    _creditorNameController.dispose();
    _accountNumberController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.25, 0.5, 0.85],
          colors: [
            const Color(0xFF1976D2),
            const Color(0xFF42A5F5),
            const Color(0xFFBBDEFB),
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 15,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _isLoading && _isEditing
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1976D2),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildForm(),
                        ),
                ),
              ),
            ],
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
                Text(
                  _isEditing ? 'Modifier la Dette' : 'Nouvelle Dette',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ce que je dois',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_down,
              color: Colors.red,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with modern design
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _selectedTransactionType == DebtTransactionType.dette
                    ? [const Color(0xFF1976D2), const Color(0xFF42A5F5)]
                    : [const Color(0xFF388E3C), const Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_selectedTransactionType == DebtTransactionType.dette
                          ? const Color(0xFF1976D2)
                          : const Color(0xFF388E3C))
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedTransactionType == DebtTransactionType.dette
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTransactionType == DebtTransactionType.dette
                            ? 'Ce que je dois'
                            : 'Ce qu\'on me doit',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTransactionType == DebtTransactionType.dette
                            ? 'Argent que vous devez rembourser'
                            : 'Argent qu\'on doit vous rembourser',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFormField(
            controller: _nameController,
            label: 'Nom de la dette',
            icon: Icons.label,
            hintText: 'Ex: Prêt pour mariage, Achat voiture...',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est requis';
              }
              if (value.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _creditorNameController,
            label: 'Nom du créancier',
            icon: Icons.person_outline_rounded,
            hintText: 'Ex: Jean Kouassi, Banque BACI...',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom du créancier est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildAmountField(
            controller: _originalAmountController,
            label: 'Montant original (FCFA)',
            hintText: 'Ex: 100 000',
          ),
          const SizedBox(height: 20),
          _buildAmountField(
            controller: _currentBalanceController,
            label: 'Montant actuel (FCFA)',
            hintText: 'Ex: 75 000',
          ),
          const SizedBox(height: 20),
          _buildDebtTypeDropdown(),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _descriptionController,
            label: 'Description (optionnelle)',
            icon: Icons.description,
            hintText: 'Détails supplémentaires...',
            maxLines: 3,
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Informations Financières',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _originalAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant original *',
                hintText: 'Montant',
                prefixIcon: const Icon(Icons.account_balance),
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Montant requis';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentBalanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Solde actuel *',
                hintText: 'Solde',
                prefixIcon: const Icon(Icons.account_balance_wallet),
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Solde requis';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Solde invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Taux d\'intérêt *',
                hintText: '0.0',
                prefixIcon: const Icon(Icons.percent),
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Taux requis';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate < 0) {
                  return 'Taux invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumPaymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Paiement minimum *',
                hintText: '0',
                prefixIcon: const Icon(Icons.payment),
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Paiement requis';
                }
                final payment = double.tryParse(value);
                if (payment == null || payment <= 0) {
                  return 'Paiement invalide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.details,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Détails Supplémentaires',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditorNameController,
              decoration: InputDecoration(
                labelText: 'Nom du créancier',
                hintText: 'Banque',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Numéro de compte',
                hintText: 'N° compte',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectStartDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date de début',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectTargetDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Objectif de remboursement',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _targetPayoffDate != null
                    ? '${_targetPayoffDate!.day}/${_targetPayoffDate!.month}/${_targetPayoffDate!.year}'
                    : 'Non défini',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Stratégie et Statut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentStrategy>(
              initialValue: _selectedStrategy,
              decoration: InputDecoration(
                labelText: 'Stratégie de remboursement',
                prefixIcon: const Icon(Icons.psychology),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: PaymentStrategy.values.map((strategy) {
                return DropdownMenuItem(
                  value: strategy,
                  child: Text(_getStrategyDisplayName(strategy)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStrategy = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DebtStatus>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Statut',
                prefixIcon: const Icon(Icons.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: DebtStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getStatusDisplayName(status)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon, 
                color: const Color(0xFF1976D2),
                size: 22,
              ),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(
                Icons.payments_rounded,
                color: Color(0xFF1976D2),
                size: 22,
              ),
              suffixText: 'FCFA',
              suffixStyle: const TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est obligatoire';
              }
              final number = double.tryParse(value.replaceAll(' ', ''));
              if (number == null || number <= 0) {
                return 'Veuillez entrer un montant valide';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveDebt,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1976D2),
                    Color(0xFF42A5F5),
                  ],
                ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Text(
                _isEditing ? 'Mettre à Jour la Dette' : 'Créer la Dette',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetPayoffDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (date != null) {
      setState(() {
        _targetPayoffDate = date;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debt = Debt(
        id: _isEditing ? widget.debt!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        customDebtTypeId: _selectedCustomDebtType?.id,
        originalAmount: double.parse(_originalAmountController.text),
        currentBalance: double.parse(_currentBalanceController.text),
        interestRate: double.parse(_interestRateController.text),
        startDate: _startDate,
        targetPayoffDate: _targetPayoffDate,
        minimumPayment: double.parse(_minimumPaymentController.text),
        strategy: _selectedStrategy,
        status: _selectedStatus,
        creditorName: _creditorNameController.text.trim().isEmpty 
            ? null 
            : _creditorNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty 
            ? null 
            : _accountNumberController.text.trim(),
        createdAt: _isEditing ? widget.debt!.createdAt : DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
        transactionType: _selectedTransactionType,
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty
            ? null 
            : _contactPhoneController.text.trim(),
        echeance: _echeance,
        category: _selectedCategory,
        customCategoryName: _isCustomCategory(_selectedCategoryName) ? _selectedCategoryName : null,
      );

      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      
      if (_isEditing) {
        await debtProvider.updateDebt(debt);
      } else {
        await debtProvider.addDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Dette mise à jour avec succès' 
                  : 'Dette créée avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCustomTypeField() {
    final availableIcons = [
      {'name': 'account_balance', 'icon': Icons.account_balance, 'label': 'Banque'},
      {'name': 'business', 'icon': Icons.business, 'label': 'Entreprise'},
      {'name': 'home', 'icon': Icons.home, 'label': 'Maison'},
      {'name': 'person', 'icon': Icons.person, 'label': 'Personnel'},
      {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'Médical'},
      {'name': 'shopping_bag', 'icon': Icons.shopping_bag, 'label': 'Shopping'},
      {'name': 'local_gas_station', 'icon': Icons.local_gas_station, 'label': 'Carburant'},
      {'name': 'phone', 'icon': Icons.phone, 'label': 'Téléphone'},
      {'name': 'wifi', 'icon': Icons.wifi, 'label': 'Internet'},
      {'name': 'power', 'icon': Icons.power, 'label': 'Électricité'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Type personnalisé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customTypeController,
              decoration: InputDecoration(
                labelText: 'Nom du type personnalisé *',
                hintText: 'Ex: Prêt familial',
                prefixIcon: Icon(_getIconFromName(_customTypeIcon)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (_selectedType == DebtType.other && (value == null || value.trim().isEmpty)) {
                  return 'Nom du type requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Choisir une icône:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableIcons.map((iconData) {
                final isSelected = _customTypeIcon == iconData['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _customTypeIcon = iconData['name'] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconData['icon'] as IconData,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          iconData['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDebtTypeDropdown() {
    List<DropdownMenuItem<String>> items = [];
    
    // Add default debt types
    for (DebtType type in DebtType.values) {
      items.add(DropdownMenuItem(
        value: 'default_${type.toString()}',
        child: Text(_getDebtTypeDisplayName(type)),
      ));
    }
    
    // Add custom debt types
    for (CustomDebtType customType in _customDebtTypes) {
      items.add(DropdownMenuItem(
        value: 'custom_${customType.id}',
        child: Text(customType.name),
      ));
    }
    
    // Add "Create new debt type" option
    items.add(DropdownMenuItem(
      value: 'create_new',
      child: Text(
        'Créer nouveau type',
        style: TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de dette',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDebtTypeId,
            style: const TextStyle(color: Color(0xFF1A202C), fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(
                _getCurrentDebtTypeIcon(),
                color: _selectedCustomDebtType?.color ?? const Color(0xFF1976D2),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items,
            onChanged: (value) {
              if (value == 'create_new') {
                _showCreateCustomDebtTypeDialog();
              } else if (value != null) {
                setState(() {
                  _selectedDebtTypeId = value;
                  if (value.startsWith('custom_')) {
                    final customTypeId = int.parse(value.substring(7));
                    _selectedCustomDebtType = _customDebtTypes.firstWhere((ct) => ct.id == customTypeId);
                    _selectedType = DebtType.other; // Keep as other for backend compatibility
                  } else {
                    _selectedCustomDebtType = null;
                    final typeString = value.substring(8); // Remove 'default_'
                    _selectedType = DebtType.values.firstWhere((t) => t.toString() == typeString);
                  }
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner un type de dette';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  IconData _getCurrentDebtTypeIcon() {
    if (_selectedCustomDebtType != null) {
      return _getIconFromName(_selectedCustomDebtType!.iconName);
    }
    return _getDebtTypeIcon(_selectedType);
  }

  void _showCreateCustomDebtTypeDialog() {
    final nameController = TextEditingController();
    String selectedIcon = 'account_balance';
    Color selectedColor = const Color(0xFF1976D2);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxDialogHeight = screenHeight - keyboardHeight - 100;
          
          return AlertDialog(
            title: const Text('Créer un nouveau type de dette'),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxDialogHeight,
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du type de dette',
                          hintText: 'Ex: Prêt familial',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Icône: '),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getIconFromName(selectedIcon), color: selectedColor),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _showIconPicker(setDialogState, (icon) {
                              setDialogState(() => selectedIcon = icon);
                            }),
                            child: const Text('Changer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Couleur: '),
                          const SizedBox(width: 8),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _showColorPicker(setDialogState, (color) {
                              setDialogState(() => selectedColor = color);
                            }),
                            child: const Text('Changer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    return;
                  }
                  
                  final exists = await _databaseHelper.customDebtTypeNameExists(nameController.text.trim());
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ce nom de type de dette existe déjà')),
                    );
                    return;
                  }
                  
                  final newDebtType = CustomDebtType(
                    name: nameController.text.trim(),
                    iconName: selectedIcon,
                    colorValue: selectedColor.value,
                    createdAt: DateTime.now(),
                  );
                  
                  try {
                    final id = await _databaseHelper.insertCustomDebtType(newDebtType);
                    final createdDebtType = newDebtType.copyWith(id: id);
                    
                    setState(() {
                      _customDebtTypes.add(createdDebtType);
                      _selectedDebtTypeId = 'custom_$id';
                      _selectedCustomDebtType = createdDebtType;
                      _selectedType = DebtType.other;
                    });
                    
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Type de dette créé avec succès')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de la création du type de dette')),
                    );
                  }
                },
                child: const Text('Créer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIconPicker(StateSetter setDialogState, Function(String) onIconSelected) {
    final icons = [
      'account_balance', 'credit_card', 'home', 'school', 'directions_car',
      'person', 'business', 'shopping_cart', 'medical_services', 'build',
      'phone', 'computer', 'fitness_center', 'restaurant', 'local_gas_station'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une icône'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  onIconSelected(icons[index]);
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getIconFromName(icons[index])),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(StateSetter setDialogState, Function(Color) onColorSelected) {
    final colors = [
      const Color(0xFF1976D2), const Color(0xFFD32F2F), const Color(0xFF388E3C),
      const Color(0xFFF57C00), const Color(0xFF7B1FA2), const Color(0xFF0097A7),
      const Color(0xFF5D4037), const Color(0xFF455A64), const Color(0xFFE91E63),
      const Color(0xFF00796B), const Color(0xFF3F51B5), const Color(0xFF9E9E9E),
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) => GestureDetector(
              onTap: () {
                onColorSelected(color);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.mortgage:
        return Icons.home;
      case DebtType.studentLoan:
        return Icons.school;
      case DebtType.autoLoan:
        return Icons.directions_car;
      case DebtType.other:
        return _getIconFromName(_customTypeIcon);
    }
  }

  String _getDebtTypeDisplayName(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Carte de crédit';
      case DebtType.personalLoan:
        return 'Prêt personnel';
      case DebtType.mortgage:
        return 'Hypothèque';
      case DebtType.studentLoan:
        return 'Prêt étudiant';
      case DebtType.autoLoan:
        return 'Prêt auto';
      case DebtType.other:
        return _customTypeController.text.isNotEmpty 
            ? _customTypeController.text 
            : 'Autre';
    }
  }

  String _getStrategyDisplayName(PaymentStrategy strategy) {
    switch (strategy) {
      case PaymentStrategy.snowball:
        return 'Boule de neige';
      case PaymentStrategy.avalanche:
        return 'Avalanche';
      case PaymentStrategy.custom:
        return 'Personnalisée';
    }
  }

  String _getStatusDisplayName(DebtStatus status) {
    switch (status) {
      case DebtStatus.active:
        return 'Actif';
      case DebtStatus.paused:
        return 'En pause';
      case DebtStatus.paidOff:
        return 'Remboursé';
      case DebtStatus.defaulted:
        return 'En défaut';
    }
  }

  Color _getStatusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.active:
        return Colors.green;
      case DebtStatus.paused:
        return Colors.orange;
      case DebtStatus.paidOff:
        return Colors.blue;
      case DebtStatus.defaulted:
        return Colors.red;
    }
  }

  Widget _buildCategoryDropdown() {
    final categories = _getCategoriesForDropdown();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catégorie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            GestureDetector(
              onTap: _showAddCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Nouvelle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<String>(
            initialValue: categories.contains(_selectedCategoryName) 
              ? _selectedCategoryName 
              : (categories.isNotEmpty ? categories.first : null),
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.category,
                color: Color(0xFF1976D2),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF1A202C),
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategoryName = value;
                  _selectedCategory = _getCategoryEnum(value);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  List<String> _getCategoriesForDropdown() {
    List<String> categories = [];
    
    // Add default categories
    for (DebtCategory category in DebtCategory.values) {
      categories.add(_getDebtCategoryDisplayName(category));
    }
    
    // Add custom categories
    for (CustomCategory customCategory in _customCategories) {
      categories.add(customCategory.name);
    }
    
    return categories;
  }

  DebtCategory _getCategoryEnum(String categoryName) {
    // Check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => CustomCategory(name: '', type: 'debt', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      return DebtCategory.autre; // Custom categories use 'autre' as the enum value
    }
    
    // Check default categories
    switch (categoryName) {
      case 'Famille':
        return DebtCategory.famille;
      case 'Amis':
        return DebtCategory.amis;
      case 'Banque':
        return DebtCategory.banque;
      case 'Tontine':
        return DebtCategory.tontine;
      case 'Autre':
        return DebtCategory.autre;
      default:
        return DebtCategory.autre;
    }
  }

  String _getDebtCategoryDisplayName(DebtCategory category) {
    switch (category) {
      case DebtCategory.famille:
        return 'Famille';
      case DebtCategory.amis:
        return 'Amis';
      case DebtCategory.banque:
        return 'Banque';
      case DebtCategory.tontine:
        return 'Tontine';
      case DebtCategory.autre:
        return 'Autre';
    }
  }

  bool _isCustomCategory(String categoryName) {
    return _customCategories.any((cat) => cat.name == categoryName);
  }

  String _getCategoryDisplayName(String category) {
    // Check if it's a custom category first
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == category,
      orElse: () => CustomCategory(name: '', type: 'debt', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      return customCategory.name;
    }
    
    // Must be a default category
    return category;
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    String selectedIcon = 'account_balance';
    Color selectedColor = const Color(0xFF1565C0);
    
    final availableIcons = [
      {'name': 'account_balance', 'icon': Icons.account_balance},
      {'name': 'family_restroom', 'icon': Icons.family_restroom},
      {'name': 'groups', 'icon': Icons.groups},
      {'name': 'handshake', 'icon': Icons.handshake},
      {'name': 'savings', 'icon': Icons.savings},
      {'name': 'credit_card', 'icon': Icons.credit_card},
      {'name': 'money', 'icon': Icons.attach_money},
      {'name': 'business', 'icon': Icons.business},
      {'name': 'home', 'icon': Icons.home},
      {'name': 'car', 'icon': Icons.directions_car},
      {'name': 'school', 'icon': Icons.school},
      {'name': 'medical', 'icon': Icons.medical_services},
    ];

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Nouvelle Catégorie de Dette',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la catégorie',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Icône:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableIcons.map((iconData) {
                    final isSelected = selectedIcon == iconData['name'];
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = iconData['name'] as String;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          iconData['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Couleur:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    const Color(0xFF1565C0), // Primary debt blue
                    const Color(0xFF0D47A1), // Dark blue
                    const Color(0xFF1976D2), // Material blue
                    const Color(0xFF424242), // Dark grey
                    const Color(0xFF37474F), // Blue grey
                    const Color(0xFF263238), // Dark blue grey
                    const Color(0xFF3F51B5), // Indigo
                    const Color(0xFF512DA8), // Deep purple
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final categoryName = nameController.text.trim();
                
                if (categoryName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom de la catégorie ne peut pas être vide'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Check if category already exists
                final existingCategories = await _databaseHelper.getCustomCategories(type: 'debt');
                final duplicateExists = existingCategories.any((cat) => cat.name.toLowerCase() == categoryName.toLowerCase());
                
                if (duplicateExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Une catégorie nommée "$categoryName" existe déjà'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                try {
                  final newCategory = CustomCategory(
                    name: categoryName,
                    type: 'debt',
                    iconName: selectedIcon,
                    colorValue: selectedColor.value,
                    createdAt: DateTime.now(),
                  );
                  
                  await _databaseHelper.insertCustomCategory(newCategory);
                  await _loadCustomCategories();
                  
                  setState(() {
                    _selectedCategoryName = categoryName;
                    _selectedCategory = DebtCategory.autre; // Custom categories use 'autre'
                  });
                  
                  Navigator.of(context).pop(true);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Catégorie "$categoryName" créée avec succès'),
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                  );
                  
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la création: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}