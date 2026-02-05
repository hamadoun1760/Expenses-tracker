import 'package:flutter/material.dart';

class CategoryConfig {
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
}