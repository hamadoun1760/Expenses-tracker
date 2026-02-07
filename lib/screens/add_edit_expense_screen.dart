import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';
import '../config/category_config.dart' as category_config;

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final Map<String, dynamic>? initialData;

  const AddEditExpenseScreen({super.key, this.expense, this.initialData});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  String _selectedCategory = category_config.CategoryConfig.categories.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<CustomCategory> _customCategories = [];
  List<String> _allCategories = [];

  @override
  void initState() {
    super.initState();
    
    _loadCategories();
    
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    } else if (widget.initialData != null) {
      final data = widget.initialData!;
      _titleController.text = data['title'] ?? '';
      _amountController.text = (data['amount'] ?? 0.0).toString();
      _descriptionController.text = data['description'] ?? '';
      _selectedCategory = data['category'] ?? category_config.CategoryConfig.categories.first;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final customCategories = await _databaseHelper.getCustomCategories(type: 'expense');
      setState(() {
        _customCategories = customCategories;
        _allCategories = [
          ...category_config.CategoryConfig.categories,
          ...customCategories.map((c) => c.name),
        ];
      });
    } catch (e) {
      setState(() {
        _allCategories = category_config.CategoryConfig.categories;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFD32F2F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = Expense(
        id: widget.expense?.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        date: _selectedDate,
      );

      if (widget.expense == null) {
        await _databaseHelper.insertExpense(expense);
      } else {
        await _databaseHelper.updateExpense(expense);
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

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.25, 0.5, 0.85],
          colors: [
            Color(0xFFD32F2F),
            Color(0xFFE57373),
            Color(0xFFFFCDD2),
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
                  isEditing ? 'Modifier Dépense' : 'Nouvelle Dépense',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Suivi de vos dépenses',
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
              onTap: _saveExpense,
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
    final isEditing = widget.expense != null;
    
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
                  Color(0xFFD32F2F),
                  Color(0xFFE57373),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
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
                    Icons.receipt_long_rounded,
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
                        isEditing ? 'Modifier une dépense' : 'Ajouter une dépense',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enregistrez vos dépenses quotidiennes',
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
            label: 'Titre de la dépense',
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Courses, Restaurant, Essence...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFFD32F2F)),
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
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildDateField(),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description (optionnelle)',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajoutez des détails sur cette dépense...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFFD32F2F)),
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
            hintText: 'Ex: 5 000',
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
            prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFFD32F2F)),
            suffixText: 'FCFA',
            suffixStyle: const TextStyle(
              color: Color(0xFFD32F2F),
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

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégorie',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFFD32F2F)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _allCategories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_getCategoryDisplayName(context, category)),
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
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
                const Icon(Icons.calendar_today_rounded, color: Color(0xFFD32F2F)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
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
    final isEditing = widget.expense != null;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD32F2F),
            Color(0xFFE57373),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _saveExpense,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEditing ? 'MODIFIER DÉPENSE' : 'AJOUTER DÉPENSE',
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