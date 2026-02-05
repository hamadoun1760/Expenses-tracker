import 'package:flutter/material.dart';

class AppNotification {
  final int? id;
  final String title;
  final String body;
  final String category;
  final DateTime timestamp;
  final bool isRead;
  final String? payload;
  final String? actionText;
  final String? icon;

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.payload,
    this.actionText,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'payload': payload,
      'action_text': actionText,
      'icon': icon,
    };
  }

  static AppNotification fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      category: map['category'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['is_read'] == 1,
      payload: map['payload'],
      actionText: map['action_text'],
      icon: map['icon'],
    );
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    String? category,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
    String? actionText,
    String? icon,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      actionText: actionText ?? this.actionText,
      icon: icon ?? this.icon,
    );
  }

  static List<String> get categories => [
    'general',
    'goal_progress',
    'budget_limit',
    'recurring_transaction',
    'expense_alert',
    'income_reminder',
  ];

  IconData get categoryIcon {
    switch (category) {
      case 'goal_progress':
        return Icons.flag_rounded;
      case 'budget_limit':
        return Icons.warning_amber_rounded;
      case 'recurring_transaction':
        return Icons.repeat_rounded;
      case 'expense_alert':
        return Icons.money_off_rounded;
      case 'income_reminder':
        return Icons.attach_money_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'goal_progress':
        return Color(0xFF4CAF50);
      case 'budget_limit':
        return Color(0xFFFF9800);
      case 'recurring_transaction':
        return Color(0xFF2196F3);
      case 'expense_alert':
        return Color(0xFFE91E63);
      case 'income_reminder':
        return Color(0xFF00BCD4);
      default:
        return Color(0xFF6C757D);
    }
  }
}