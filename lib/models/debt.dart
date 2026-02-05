import 'package:flutter/material.dart';

enum DebtType {
  creditCard,
  personalLoan,
  mortgage,
  studentLoan,
  autoLoan,
  other,
}

enum DebtTransactionType {
  dette, // Ce que je dois
  creance, // Ce qu'on me doit
}

enum DebtCategory {
  famille,
  amis,
  banque,
  tontine,
  autre,
}

enum PaymentStrategy {
  snowball, // Pay off smallest balances first
  avalanche, // Pay off highest interest rates first
  custom, // User-defined strategy
}

enum DebtStatus {
  active,
  paused,
  paidOff,
  defaulted,
}

class Debt {
  final int? id;
  final String name;
  final String? description;
  final DebtType type;
  final int? customDebtTypeId; // Reference to custom debt type
  final double originalAmount;
  final double currentBalance;
  final double interestRate; // Annual percentage rate
  final DateTime startDate;
  final DateTime? targetPayoffDate;
  final double minimumPayment;
  final PaymentStrategy strategy;
  final DebtStatus status;
  final String? creditorName;
  final String? accountNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // New fields for West African context
  final DebtTransactionType transactionType;
  final String contactName;
  final String? contactPhone;
  final DateTime? echeance; // Due date
  final DebtCategory category;
  final String? customCategoryName; // For storing custom category names

  const Debt({
    this.id,
    required this.name,
    this.description,
    required this.type,
    this.customDebtTypeId,
    required this.originalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.startDate,
    this.targetPayoffDate,
    required this.minimumPayment,
    this.strategy = PaymentStrategy.snowball,
    this.status = DebtStatus.active,
    this.creditorName,
    this.accountNumber,
    required this.createdAt,
    this.updatedAt,
    required this.transactionType,
    required this.contactName,
    this.contactPhone,
    this.echeance,
    this.category = DebtCategory.autre,
    this.customCategoryName,
  });

  double get remainingPercentage => currentBalance / originalAmount;
  double get paidPercentage => 1.0 - remainingPercentage;
  double get totalInterestEstimate {
    if (currentBalance <= 0) return 0;
    
    // Simple estimate assuming minimum payments
    double balance = currentBalance;
    double totalInterest = 0;
    int months = 0;
    const maxMonths = 360; // 30 years max
    
    while (balance > 0 && months < maxMonths) {
      final monthlyInterest = balance * (interestRate / 100 / 12);
      totalInterest += monthlyInterest;
      balance = balance + monthlyInterest - minimumPayment;
      months++;
      
      if (minimumPayment <= monthlyInterest) break; // Never ending debt
    }
    
    return totalInterest;
  }
  
  DateTime? get estimatedPayoffDate {
    if (currentBalance <= 0) return null;
    if (minimumPayment <= (currentBalance * (interestRate / 100 / 12))) {
      return null; // Never ending debt
    }
    
    double balance = currentBalance;
    int months = 0;
    const maxMonths = 360; // 30 years max
    
    while (balance > 0 && months < maxMonths) {
      final monthlyInterest = balance * (interestRate / 100 / 12);
      balance = balance + monthlyInterest - minimumPayment;
      months++;
    }
    
    if (months >= maxMonths) return null;
    return DateTime.now().add(Duration(days: months * 30));
  }

  Color get statusColor {
    switch (status) {
      case DebtStatus.active:
        return Colors.orange;
      case DebtStatus.paused:
        return Colors.grey;
      case DebtStatus.paidOff:
        return Colors.green;
      case DebtStatus.defaulted:
        return Colors.red;
    }
  }

