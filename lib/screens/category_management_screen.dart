import 'package:flutter/material.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';
import 'add_edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<CustomCategory> _categories = [];
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _databaseHelper.getCustomCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des catégories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CustomCategory> _getCategoriesByType(String type) {
    return _categories.where((category) => category.type == type).toList();
  }

  Widget _buildCategoryList(String type) {
    final categories = _getCategoriesByType(type);
    
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'expense' ? Icons.money_off : Icons.monetization_on_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune catégorie ${type == 'expense' ? 'de dépense' : 'de revenus'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour ajouter une catégorie',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(CustomCategory category) {
    final iconData = _getIconData(category.iconName);
    final color = Color(category.colorValue);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            iconData,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.type == 'expense' ? 'Catégorie de dépense' : 'Catégorie de revenus',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (category.isDefault)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Par défaut',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editCategory(category),
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
            ),
            if (!category.isDefault)
              IconButton(
                onPressed: () => _deleteCategory(category),
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Supprimer',
              ),
          ],
        ),
        onTap: () => _editCategory(category),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to IconData
    const iconMap = {
      'category': Icons.category,
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'shopping': Icons.shopping_cart,
      'entertainment': Icons.movie,
      'health': Icons.local_hospital,
      'education': Icons.school,
      'bills': Icons.receipt_long,
      'work': Icons.work,
      'business': Icons.business,
      'investment': Icons.trending_up,
      'gift': Icons.card_giftcard,
      'other': Icons.more_horiz,
      'home': Icons.home,
      'utilities': Icons.electrical_services,
      'insurance': Icons.security,
      'travel': Icons.flight,
      'clothing': Icons.checkroom,
      'pets': Icons.pets,
      'sports': Icons.sports_soccer,
      'technology': Icons.devices,
      'charity': Icons.volunteer_activism,
      'taxes': Icons.account_balance,
      'medical': Icons.medical_services,
      'car': Icons.car_repair,
      'phone': Icons.phone,
      'internet': Icons.wifi,
      'groceries': Icons.local_grocery_store,
      'dining': Icons.restaurant_menu,
      'coffee': Icons.local_cafe,
      'gas': Icons.local_gas_station,
      'parking': Icons.local_parking,
      'taxi': Icons.local_taxi,
      'subway': Icons.subway,
      'flight': Icons.flight_takeoff,
      'hotel': Icons.hotel,
      'subscription': Icons.subscriptions,
      'gym': Icons.fitness_center,
      'books': Icons.menu_book,
      'music': Icons.music_note,
      'games': Icons.games,
      'beauty': Icons.face,
      'pharmacy': Icons.local_pharmacy,
      'dentist': Icons.medical_services,
      'veterinarian': Icons.pets,
      'repair': Icons.build,
      'cleaning': Icons.cleaning_services,
      'rent': Icons.home_work,
      'mortgage': Icons.real_estate_agent,
      'savings': Icons.savings,
      'bank': Icons.account_balance,
      'salary': Icons.payment,
      'freelance': Icons.computer,
      'bonus': Icons.star,
      'refund': Icons.refresh,
      'sale': Icons.sell,
      'dividend': Icons.account_balance_wallet,
      'rental': Icons.vpn_key,
      'pension': Icons.elderly,
      'award': Icons.emoji_events,
      'lottery': Icons.casino,
      'allowance': Icons.family_restroom,
    };

    return iconMap[iconName] ?? Icons.category;
  }

  void _addCategory(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(type: type),
      ),
    ).then((_) => _loadCategories());
  }

  void _editCategory(CustomCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    ).then((_) => _loadCategories());
  }

  Future<void> _deleteCategory(CustomCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${category.name}"?\\n\\n'
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _databaseHelper.deleteCustomCategory(category.id!);
        await _loadCategories();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catégorie supprimée avec succès'),
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
        title: Text(
          'Gestion des catégories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Dépenses',
              icon: Icon(Icons.money_off),
            ),
            Tab(
              text: 'Revenus',
              icon: Icon(Icons.monetization_on_rounded),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList('expense'),
                _buildCategoryList('income'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentType = _tabController.index == 0 ? 'expense' : 'income';
          _addCategory(currentType);
        },
        tooltip: 'Ajouter une catégorie',
        child: const Icon(Icons.add),
      ),
    );
  }
}