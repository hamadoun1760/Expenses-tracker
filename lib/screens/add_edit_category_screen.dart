import 'package:flutter/material.dart';
import '../models/custom_category.dart';
import '../helpers/database_helper.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CustomCategory? category;
  final String? type;

  const AddEditCategoryScreen({
    super.key,
    this.category,
    this.type,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  String _selectedType = 'expense';
  String _selectedIcon = 'category';
  Color _selectedColor = const Color(0xFF9C27B0);
  bool _isLoading = false;

  // Available icons for categories
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'category', 'icon': Icons.category},
    {'name': 'food', 'icon': Icons.restaurant},
    {'name': 'transport', 'icon': Icons.directions_car},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'entertainment', 'icon': Icons.movie},
    {'name': 'health', 'icon': Icons.local_hospital},
    {'name': 'education', 'icon': Icons.school},
    {'name': 'bills', 'icon': Icons.receipt_long},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'business', 'icon': Icons.business},
    {'name': 'investment', 'icon': Icons.trending_up},
    {'name': 'gift', 'icon': Icons.card_giftcard},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'utilities', 'icon': Icons.electrical_services},
    {'name': 'insurance', 'icon': Icons.security},
    {'name': 'travel', 'icon': Icons.flight},
    {'name': 'clothing', 'icon': Icons.checkroom},
    {'name': 'pets', 'icon': Icons.pets},
    {'name': 'sports', 'icon': Icons.sports_soccer},
    {'name': 'technology', 'icon': Icons.devices},
    {'name': 'music', 'icon': Icons.music_note},
    {'name': 'gaming', 'icon': Icons.games},
    {'name': 'beauty', 'icon': Icons.spa},
    {'name': 'fitness', 'icon': Icons.fitness_center},
    {'name': 'social', 'icon': Icons.people},
    {'name': 'books', 'icon': Icons.menu_book},
    {'name': 'coffee', 'icon': Icons.local_cafe},
    {'name': 'pharmacy', 'icon': Icons.local_pharmacy},
    {'name': 'gas', 'icon': Icons.local_gas_station},
    {'name': 'bank', 'icon': Icons.account_balance},
  ];

  // Available colors for categories
  final List<Color> _availableColors = [
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFF44336), // Red
    const Color(0xFFFF9800), // Orange
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF795548), // Brown
    const Color(0xFFE91E63), // Pink
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF009688), // Teal
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF9E9E9E), // Grey
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _loadCategoryData();
    } else if (widget.type != null) {
      _selectedType = widget.type!;
    }
  }

  void _loadCategoryData() {
    final category = widget.category!;
    _nameController.text = category.name;
    _selectedType = category.type;
    _selectedIcon = category.iconName;
    _selectedColor = Color(category.colorValue);
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = CustomCategory(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        iconName: _selectedIcon,
        colorValue: _selectedColor.value,
        isDefault: false,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.category != null) {
        await _databaseHelper.updateCustomCategory(category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catégorie mise à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _databaseHelper.insertCustomCategory(category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catégorie créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
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
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildPreviewCard() {
    final selectedIconData = _availableIcons.firstWhere(
      (icon) => icon['name'] == _selectedIcon,
      orElse: () => _availableIcons.first,
    )['icon'] as IconData;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _selectedColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selectedIconData,
                color: _selectedColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isEmpty ? 'Nom de la catégorie' : _nameController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedColor,
                    ),
                  ),
                  Text(
                    _selectedType == 'expense' ? 'Catégorie de dépense' : 'Catégorie de revenus',
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
    );
  }

  Widget _buildIconSelector() {
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
                Icon(Icons.palette, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Icône',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final iconData = _availableIcons[index];
                  final isSelected = iconData['name'] == _selectedIcon;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconData['name'];
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                          ? Border.all(color: Colors.purple, width: 2)
                          : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        iconData['icon'],
                        color: isSelected ? Colors.purple : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
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
                Icon(Icons.color_lens, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Couleur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _availableColors.length,
              itemBuilder: (context, index) {
                final color = _availableColors[index];
                final isSelected = color.value == _selectedColor.value;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                        ? Border.all(color: Colors.grey.shade800, width: 3)
                        : Border.all(color: Colors.grey.shade300),
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                  ),
                );
              },
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
        title: Text(
          widget.category != null ? 'Modifier la catégorie' : 'Ajouter une catégorie',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveCategory,
              child: const Text(
                'ENREGISTRER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Card
              _buildPreviewCard(),
              const SizedBox(height: 16),

              // Basic Information Section
              Card(
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
                          Icon(Icons.info_outline_rounded, color: Colors.purple),
                          const SizedBox(width: 8),
                          const Text(
                            'Informations générales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom de la catégorie *',
                          hintText: 'Ex: Transport, Alimentation, Salaire...',
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purple),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          if (value.trim().length < 2) {
                            return 'Le nom doit contenir au moins 2 caractères';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Refresh preview
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Type (only if not editing a default category)
                      if (widget.category?.isDefault != true) ...[
                        const Text(
                          'Type de catégorie',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Dépense'),
                                value: 'expense',
                                groupValue: _selectedType,
                                onChanged: widget.category?.isDefault == true
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                    },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Revenus'),
                                value: 'income',
                                groupValue: _selectedType,
                                onChanged: widget.category?.isDefault == true
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                    },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Icon Selector
              _buildIconSelector(),
              const SizedBox(height: 16),

              // Color Selector
              _buildColorSelector(),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.purple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}