  IconData get typeIcon {
    // TODO: For custom debt types, we need to fetch from database
    // This is a limitation that would need database access here
    // For now, return default icons for enum types
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.mortgage:
        return Icons.home;
      case DebtType.studentLoan:
        return Icons.school;
      case DebtType.autoLoan:
        return Icons.directions_car;
      case DebtType.other:
        return Icons.account_balance;
    }
  }

  Color get typeColor {
    // Return distinct colors for each debt type
    switch (type) {
      case DebtType.creditCard:
        return const Color(0xFF6200EA); // Purple
      case DebtType.personalLoan:
        return const Color(0xFF1976D2); // Blue
      case DebtType.mortgage:
        return const Color(0xFFD32F2F); // Red
      case DebtType.studentLoan:
        return const Color(0xFF00897B); // Teal
      case DebtType.autoLoan:
        return const Color(0xFFFFA000); // Orange
      case DebtType.other:
        return const Color(0xFF616161); // Grey
    }
  }

  String get typeDisplayName {
    switch (type) {
      case DebtType.creditCard:
        return 'Carte de crédit';
      case DebtType.personalLoan:
        return 'Prêt personnel';
      case DebtType.mortgage:
        return 'Hypothèque';
      case DebtType.studentLoan:
        return 'Prêt étudiant';
      case DebtType.autoLoan:
        return 'Prêt auto';
      case DebtType.other:
        return 'Autre';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case DebtStatus.active:
        return 'Actif';
      case DebtStatus.paused:
        return 'En pause';
      case DebtStatus.paidOff:
        return 'Remboursé';
      case DebtStatus.defaulted:
        return 'En défaut';
    }
  }

  String get transactionTypeDisplayName {
    switch (transactionType) {
      case DebtTransactionType.dette:
        return 'Dette (Ce que je dois)';
      case DebtTransactionType.creance:
        return 'Créance (Ce qu\'on me doit)';
    }
  }

  // Format amount with FCFA and thousands separator
  String get formattedAmount {
    return '${originalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }

  String get formattedCurrentBalance {
    return '${currentBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'custom_debt_type_id': customDebtTypeId,
      'original_amount': originalAmount,
      'current_balance': currentBalance,
      'interest_rate': interestRate,
      'start_date': startDate.toIso8601String(),
      'target_payoff_date': targetPayoffDate?.toIso8601String(),
      'minimum_payment': minimumPayment,
      'strategy': strategy.name,
      'status': status.name,
      'creditor_name': creditorName,
      'account_number': accountNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'transaction_type': transactionType.name,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'echeance': echeance?.toIso8601String(),
      'category': category.name,
      'custom_category_name': customCategoryName,
    };
  }

  static Debt fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: DebtType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DebtType.other,
      ),
      customDebtTypeId: map['custom_debt_type_id'],
      originalAmount: map['original_amount']?.toDouble() ?? 0.0,
      currentBalance: map['current_balance']?.toDouble() ?? 0.0,
      interestRate: map['interest_rate']?.toDouble() ?? 0.0,
      startDate: DateTime.parse(map['start_date']),
      targetPayoffDate: map['target_payoff_date'] != null
          ? DateTime.parse(map['target_payoff_date'])
          : null,
      minimumPayment: map['minimum_payment']?.toDouble() ?? 0.0,
      strategy: PaymentStrategy.values.firstWhere(
        (e) => e.name == map['strategy'],
        orElse: () => PaymentStrategy.snowball,
      ),
      status: DebtStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DebtStatus.active,
      ),
      creditorName: map['creditor_name'],
      accountNumber: map['account_number'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      transactionType: DebtTransactionType.values.firstWhere(
        (e) => e.name == map['transaction_type'],
        orElse: () => DebtTransactionType.dette,
      ),
      contactName: map['contact_name'] ?? '',
      contactPhone: map['contact_phone'],
      echeance: map['echeance'] != null
          ? DateTime.parse(map['echeance'])
          : null,
      category: DebtCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => DebtCategory.autre,
      ),
      customCategoryName: map['custom_category_name'],
    );
  }

  Debt copyWith({
    int? id,
    String? name,
    String? description,
    DebtType? type,
    int? customDebtTypeId,
    double? originalAmount,
    double? currentBalance,
    double? interestRate,
    DateTime? startDate,
    DateTime? targetPayoffDate,
    double? minimumPayment,
    PaymentStrategy? strategy,
    DebtStatus? status,
    String? creditorName,
    String? accountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DebtTransactionType? transactionType,
    String? contactName,
    String? contactPhone,
    DateTime? echeance,
    DebtCategory? category,
    String? customCategoryName,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      customDebtTypeId: customDebtTypeId ?? this.customDebtTypeId,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      targetPayoffDate: targetPayoffDate ?? this.targetPayoffDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      strategy: strategy ?? this.strategy,
      status: status ?? this.status,
      creditorName: creditorName ?? this.creditorName,
      accountNumber: accountNumber ?? this.accountNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionType: transactionType ?? this.transactionType,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      echeance: echeance ?? this.echeance,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
    );
  }

  String get categoryDisplayName {
    // If we have a custom category name, use it
    if (customCategoryName != null && customCategoryName!.isNotEmpty) {
      return customCategoryName!;
    }
    
    // Otherwise use the default category display name
    switch (category) {
      case DebtCategory.famille:
        return 'Famille';
      case DebtCategory.amis:
        return 'Amis';
      case DebtCategory.banque:
        return 'Banque';
      case DebtCategory.tontine:
        return 'Tontine';
      case DebtCategory.autre:
        return 'Autre';
    }
  }
}

class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime paymentDate;
  final String? description;
  final bool isExtraPayment;
  final DateTime createdAt;

  const DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.description,
    this.isExtraPayment = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'description': description,
      'is_extra_payment': isExtraPayment ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DebtPayment fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'],
      debtId: map['debt_id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(map['payment_date']),
      description: map['description'],
      isExtraPayment: map['is_extra_payment'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}