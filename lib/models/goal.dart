import 'package:flutter/material.dart';

enum GoalType {
  savings,
  expense,
  income,
  debt,
}

enum GoalPriority {
  low,
  medium,
  high,
  urgent,
}

enum GoalStatus {
  active,
  paused,
  completed,
  cancelled,
}

class Goal {
  final int? id;
  final String title;
  final String? description;
  final GoalType type;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final GoalPriority priority;
  final GoalStatus status;
  final String iconName;
  final int colorValue;
  final int? accountId; // Optional linked account
  final DateTime createdAt;
  final DateTime? updatedAt;

  Goal({
    this.id,
    required this.title,
    this.description,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.targetDate,
    this.priority = GoalPriority.medium,
    this.status = GoalStatus.active,
    required this.iconName,
    required this.colorValue,
    this.accountId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'start_date': startDate.millisecondsSinceEpoch,
      'target_date': targetDate.millisecondsSinceEpoch,
      'priority': priority.name,
      'status': status.name,
      'icon_name': iconName,
      'color_value': colorValue,
      'account_id': accountId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'],
      type: GoalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GoalType.savings,
      ),
      targetAmount: map['target_amount']?.toDouble() ?? 0.0,
      currentAmount: map['current_amount']?.toDouble() ?? 0.0,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] ?? 0),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['target_date'] ?? 0),
      priority: GoalPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => GoalPriority.medium,
      ),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GoalStatus.active,
      ),
      iconName: map['icon_name'] ?? 'flag',
      colorValue: map['color_value']?.toInt() ?? 0xFF2196F3,
      accountId: map['account_id']?.toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    GoalType? type,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    GoalPriority? priority,
    GoalStatus? status,
    String? iconName,
    int? colorValue,
    int? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters for display
  String get typeDisplayName {
    switch (type) {
      case GoalType.savings:
        return 'Épargne';
      case GoalType.expense:
        return 'Contrôle des dépenses';
      case GoalType.income:
        return 'Objectif de revenus';
      case GoalType.debt:
        return 'Remboursement de dettes';
    }
  }

  String get typeDescription {
    switch (type) {
      case GoalType.savings:
        return 'Économiser pour un objectif';
      case GoalType.expense:
        return 'Limiter les dépenses';
      case GoalType.income:
        return 'Augmenter les revenus';
      case GoalType.debt:
        return 'Rembourser les dettes';
    }
  }

  String get priorityDisplayName {
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

  String get statusDisplayName {
    switch (status) {
      case GoalStatus.active:
        return 'Actif';
      case GoalStatus.paused:
        return 'En pause';
      case GoalStatus.completed:
        return 'Terminé';
      case GoalStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case GoalPriority.low:
        return Colors.grey;
      case GoalPriority.medium:
        return Colors.blue;
      case GoalPriority.high:
        return Colors.orange;
      case GoalPriority.urgent:
        return Colors.red;
    }
  }

  Color get statusColor {
    switch (status) {
      case GoalStatus.active:
        return Colors.green;
      case GoalStatus.paused:
        return Colors.orange;
      case GoalStatus.completed:
        return Colors.blue;
      case GoalStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case GoalType.savings:
        return Icons.savings;
      case GoalType.expense:
        return Icons.trending_down;
      case GoalType.income:
        return Icons.trending_up;
      case GoalType.debt:
        return Icons.payment;
    }
  }

  // Progress calculations
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, targetAmount);
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  int get totalDays {
    return targetDate.difference(startDate).inDays;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && status == GoalStatus.active;
  }

  bool get isCompleted {
    return status == GoalStatus.completed || currentAmount >= targetAmount;
  }

  // Expected daily progress for on-track goals
  double get requiredDailyProgress {
    if (daysRemaining <= 0 || targetAmount <= 0) return 0.0;
    return remainingAmount / daysRemaining;
  }

  @override
  String toString() {
    return 'Goal{id: $id, title: $title, type: $type, progress: ${progressPercentage.toStringAsFixed(1)}%}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.targetAmount == targetAmount &&
        other.currentAmount == currentAmount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        type.hashCode ^
        targetAmount.hashCode ^
        currentAmount.hashCode;
  }

  Color get typeColor {
    switch (type) {
      case GoalType.savings:
        return const Color(0xFF4CAF50); // Green
      case GoalType.expense:
        return const Color(0xFFF44336); // Red
      case GoalType.income:
        return const Color(0xFF2196F3); // Blue
      case GoalType.debt:
        return const Color(0xFFFF9800); // Orange
    }
  }

  // Notification-related methods
  bool get needsProgressNotification {
    final milestones = [25.0, 50.0, 75.0, 90.0];
    final currentProgress = progressPercentage;
    
    return milestones.any((milestone) => 
      currentProgress >= milestone - 0.5 && currentProgress <= milestone + 0.5);
  }

  bool get nearDeadline {
    final daysLeft = targetDate.difference(DateTime.now()).inDays;
    return daysLeft <= 7 && daysLeft > 0 && status == GoalStatus.active;
  }

  String get urgencyLevel {
    if (status != GoalStatus.active) return 'inactive';
    
    final daysLeft = targetDate.difference(DateTime.now()).inDays;
    final progress = progressPercentage;
    
    if (daysLeft <= 0) return 'overdue';
    if (daysLeft <= 3 && progress < 75) return 'urgent';
    if (daysLeft <= 7 && progress < 50) return 'high';
    if (daysLeft <= 14 && progress < 25) return 'medium';
    
    return 'low';
  }

  Color get urgencyColor {
    switch (urgencyLevel) {
      case 'overdue':
      case 'urgent':
        return const Color(0xFFD32F2F); // Red
      case 'high':
        return const Color(0xFFFF6D00); // Orange
      case 'medium':
        return const Color(0xFFFFA000); // Amber
      default:
        return const Color(0xFF388E3C); // Green
    }
  }
}