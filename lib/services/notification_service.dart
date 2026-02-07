import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../helpers/database_helper.dart';
import '../models/notification.dart';
import '../utils/currency_formatter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize notification settings
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iOSInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
        macOS: iOSInitializationSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status == PermissionStatus.granted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final result = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationCategory category = NotificationCategory.reminder,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Store notification in database
      final appNotification = AppNotification(
        title: title,
        body: body,
        category: _categoryToString(category),
        timestamp: DateTime.now(),
        payload: payload,
      );
      await _databaseHelper.insertNotification(appNotification);

      // Show system notification
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'expenses_channel',
        'Expense Tracker Notifications',
        channelDescription: 'Notifications for expense tracking app',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Expense Tracker',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
        macOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
    NotificationCategory category = NotificationCategory.reminder,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'expenses_scheduled_channel',
        'Scheduled Expense Notifications',
        channelDescription: 'Scheduled notifications for expense tracking',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Expense Tracker',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
        macOS: iOSDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'expenses_repeating_channel',
        'Repeating Expense Notifications',
        channelDescription: 'Repeating notifications for expense tracking',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Expense Tracker',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
        macOS: iOSDetails,
      );

      await _notificationsPlugin.periodicallyShow(
        id,
        title,
        body,
        repeatInterval,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling repeating notification: $e');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling notification: $e');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling all notifications: $e');
      }
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending notifications: $e');
      }
      return [];
    }
  }

  // Notification categories
  static const String goalProgressCategory = 'goal_progress';
  static const String budgetLimitCategory = 'budget_limit';
  static const String recurringTransactionCategory = 'recurring_transaction';
  static const String budgetReminderCategory = 'budget_reminder';

  // Predefined notification IDs to avoid conflicts
  static const int goalProgressBaseId = 1000;
  static const int budgetLimitBaseId = 2000;
  static const int recurringTransactionBaseId = 3000;
  static const int budgetReminderBaseId = 4000;

  // Helper method to convert enum to string
  String _categoryToString(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.goalProgress:
        return 'goal_progress';
      case NotificationCategory.budgetLimit:
        return 'budget_limit';
      case NotificationCategory.recurringTransaction:
        return 'recurring_transaction';
      case NotificationCategory.reminder:
        return 'general';
    }
  }

  // Create sample notifications for testing
  Future<void> createSampleNotifications() async {
    try {
      // Check if sample notifications already exist to avoid duplicates
      final existingNotifications = await _databaseHelper.getNotifications();
      
      // List of essential notifications to create if they don't exist
      final sampleNotifications = [
        AppNotification(
          title: 'Objectif presque atteint !',
          body: 'Votre objectif d\'épargne: 75% accompli. Plus que 50,000 FCFA !',
          category: 'goal_progress',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          actionText: 'Voir progrès',
          actionType: 'see_goal_progress',
        ),
        AppNotification(
          title: 'Transaction récurrente',
          body: 'Rappel: Forfait internet (5,000 FCFA) sera débité demain',
          category: 'recurring_transaction',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          actionText: 'Gérer',
          actionType: 'manage_recurring',
        ),
      ];

      // Only add notifications that don't already exist
      for (final notification in sampleNotifications) {
        final exists = existingNotifications.any(
          (existing) => existing.title == notification.title,
        );
        
        if (!exists) {
          await _databaseHelper.insertNotification(notification);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Create notification for new expense
  Future<void> notifyExpenseAdded(String title, double amount) async {
    final notification = AppNotification(
      title: 'Dépense ajoutée',
      body: '$title: ${amount.toStringAsFixed(0)} FCFA enregistré',
      category: 'expense_alert',
      timestamp: DateTime.now(),
      actionText: 'Voir détails',
      actionType: 'see_expense_details',
    );
    await _databaseHelper.insertNotification(notification);
  }

  // Create notification for new income - DISABLED
  Future<void> notifyIncomeAdded(String title, double amount) async {
    // Income notifications have been disabled to reduce notification fatigue
    return;
    
    // Original code below (disabled):
    /*
    final notification = AppNotification(
      title: 'Revenu ajouté',
      body: '$title: ${amount.toStringAsFixed(0)} FCFA enregistré',
      category: 'income_reminder',
      timestamp: DateTime.now(),
      actionText: 'Voir détails',
      actionType: 'see_income_details',
    );
    await _databaseHelper.insertNotification(notification);
    */
  }

  // Check if monthly report notification should be created
  // Only create it if:
  // 1. User has performed operations (has expenses or income)
  // 2. It's a new month compared to the last report
  Future<bool> shouldCreateMonthlyReportNotification() async {
    try {
      // Check if user has any expenses or income
      final expenses = await _databaseHelper.getExpenses();
      final incomes = await _databaseHelper.getIncomes();
      
      if (expenses.isEmpty && incomes.isEmpty) {
        return false;
      }

      // Check if a monthly report notification was already sent this month
      // Monthly report notifications are disabled
      return false;
    } catch (e) {
      return false;
    }
  }

  // Create monthly report notification
  // Monthly report notification - DISABLED
  Future<void> notifyMonthlyReport(String monthYear) async {
    // Monthly report notifications have been disabled
    return;
  }

  // Clear all sample notifications from database
  Future<void> clearSampleNotifications() async {
    try {
      final notifications = await _databaseHelper.getNotifications();
      final titlesToClear = [
        'Objectif presque atteint !',
        'Transaction récurrente',
        'Nouvelle fonctionnalité',
        'Nouveau revenu ajouté',  // Old income notifications
        'Rapport mensuel prêt',    // Old monthly report notifications
      ];
      
      for (final notification in notifications) {
        if (titlesToClear.contains(notification.title)) {
          await _databaseHelper.deleteNotification(notification.id!);
        }
      }
    } catch (e) {

    }
  }
}

enum NotificationCategory {
  reminder,
  goalProgress,
  budgetLimit,
  recurringTransaction,
}

enum NotificationPriority {
  critical,       // 🔴 Budget exceeded, goal reached
  important,      // 🔵 75% thresholds, milestones
  informational,  // ⚪ Tips, planning reminders
}