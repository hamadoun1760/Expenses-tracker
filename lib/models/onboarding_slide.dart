import 'package:flutter/material.dart';

/// Model representing a single onboarding slide
class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
  });
}

/// Default onboarding slides for the application
List<OnboardingSlide> getOnboardingSlides() {
  return [
    OnboardingSlide(
      title: 'Bienvenue dans Suivi des Dépenses',
      description: 'Suivez toutes vos dépenses et gérez votre budget efficacement en un seul endroit.',
      icon: Icons.trending_down,
      backgroundColor: const Color(0xFF1976D2),
      accentColor: const Color(0xFF42A5F5),
    ),
    OnboardingSlide(
      title: 'Catégorisation Intelligente',
      description: 'Organisez vos dépenses par catégories pour mieux comprendre vos habitudes de dépenses.',
      icon: Icons.folder_open,
      backgroundColor: const Color(0xFF00695C),
      accentColor: const Color(0xFF00897B),
    ),
    OnboardingSlide(
      title: 'Suivi des Dépenses Récurrentes',
      description: 'Configurez des transactions récurrentes pour les factures et abonnements réguliers.',
      icon: Icons.repeat,
      backgroundColor: const Color(0xFFFF8F00),
      accentColor: const Color(0xFFFFB74D),
    ),
    OnboardingSlide(
      title: 'Gestion des Dettes',
      description: 'Suivez vos dettes et visualisez votre progression vers la liberté financière.',
      icon: Icons.account_balance_wallet,
      backgroundColor: const Color(0xFF6A1B9A),
      accentColor: const Color(0xFFAB47BC),
    ),
    OnboardingSlide(
      title: 'Obtenez des Insights',
      description: 'Visualisez vos dépenses avec des graphiques et des rapports pour mieux décider.',
      icon: Icons.analytics,
      backgroundColor: const Color(0xFFD32F2F),
      accentColor: const Color(0xFFEF5350),
    ),
  ];
}
