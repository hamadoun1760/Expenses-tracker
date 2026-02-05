import 'package:flutter/material.dart';

class IncomeConfig {
  static const List<String> categories = [
    'salary',
    'freelance',
    'investment',
    'business',
    'rental',
    'gift',
    'bonus',
    'other',
  ];
  
  static const Map<String, IconData> incomeIcons = {
    'salary': Icons.work_rounded,
    'freelance': Icons.laptop_rounded,
    'investment': Icons.trending_up_rounded,
    'business': Icons.business_rounded,
    'rental': Icons.home_rounded,
    'gift': Icons.card_giftcard_rounded,
    'bonus': Icons.star_rounded,
    'other': Icons.monetization_on_rounded,
  };

  static const Map<String, Color> incomeColors = {
    'salary': Colors.blue,
    'freelance': Colors.purple,
    'investment': Colors.green,
    'business': Colors.orange,
    'rental': Colors.teal,
    'gift': Colors.pink,
    'bonus': Colors.amber,
    'other': Colors.grey,
  };

  static const List<String> incomeCategories = [
    'salary',
    'freelance', 
    'investment',
    'business',
    'rental',
    'gift',
    'bonus',
    'other',
  ];
}