import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../helpers/database_helper.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  final Map<String, double> _categoryTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetsAndExpenses();
  }

  // Category configuration - define directly in the file
  static const Map<String, IconData> categoryIcons = {
    'food': Icons.restaurant,
    'transportation': Icons.directions_car,
    'entertainment': Icons.movie,
    'shopping': Icons.shopping_bag,
    'health': Icons.medical_services,
    'education': Icons.school,
    'other': Icons.category,
  };

  static const Map<String, Color> categoryColors = {
    'food': Colors.orange,
    'transportation': Colors.blue,
    'entertainment': Colors.purple,
    'shopping': Colors.pink,
    'health': Colors.red,
    'education': Colors.green,
    'other': Colors.grey,
  };

  Future<void> _loadBudgetsAndExpenses() async {
    try {
      setState(() => _isLoading = true);
      
      // Load data using Future.wait for better performance
      final results = await Future.wait([
        _databaseHelper.getBudgets(),
        _databaseHelper.getExpenses(), // Use getExpenses instead of getExpensesForPeriod
      ]);

      _budgets = results[0] as List<Budget>;
      _expenses = results[1] as List<Expense>;
      _calculateCategoryTotals();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des budgets: $e'),
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

  void _calculateCategoryTotals() {
    _categoryTotals.clear();
    
    // Calculate totals based on budget period
    for (final expense in _expenses) {
      final now = DateTime.now();
      bool includeExpense = false;
      
      // Check if expense should be included based on period
      for (final budget in _budgets) {
        if (budget.category == expense.category) {
          if (budget.period == 'monthly') {
            // Include expenses from current month
            includeExpense = expense.date.year == now.year && 
                           expense.date.month == now.month;
          } else if (budget.period == 'yearly') {
            // Include expenses from current year
            includeExpense = expense.date.year == now.year;
          }
          break;
        }
      }
      
      if (includeExpense) {
        _categoryTotals[expense.category] =
            (_categoryTotals[expense.category] ?? 0) + expense.amount;
      }
    }
  }

  String _getCategoryDisplayName(String category) {
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

  void _showBudgetDialog({Budget? existingBudget}) {
    showDialog(
      context: context,
      builder: (context) => _BudgetDialog(
        existingBudget: existingBudget,
        onSaved: () => _loadBudgetsAndExpenses(),
      ),
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _databaseHelper.deleteBudget(budget.id!);
        _loadBudgetsAndExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBudgetDialog(),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBudgetList(),
    );
  }

  Widget _buildBudgetList() {
    if (_budgets.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBudgetsAndExpenses,
      child: ListView.builder(
        itemCount: _budgets.length,
        itemBuilder: (context, index) {
          final budget = _budgets[index];
          return _buildBudgetCard(budget);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun budget défini',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer un budget pour suivre vos dépenses',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showBudgetDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Créer un budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = _categoryTotals[budget.category] ?? 0;
    final remaining = budget.amount - spent;
    final progress = spent / budget.amount;
    final isOverBudget = spent > budget.amount;
    
    Color progressColor;
    if (isOverBudget) {
      progressColor = Colors.red;
    } else if (progress > 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showBudgetDialog(existingBudget: budget),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and actions
              Row(
                children: [
                  Icon(
                    categoryIcons[budget.category],
                    color: categoryColors[budget.category],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryDisplayName(budget.category),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          budget.period == 'monthly' ? 'Mensuel' : 'Annuel',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showBudgetDialog(existingBudget: budget);
                          break;
                        case 'delete':
                          _deleteBudget(budget);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress bar
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              const SizedBox(height: 8),
              
              // Amount information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dépensé',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${spent.toStringAsFixed(0)} FCFA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverBudget ? 'Dépassement' : 'Reste',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${remaining.abs().toStringAsFixed(0)} FCFA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isOverBudget ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Budget total
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '${budget.amount.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final Budget? existingBudget;
  final VoidCallback onSaved;

  const _BudgetDialog({
    this.existingBudget,
    required this.onSaved,
  });

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  String _selectedCategory = 'food';
  String _selectedPeriod = 'monthly';
  bool _isLoading = false;

  // Category configuration - define directly in the dialog
  static const Map<String, IconData> categoryIcons = {
    'food': Icons.restaurant,
    'transportation': Icons.directions_car,
    'entertainment': Icons.movie,
    'shopping': Icons.shopping_bag,
    'health': Icons.medical_services,
    'education': Icons.school,
    'other': Icons.category,
  };

  static const Map<String, Color> categoryColors = {
    'food': Colors.orange,
    'transportation': Colors.blue,
    'entertainment': Colors.purple,
    'shopping': Colors.pink,
    'health': Colors.red,
    'education': Colors.green,
    'other': Colors.grey,
  };

  static const List<String> categories = [
    'food',
    'transportation', 
    'entertainment',
    'shopping',
    'health',
    'education',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _selectedCategory = widget.existingBudget!.category;
      _selectedPeriod = widget.existingBudget!.period;
      _amountController.text = widget.existingBudget!.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(String category) {
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

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      if (widget.existingBudget != null) {
        // Update existing budget
        final updatedBudget = widget.existingBudget!.copyWith(
          category: _selectedCategory,
          amount: amount,
          period: _selectedPeriod,
          updatedDate: DateTime.now(),
        );
        await _databaseHelper.updateBudget(updatedBudget);
      } else {
        // Create new budget
        final budget = Budget(
          category: _selectedCategory,
          amount: amount,
          period: _selectedPeriod,
          createdDate: DateTime.now(),
        );
        await _databaseHelper.insertBudget(budget);
      }
      
      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingBudget != null
                ? 'Budget mis à jour avec succès'
                : 'Budget créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde du budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingBudget != null 
            ? 'Modifier le budget' 
            : 'Créer un budget',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          categoryIcons[category],
                          color: categoryColors[category],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(_getCategoryDisplayName(category)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant du budget',
                  suffixText: 'FCFA',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Period dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedPeriod,
                decoration: const InputDecoration(
                  labelText: 'Période',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text('Mensuel'),
                  ),
                  DropdownMenuItem(
                    value: 'yearly',
                    child: Text('Annuel'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedPeriod = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.existingBudget != null 
                      ? 'Mettre à jour'
                      : 'Créer',
                ),
        ),
      ],
    );
  }
}