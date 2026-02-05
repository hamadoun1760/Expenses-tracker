import 'package:flutter/material.dart';

enum AccountType {
  checking,
  savings,
  credit,
  cash,
  investment,
  other,
}

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final String currency;
  final String? description;
  final String iconName;
  final int colorValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    this.currency = 'FCFA',
    this.description,
    required this.iconName,
    required this.colorValue,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'currency': currency,
      'description': description,
      'icon_name': iconName,
      'color_value': colorValue,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.other,
      ),
      initialBalance: map['initial_balance']?.toDouble() ?? 0.0,
      currentBalance: map['current_balance']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'FCFA',
      description: map['description'],
      iconName: map['icon_name'] ?? 'account_balance',
      colorValue: map['color_value']?.toInt() ?? 0xFF2196F3,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    String? currency,
    String? description,
    String? iconName,
    int? colorValue,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case AccountType.checking:
        return 'Compte courant';
      case AccountType.savings:
        return 'Compte épargne';
      case AccountType.credit:
        return 'Carte de crédit';
      case AccountType.cash:
        return 'Espèces';
      case AccountType.investment:
        return 'Investissement';
      case AccountType.other:
        return 'Autre';
    }
  }

  String get typeDescription {
    switch (type) {
      case AccountType.checking:
        return 'Compte bancaire principal';
      case AccountType.savings:
        return 'Compte d\'épargne et économies';
      case AccountType.credit:
        return 'Carte de crédit et crédits';
      case AccountType.cash:
        return 'Argent liquide et espèces';
      case AccountType.investment:
        return 'Comptes d\'investissement';
      case AccountType.other:
        return 'Autres types de comptes';
    }
  }

  IconData get defaultIcon {
    switch (type) {
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.credit:
        return Icons.credit_card;
      case AccountType.cash:
        return Icons.monetization_on_rounded;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }

  Color get defaultColor {
    switch (type) {
      case AccountType.checking:
        return const Color(0xFF2196F3); // Blue
      case AccountType.savings:
        return const Color(0xFF4CAF50); // Green
      case AccountType.credit:
        return const Color(0xFFFF5722); // Deep Orange
      case AccountType.cash:
        return const Color(0xFF795548); // Brown
      case AccountType.investment:
        return const Color(0xFF9C27B0); // Purple
      case AccountType.other:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, type: $type, currentBalance: $currentBalance}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.currentBalance == currentBalance;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        currentBalance.hashCode;
  }

  // Static methods for default accounts
  static List<Account> getDefaultAccounts() {
    final now = DateTime.now();
    return [
      Account(
        name: 'Compte principal',
        type: AccountType.checking,
        initialBalance: 0.0,
        currentBalance: 0.0,
        iconName: 'account_balance',
        colorValue: const Color(0xFF2196F3).value,
        createdAt: now,
      ),
      Account(
        name: 'Espèces',
        type: AccountType.cash,
        initialBalance: 0.0,
        currentBalance: 0.0,
        iconName: 'monetization_on_rounded',
        colorValue: const Color(0xFF795548).value,
        createdAt: now,
      ),
    ];
  }
}