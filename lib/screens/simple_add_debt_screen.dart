import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../models/custom_category.dart';
import '../models/custom_debt_type.dart';
import '../providers/debt_provider.dart';
import '../helpers/database_helper.dart';

class SimpleAddDebtScreen extends StatefulWidget {
  final DebtTransactionType transactionType;
  final Debt? debt;

  const SimpleAddDebtScreen({
    super.key,
    required this.transactionType,
    this.debt,
  });

  @override
  State<SimpleAddDebtScreen> createState() => _SimpleAddDebtScreenState();
}

class _SimpleAddDebtScreenState extends State<SimpleAddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form data
  DebtType _selectedType = DebtType.creditCard;
  List<CustomDebtType> _customDebtTypes = [];
  CustomDebtType? _selectedCustomDebtType;
  String? _selectedDebtTypeId;
  
  DebtCategory _selectedCategory = DebtCategory.autre;
  String _selectedCategoryName = '';
  List<CustomCategory> _customCategories = [];
  DateTime? _echeance;
  bool _isLoading = false;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    _selectedDebtTypeId = 'default_${_selectedType.toString()}';
    _selectedCategoryName = _getCategoryDisplayName(_selectedCategory);
    _loadCustomDebtTypes();
    _loadCustomCategories();
    if (_isEditing) {
      _populateFields();
    }
  }

  Future<void> _loadCustomDebtTypes() async {
    try {
      final customDebtTypes = await _databaseHelper.getCustomDebtTypes();
      setState(() {
        _customDebtTypes = customDebtTypes;
        // After loading custom debt types, populate the selected debt type if editing
        if (_isEditing && widget.debt?.customDebtTypeId != null) {
          try {
            final customType = _customDebtTypes.firstWhere(
              (ct) => ct.id == widget.debt!.customDebtTypeId,
            );
            _selectedCustomDebtType = customType;
            _selectedDebtTypeId = 'custom_${widget.debt!.customDebtTypeId}';
            _selectedType = DebtType.other;
          } catch (e) {
            // Custom type not found, use default
            _selectedCustomDebtType = null;
          }
        }
      });
    } catch (e) {
      print('Error loading custom debt types: $e');
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
    _contactNameController.text = debt.contactName;
    _contactPhoneController.text = debt.contactPhone ?? '';
    _amountController.text = debt.currentBalance.toString();
    _minimumPaymentController.text = debt.minimumPayment.toString();
    _descriptionController.text = debt.description ?? '';
    _selectedCategory = debt.category;
    if (debt.customCategoryName != null && debt.customCategoryName!.isNotEmpty) {
      _selectedCategoryName = debt.customCategoryName!;
    } else {
      _selectedCategoryName = _getCategoryDisplayName(debt.category);
    }
    _echeance = debt.echeance;
    
    // Populate debt type
    if (debt.customDebtTypeId != null) {
      _selectedDebtTypeId = 'custom_${debt.customDebtTypeId}';
      _selectedType = DebtType.other;
    } else {
      _selectedDebtTypeId = 'default_${debt.type.toString()}';
      _selectedType = debt.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _amountController.dispose();
    _minimumPaymentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreance = widget.transactionType == DebtTransactionType.creance;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.25, 0.5, 0.85],
          colors: isCreance ? [
            const Color(0xFF2E7D32),
            const Color(0xFF4CAF50),
            const Color(0xFF81C784),
            Colors.white,
          ] : [
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
                  child: SingleChildScrollView(
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
    final isCreance = widget.transactionType == DebtTransactionType.creance;
    
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
                  _isEditing
                      ? (isCreance ? 'Modifier Créance' : 'Modifier Dette')
                      : (isCreance ? 'Nouvelle Créance' : 'Nouvelle Dette'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isCreance ? 'Ce qu\'on me doit' : 'Ce que je dois',
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
              color: (isCreance ? Colors.green : Colors.red).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCreance ? Icons.trending_up : Icons.trending_down,
              color: isCreance ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final isCreance = widget.transactionType == DebtTransactionType.creance;
    
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
                colors: isCreance ? [
                  const Color(0xFF4CAF50),
                  const Color(0xFF66BB6A),
                ] : [
                  const Color(0xFF1976D2),
                  const Color(0xFF42A5F5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isCreance ? const Color(0xFF4CAF50) : const Color(0xFF1976D2)).withOpacity(0.3),
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
                    isCreance ? Icons.trending_up_rounded : Icons.trending_down_rounded,
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
                        isCreance ? 'Ce qu\'on me doit' : 'Ce que je dois',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCreance 
                            ? 'Argent qui vous sera remboursé'
                            : 'Argent que vous devez rembourser',
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
            label: 'Nom de la ${widget.transactionType == DebtTransactionType.dette ? 'dette' : 'créance'}',
            icon: Icons.label,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildContactField(),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _contactPhoneController,
            label: 'Téléphone (optionnel)',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          _buildAmountField(),
          const SizedBox(height: 20),
          _buildMinimumPaymentField(),
          const SizedBox(height: 20),
          _buildDebtTypeDropdown(),
          const SizedBox(height: 20),
          _buildDateField(),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _descriptionController,
            label: 'Description (optionnelle)',
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }

  String _getHintText(String label) {
    switch (label.toLowerCase()) {
      case 'nom de la dette':
      case 'nom de la créance':
        return 'Ex: Prêt pour mariage, Achat voiture...';
      case 'nom du contact':
        return 'Ex: Jean Kouassi, Marie Assi...';
      case 'téléphone (optionnel)':
        return '+225 XX XX XX XX XX';
      case 'montant (fcfa)':
        return 'Ex: 50000';
      case 'description (optionnelle)':
        return 'Détails supplémentaires...';
      default:
        return '';
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
              hintText: _getHintText(label),
              hintStyle: TextStyle(
                color: const Color(0xFF718096),
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

  Widget _buildContactField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nom du contact',
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
          child: TextFormField(
            controller: _contactNameController,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Jean Kouassi, Marie Assi...',
              hintStyle: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF1976D2),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.contacts_rounded,
                  color: Color(0xFF1976D2),
                  size: 22,
                ),
                onPressed: _pickContact,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom du contact est obligatoire';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Montant (FCFA)',
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
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: 50 000',
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                
                final number = int.tryParse(newValue.text.replaceAll(' ', ''));
                if (number == null) return oldValue;
                
                final formatted = number.toString().replaceAllMapped(
                  RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'),
                  (Match m) => '${m[1]} ',
                );
                
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
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

  Widget _buildMinimumPaymentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paiement Minimum (FCFA)',
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
          child: TextFormField(
            controller: _minimumPaymentController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: 10 000',
              hintStyle: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(
                Icons.payment,
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                
                final number = int.tryParse(newValue.text.replaceAll(' ', ''));
                if (number == null) return oldValue;
                
                final formatted = number.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]} ',
                );
                
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est obligatoire';
              }
              final number = double.tryParse(value.replaceAll(' ', ''));
              if (number == null || number < 0) {
                return 'Veuillez entrer un montant valide';
              }
              return null;
            },
          ),
        ),
      ],
    );
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

  Widget _buildDebtTypeDropdown() {
    List<DropdownMenuItem<String>> items = [];
    
    // Add default debt types
    for (DebtType type in DebtType.values) {
      items.add(DropdownMenuItem(
        value: 'default_${type.toString()}',
        child: Text(_getDebtTypeDisplayName(type)),
      ));
    }
    
    // Add custom debt types with edit/delete options
    for (CustomDebtType customType in _customDebtTypes) {
      items.add(DropdownMenuItem(
        value: 'custom_${customType.id}',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(customType.name),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showEditCustomDebtTypeDialog(customType);
                    },
                    child: Icon(Icons.edit, size: 16, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showDeleteConfirmationDialog(customType);
                    },
                    child: Icon(Icons.delete, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    _selectedType = DebtType.other;
                  } else {
                    _selectedCustomDebtType = null;
                    // Extract the DebtType value (e.g., "DebtType.creditCard" from "default_DebtType.creditCard")
                    final typeString = value.replaceFirst('default_', '');
                    try {
                      _selectedType = DebtType.values.firstWhere(
                        (t) => t.toString() == typeString,
                        orElse: () => DebtType.creditCard,
                      );
                    } catch (e) {
                      _selectedType = DebtType.creditCard;
                    }
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Échéance (optionnelle)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF1976D2),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _echeance != null
                        ? '${_echeance!.day}/${_echeance!.month}/${_echeance!.year}'
                        : 'Aucune échéance définie',
                    style: TextStyle(
                      color: _echeance != null 
                          ? const Color(0xFF1A202C)
                          : const Color(0xFF718096),
                      fontSize: 16,
                      fontWeight: _echeance != null 
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (_echeance != null)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color(0xFF718096),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _echeance = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.transactionType == DebtTransactionType.creance
              ? [Colors.green.shade600, Colors.green.shade800]
              : [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (widget.transactionType == DebtTransactionType.creance
                    ? Colors.green.shade600
                    : Colors.red.shade600)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveDebt,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isEditing
                    ? 'Mettre à jour'
                    : 'Enregistrer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  String _getDebtTypeDisplayName(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Carte de crédit';
      case DebtType.personalLoan:
        return 'Prêt personnel';
      case DebtType.mortgage:
        return 'Hypothèque';
      case DebtType.autoLoan:
        return 'Prêt automobile';
      case DebtType.studentLoan:
        return 'Prêt étudiant';
      case DebtType.other:
        return 'Autre';
    }
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.money;
      case DebtType.mortgage:
        return Icons.home;
      case DebtType.autoLoan:
        return Icons.directions_car;
      case DebtType.studentLoan:
        return Icons.school;
      case DebtType.other:
        return Icons.account_balance;
    }
  }

  String _getCategoryDisplayName(DebtCategory category) {
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

  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          setState(() {
            _contactNameController.text = contact.displayName;
            if (contact.phones.isNotEmpty) {
              _contactPhoneController.text = contact.phones.first.number;
            }
          });
        }
      } else {
        // Show permission denied message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission d\'accès aux contacts refusée'),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection du contact'),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _echeance ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (date != null) {
      setState(() {
        _echeance = date;
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
      final amount = double.parse(_amountController.text.replaceAll(' ', ''));
      final minimumPayment = double.tryParse(_minimumPaymentController.text.replaceAll(' ', '')) ?? 0.0;
      
      // Parse the selected debt type ID to extract custom debt type ID if applicable
      int? customDebtTypeId;
      DebtType debtType = _selectedType;
      
      if (_selectedDebtTypeId != null && _selectedDebtTypeId!.startsWith('custom_')) {
        final idString = _selectedDebtTypeId!.replaceFirst('custom_', '');
        customDebtTypeId = int.tryParse(idString);
      }
      
      final debt = Debt(
        id: _isEditing ? widget.debt!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: debtType,
        originalAmount: amount,
        currentBalance: amount,
        interestRate: 0.0,
        startDate: DateTime.now(),
        minimumPayment: minimumPayment,
        strategy: PaymentStrategy.custom,
        status: DebtStatus.active,
        createdAt: _isEditing ? widget.debt!.createdAt : DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
        transactionType: widget.transactionType,
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty
            ? null 
            : _contactPhoneController.text.trim(),
        echeance: _echeance,
        category: _selectedCategory,
        customCategoryName: _isCustomCategory(_selectedCategoryName) ? _selectedCategoryName : null,
        customDebtTypeId: customDebtTypeId,
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
                  : 'Dette ajoutée avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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

  List<String> _getCategoriesForDropdown() {
    List<String> categories = [];
    
    // Add default categories
    for (DebtCategory category in DebtCategory.values) {
      categories.add(_getCategoryDisplayName(category));
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

  bool _isCustomCategory(String categoryName) {
    return _customCategories.any((cat) => cat.name == categoryName);
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
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Créer un nouveau type de dette'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
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
                      Expanded(
                        child: TextButton(
                          onPressed: () => _showIconPicker(setDialogState, (icon) {
                            setDialogState(() => selectedIcon = icon);
                          }),
                          child: const Text('Changer'),
                        ),
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
                      Expanded(
                        child: TextButton(
                          onPressed: () => _showColorPicker(setDialogState, (color) {
                            setDialogState(() => selectedColor = color);
                          }),
                          child: const Text('Changer'),
                        ),
                      ),
                    ],
                  ),
                ],
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
        ),
      ),
    );
  }

  void _showEditCustomDebtTypeDialog(CustomDebtType customType) {
    final nameController = TextEditingController(text: customType.name);
    String selectedIcon = customType.iconName;
    Color selectedColor = customType.color;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le type de dette'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du type de dette',
                  ),
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
                
                final exists = await _databaseHelper.customDebtTypeNameExists(
                  nameController.text.trim(),
                  excludeId: customType.id,
                );
                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ce nom de type de dette existe déjà')),
                  );
                  return;
                }
                
                final updatedType = customType.copyWith(
                  name: nameController.text.trim(),
                  iconName: selectedIcon,
                  colorValue: selectedColor.value,
                );
                
                try {
                  await _databaseHelper.updateCustomDebtType(updatedType);
                  
                  setState(() {
                    final index = _customDebtTypes.indexWhere((ct) => ct.id == customType.id);
                    if (index != -1) {
                      _customDebtTypes[index] = updatedType;
                      if (_selectedCustomDebtType?.id == customType.id) {
                        _selectedCustomDebtType = updatedType;
                      }
                    }
                  });
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Type de dette modifié avec succès')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de la modification')),
                  );
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(CustomDebtType customType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le type de dette'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${customType.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _databaseHelper.deleteCustomDebtType(customType.id!);
                
                setState(() {
                  _customDebtTypes.removeWhere((ct) => ct.id == customType.id);
                  if (_selectedCustomDebtType?.id == customType.id) {
                    _selectedCustomDebtType = null;
                    _selectedDebtTypeId = 'default_${_selectedType.toString()}';
                    _selectedType = DebtType.creditCard;
                  }
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Type de dette supprimé')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur lors de la suppression')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
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
}
