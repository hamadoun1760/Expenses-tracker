import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../helpers/database_helper.dart';

class AddEditGoalScreen extends StatefulWidget {
  final Goal? goal;

  const AddEditGoalScreen({
    super.key,
    this.goal,
  });

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  GoalType _selectedType = GoalType.savings;
  GoalPriority _selectedPriority = GoalPriority.medium;
  GoalStatus _selectedStatus = GoalStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _selectedIcon = 'flag';
  Color _selectedColor = const Color(0xFF7B1FA2);
  Account? _selectedAccount;
  List<Account> _accounts = [];
  bool _isLoading = false;

  // Available icons for goals
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'flag', 'icon': Icons.flag},
    {'name': 'savings', 'icon': Icons.savings},
    {'name': 'trending_up', 'icon': Icons.trending_up},
    {'name': 'trending_down', 'icon': Icons.trending_down},
    {'name': 'payment', 'icon': Icons.payment},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'car', 'icon': Icons.directions_car},
    {'name': 'travel', 'icon': Icons.flight},
    {'name': 'education', 'icon': Icons.school},
    {'name': 'health', 'icon': Icons.local_hospital},
    {'name': 'gift', 'icon': Icons.card_giftcard},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
  ];

  // Available colors for goals
  final List<Color> _availableColors = [
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFF512DA8), // Deep Purple
    const Color(0xFF303F9F), // Indigo
    const Color(0xFF1976D2), // Blue
    const Color(0xFF0288D1), // Light Blue
    const Color(0xFF0097A7), // Cyan
    const Color(0xFF00796B), // Teal
    const Color(0xFF388E3C), // Green
    const Color(0xFF689F38), // Light Green
    const Color(0xFFAFB42B), // Lime
    const Color(0xFFFF8F00), // Amber
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFFE64A19), // Orange Red
    const Color(0xFFD32F2F), // Red
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descriptionController.text = widget.goal!.description ?? '';
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _selectedType = widget.goal!.type;
      _selectedPriority = widget.goal!.priority;
      _selectedStatus = widget.goal!.status;
      _startDate = widget.goal!.startDate;
      _targetDate = widget.goal!.targetDate;
      _selectedIcon = widget.goal!.iconName;
      _selectedColor = Color(widget.goal!.colorValue);
      _selectedAccount = _accounts.firstWhere(
        (account) => account.id == widget.goal!.accountId,
        orElse: () => _accounts.isNotEmpty ? _accounts.first : Account(id: 0, name: '', type: AccountType.savings, initialBalance: 0, currentBalance: 0, iconName: 'savings', colorValue: Colors.blue.value, createdAt: DateTime.now()),
      );
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _databaseHelper.getAccounts();
      setState(() {
        _accounts = accounts;
        if (_selectedAccount == null && accounts.isNotEmpty) {
          _selectedAccount = accounts.first;
        }
      });
    } catch (e) {
      print('Error loading accounts: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _targetDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF7B1FA2),
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
          if (_startDate.isAfter(_targetDate)) {
            _targetDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _targetDate = picked;
          if (_targetDate.isBefore(_startDate)) {
            _startDate = _targetDate.subtract(const Duration(days: 30));
          }
        }
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un compte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final goal = Goal(
        id: widget.goal?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: double.parse(_currentAmountController.text),
        type: _selectedType,
        priority: _selectedPriority,
        status: _selectedStatus,
        startDate: _startDate,
        targetDate: _targetDate,
        iconName: _selectedIcon,
        colorValue: _selectedColor.value,
        accountId: _selectedAccount!.id,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
      );

      if (widget.goal == null) {
        await _databaseHelper.insertGoal(goal);
      } else {
        await _databaseHelper.updateGoal(goal);
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

  String _getTypeDisplayName(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Épargne';
      case GoalType.expense:
        return 'Dépense';
      case GoalType.debt:
        return 'Réduction de dette';
      case GoalType.income:
        return 'Revenu';
    }
  }

  String _getPriorityDisplayName(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.low:
        return 'Faible';
      case GoalPriority.medium:
        return 'Moyenne';
      case GoalPriority.high:
        return 'Élevée';
      case GoalPriority.urgent:
        return 'Urgente';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.25, 0.5, 0.85],
          colors: [
            Color(0xFF7B1FA2),
            Color(0xFFBA68C8),
            Color(0xFFE1BEE7),
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
                  isEditing ? 'Modifier Objectif' : 'Nouvel Objectif',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Définissez vos objectifs financiers',
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
              onTap: _saveGoal,
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
    final isEditing = widget.goal != null;
    
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
                  Color(0xFF7B1FA2),
                  Color(0xFFBA68C8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.3),
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
                    Icons.flag_rounded,
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
                        isEditing ? 'Modifier un objectif' : 'Créer un objectif',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Définissez et suivez vos objectifs financiers',
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
            label: 'Nom de l\'objectif',
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Vacances d\'été, Nouvel appartement...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF7B1FA2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom de l\'objectif est obligatoire';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildAmountFields(),
          const SizedBox(height: 20),
          _buildTypeDropdown(),
          const SizedBox(height: 20),
          _buildDateFields(),
          const SizedBox(height: 20),
          _buildAccountDropdown(),
          const SizedBox(height: 20),
          _buildFormField(
            label: 'Description (optionnelle)',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajoutez des détails sur cet objectif...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF7B1FA2)),
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

  Widget _buildAmountFields() {
    return Row(
      children: [
        Expanded(
          child: _buildFormField(
            label: 'Montant objectif (FCFA)',
            child: TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: 100 000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.flag_rounded, color: Color(0xFF7B1FA2)),
                suffixText: 'FCFA',
                suffixStyle: const TextStyle(
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.bold,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Obligatoire';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFormField(
            label: 'Montant actuel (FCFA)',
            child: TextFormField(
              controller: _currentAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: 25 000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                prefixIcon: const Icon(Icons.savings_rounded, color: Color(0xFF7B1FA2)),
                suffixText: 'FCFA',
                suffixStyle: const TextStyle(
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.bold,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Obligatoire';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'objectif',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<GoalType>(
          value: _selectedType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF7B1FA2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: GoalType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getTypeDisplayName(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
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
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF7B1FA2)),
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
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date cible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context, false),
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
                      const Icon(Icons.event_rounded, color: Color(0xFF7B1FA2)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_targetDate),
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
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compte associé',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Account>(
          value: _selectedAccount,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: const Icon(Icons.account_balance_rounded, color: Color(0xFF7B1FA2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _accounts.map((account) {
            return DropdownMenuItem(
              value: account,
              child: Text(account.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAccount = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isEditing = widget.goal != null;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7B1FA2),
            Color(0xFFBA68C8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _saveGoal,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEditing ? 'MODIFIER OBJECTIF' : 'CRÉER OBJECTIF',
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