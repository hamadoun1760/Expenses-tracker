import 'package:expenses_tracking/screens/add_edit_recurring_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';
import '../utils/theme.dart';
import '../config/category_config.dart' as config;
import '../config/income_config.dart';
import '../utils/currency_formatter.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<RecurringTransaction> _recurringTransactions = [];
  List<CustomCategory> _customCategories = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'active', 'inactive', 'due'

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions();
    _loadCustomCategories();
    _processDueTransactions();
  }

  Future<void> _loadRecurringTransactions() async {
    try {
      final transactions = await _databaseHelper.getRecurringTransactions();
      setState(() {
        _recurringTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      final customCategories = await _databaseHelper.getCustomCategories();
      setState(() {
        _customCategories = customCategories;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _processDueTransactions() async {
    try {
      final processedTitles = await _databaseHelper
          .processDueRecurringTransactions();
      if (processedTitles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${processedTitles.length} transaction(s) récurrente(s) traitée(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecurringTransactions(); // Refresh the list
      }
    } catch (e) {
      // Silently handle processing errors
    }
  }

  List<RecurringTransaction> get _filteredTransactions {
    switch (_selectedFilter) {
      case 'active':
        return _recurringTransactions.where((t) => t.isActive).toList();
      case 'inactive':
        return _recurringTransactions.where((t) => !t.isActive).toList();
      case 'due':
        final now = DateTime.now();
        return _recurringTransactions
            .where(
              (t) =>
                  t.isActive &&
                  (t.nextDueDate.isBefore(now) ||
                      t.nextDueDate.isAtSameMomentAs(now)),
            )
            .toList();
      default:
        return _recurringTransactions;
    }
  }

  Future<void> _deleteRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la récurrence'),
        content: Text(
          'Voulez-vous supprimer la récurrence "${transaction.title}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteRecurringTransaction(transaction.id!);
        _loadRecurringTransactions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Récurrence supprimée'),
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

  Future<void> _toggleTransactionStatus(
    RecurringTransaction transaction,
  ) async {
    try {
      final updatedTransaction = transaction.copyWith(
        isActive: !transaction.isActive,
      );
      await _databaseHelper.updateRecurringTransaction(updatedTransaction);
      _loadRecurringTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecurringTransactionScreen(),
      ),
    );

    if (result == true) {
      _loadRecurringTransactions();
    }
  }

  void _navigateToEdit(RecurringTransaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditRecurringTransactionScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      _loadRecurringTransactions();
    }
  }

  IconData _getCategoryIcon(String category, String type) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == category,
      orElse: () => CustomCategory(
        name: '',
        type: 'expense',
        iconName: '',
        colorValue: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (customCategory.name.isNotEmpty) {
      return _getIconFromName(customCategory.iconName);
    }

    // Handle default categories
    final categoryConfig = type == 'expense'
        ? config.CategoryConfig.categoryIcons
        : IncomeConfig.incomeIcons;
    return categoryConfig[category] ?? Icons.category;
  }

  Color _getCategoryColor(String category, String type) {
    // First check if it's a custom category
    final customCategory = _customCategories.firstWhere(
      (cat) => cat.name == category,
      orElse: () => CustomCategory(
        name: '',
        type: 'expense',
        iconName: '',
        colorValue: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (customCategory.name.isNotEmpty) {
      return Color(customCategory.colorValue);
    }

    // Handle default categories
    final categoryColors = type == 'expense'
        ? config.CategoryConfig.categoryColors
        : IncomeConfig.incomeColors;
    return categoryColors[category] ?? Colors.grey;
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'phone':
        return Icons.phone;
      case 'wifi':
        return Icons.wifi;
      case 'pets':
        return Icons.pets;
      case 'work_rounded':
        return Icons.work_rounded;
      case 'laptop_rounded':
        return Icons.laptop_rounded;
      case 'trending_up_rounded':
        return Icons.trending_up_rounded;
      case 'business_rounded':
        return Icons.business_rounded;
      case 'home_rounded':
        return Icons.home_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'monetization_on_rounded':
        return Icons.monetization_on_rounded;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'groups':
        return Icons.groups;
      case 'handshake':
        return Icons.handshake;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }

  Widget _buildTransactionCard(RecurringTransaction transaction) {
    final isExpense = transaction.type == 'expense';
    final categoryIcon = _getCategoryIcon(
      transaction.category,
      transaction.type,
    );
    final categoryColor = _getCategoryColor(
      transaction.category,
      transaction.type,
    );

    final cardColor = transaction.isActive
        ? Colors.white
        : Colors.grey.shade100;
    final isDue =
        transaction.isActive &&
        transaction.nextDueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDue ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: Colors.white, size: 24),
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
                              transaction.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: transaction.isActive
                                    ? AppColors.textPrimary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (isDue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (!transaction.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'INACTIF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transaction.typeDisplayText} • ${transaction.frequencyDisplayText}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (transaction.description?.isNotEmpty ?? false)
                        Text(
                          transaction.description!,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isExpense ? AppColors.secondary : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${isExpense ? '-' : '+'}${CurrencyFormatter.formatWithCurrency(transaction.amount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleTransactionStatus(transaction),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: transaction.isActive
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              transaction.isActive
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18,
                              color: transaction.isActive
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _navigateToEdit(transaction),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00695C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: Color(0xFF00695C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteRecurringTransaction(transaction),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Prochaine: ${DateFormat('dd/MM/yyyy').format(transaction.nextDueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (transaction.maxOccurrences != null)
                    Text(
                      '${transaction.currentOccurrences}/${transaction.maxOccurrences}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions Récurrentes'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Toutes')),
              const PopupMenuItem(value: 'active', child: Text('Actives')),
              const PopupMenuItem(value: 'inactive', child: Text('Inactives')),
              const PopupMenuItem(value: 'due', child: Text('À traiter')),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.filter_list_rounded),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00695C).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_recurringTransactions.where((t) => t.isActive).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Actives',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_recurringTransactions.where((t) => !t.isActive && t.nextDueDate.isBefore(DateTime.now())).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'À traiter',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_recurringTransactions.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune transaction récurrente',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ajoutez des transactions récurrentes pour automatiser vos finances',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                              _filteredTransactions[index],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
