import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';
import '../utils/theme.dart';
import '../config/category_config.dart' as config;
import '../config/income_config.dart';

class AddEditRecurringTransactionScreen extends StatefulWidget {
  final RecurringTransaction? transaction;

  const AddEditRecurringTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditRecurringTransactionScreen> createState() => _AddEditRecurringTransactionScreenState();
}

class _AddEditRecurringTransactionScreenState extends State<AddEditRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  String _selectedType = 'expense';
  String _selectedCategory = '';
  String _selectedFrequency = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _maxOccurrences;
  bool _isLoading = false;
  bool _hasEndDate = false;
  bool _hasMaxOccurrences = false;
  List<CustomCategory> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    if (widget.transaction != null) {
      _loadTransactionData();
    } else {
      _selectedCategory = config.CategoryConfig.categories.first;
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      final customCategories = await _databaseHelper.getCustomCategories();
      setState(() {
        _customCategories = customCategories;
      });
    } catch (e) {
      print('Error loading custom categories: $e');
    }
  }

  void _loadTransactionData() {
    final transaction = widget.transaction!;
    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    _selectedCategory = transaction.category;
    _selectedFrequency = transaction.frequency;
    _startDate = transaction.startDate;
    _endDate = transaction.endDate;
    _maxOccurrences = transaction.maxOccurrences;
    _hasEndDate = transaction.endDate != null;
    _hasMaxOccurrences = transaction.maxOccurrences != null;
  }

  List<String> _getAvailableCategories() {
    if (_selectedType == 'income') {
      final incomeCustomCategories = _customCategories
          .where((cat) => cat.type == 'income')
          .map((cat) => cat.name)
          .toList();
      return [...incomeCustomCategories, ...IncomeConfig.categories];
    } else {
      final expenseCustomCategories = _customCategories
          .where((cat) => cat.type == 'expense')
          .map((cat) => cat.name)
          .toList();
      return [...expenseCustomCategories, ...config.CategoryConfig.categories];
    }
  }

  String _getCategoryDisplayName(String categoryKey) {
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == categoryKey,
      orElse: () => CustomCategory(name: '', type: 'expense', iconName: '', colorValue: 0, createdAt: DateTime.now()),
    );
    
    if (customCategory.name.isNotEmpty) {
      return customCategory.name;
    }
    
    if (_selectedType == 'income') {
      switch (categoryKey) {
        case 'salary':
          return 'Salaire';
        case 'business':
          return 'Affaires';
        case 'investment':
          return 'Investissement';
        case 'gift':
          return 'Cadeau';
        case 'other':
          return 'Autre';
        default:
          return categoryKey;
      }
    } else {
      switch (categoryKey) {
        case 'food':
          return 'Alimentation';
        case 'transportation':
          return 'Transport';
        case 'shopping':
          return 'Achats';
        case 'entertainment':
          return 'Divertissement';
        case 'health':
          return 'Santé';
        case 'education':
          return 'Éducation';
        case 'other':
          return 'Autre';
        default:
          return categoryKey;
      }
    }
  }

  String _getFrequencyDisplayName(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return frequency;
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    String selectedIcon = 'category';
    Color selectedColor = const Color(0xFF00695C);

    final availableIcons = [
      {'name': 'category', 'icon': Icons.category},
      {'name': 'restaurant', 'icon': Icons.restaurant},
      {'name': 'directions_car', 'icon': Icons.directions_car},
      {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
      {'name': 'movie', 'icon': Icons.movie},
      {'name': 'medical_services', 'icon': Icons.medical_services},
      {'name': 'school', 'icon': Icons.school},
      {'name': 'work', 'icon': Icons.work},
      {'name': 'business', 'icon': Icons.business},
      {'name': 'monetization_on', 'icon': Icons.monetization_on},
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Nouvelle Catégorie',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00695C),
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
                    const Color(0xFF00695C),
                    const Color(0xFFD32F2F),
                    const Color(0xFF1976D2),
                    const Color(0xFF388E3C),
                    const Color(0xFFF57C00),
                    const Color(0xFF7B1FA2),
                    const Color(0xFFE64A19),
                    const Color(0xFF455A64),
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
                      content: Text('Veuillez entrer un nom pour la catégorie'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Check if category already exists
                final existingCategories = await _databaseHelper.getCustomCategories(type: _selectedType);
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
                    type: _selectedType,
                    iconName: selectedIcon,
                    colorValue: selectedColor.value,
                    createdAt: DateTime.now(),
                  );
                  
                  await _databaseHelper.insertCustomCategory(newCategory);
                  await _loadCustomCategories();
                  
                  setState(() {
                    _selectedCategory = categoryName;
                  });
                  
                  Navigator.of(context).pop(true);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Catégorie "$categoryName" créée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Créer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate.add(const Duration(days: 30))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF00695C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = RecurringTransaction(
        id: widget.transaction?.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: _selectedCategory,
        frequency: _selectedFrequency,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        maxOccurrences: _hasMaxOccurrences ? _maxOccurrences : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        nextDueDate: _startDate,
      );

      if (widget.transaction == null) {
        await _databaseHelper.insertRecurringTransaction(transaction);
      } else {
        await _databaseHelper.updateRecurringTransaction(transaction);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.25, 0.5, 0.85],
          colors: [
            Color(0xFF00695C),
            Color(0xFF26A69A),
            Color(0xFFB2DFDB),
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isEditing),
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

  Widget _buildHeader(bool isEditing) {
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
                  isEditing ? 'Modifier Récurrence' : 'Nouvelle Récurrence',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Transactions automatiques',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          else
            GestureDetector(
              onTap: _saveTransaction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SAUVER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final isEditing = widget.transaction != null;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with modern design
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00695C),
                  Color(0xFF26A69A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00695C).withOpacity(0.3),
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
                  child: const Icon(
                    Icons.repeat_rounded,
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
                        isEditing ? 'Modifier une récurrence' : 'Ajouter une récurrence',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configurez vos transactions automatiques',
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
            label: 'Titre de la transaction',
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Loyer, Salaire, Abonnement...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF00695C)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildAmountField(),
          const SizedBox(height: 20),
          _buildTypeDropdown(),
          const SizedBox(height: 20),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildFrequencyDropdown(),
          const SizedBox(height: 20),
          _buildStartDateField(),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description (optionnelle)',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajoutez des détails sur cette récurrence...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF00695C)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
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
        child,
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
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Ex: 75 000',
            hintStyle: TextStyle(
              color: const Color(0xFF2D3748).withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFF00695C)),
            suffixText: 'FCFA',
            suffixStyle: const TextStyle(
              color: Color(0xFF00695C),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le montant est obligatoire';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Veuillez entrer un montant valide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de transaction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF00695C)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: const [
            DropdownMenuItem(value: 'expense', child: Text('Dépense')),
            DropdownMenuItem(value: 'income', child: Text('Revenu')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
              final categories = _getAvailableCategories();
              if (categories.isNotEmpty) {
                _selectedCategory = categories.first;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _getAvailableCategories();
    if (_selectedCategory.isEmpty && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showAddCategoryDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C),
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
        DropdownButtonFormField<String>(
          value: categories.contains(_selectedCategory) ? _selectedCategory : (categories.isNotEmpty ? categories.first : null),
          decoration: InputDecoration(
            hintText: 'Sélectionnez une catégorie',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF00695C)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
          ),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                _getCategoryDisplayName(category),
                style: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fréquence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFrequency,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.schedule_rounded, color: Color(0xFF00695C)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Quotidien')),
            DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
            DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
            DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFrequency = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStartDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de début',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context, true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF00695C)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_startDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isEditing = widget.transaction != null;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00695C),
            Color(0xFF26A69A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _saveTransaction,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEditing ? 'MODIFIER RÉCURRENCE' : 'CRÉER RÉCURRENCE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}