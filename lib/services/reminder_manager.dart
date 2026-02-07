import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import '../helpers/database_helper.dart';
import 'notification_service.dart';

class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();
  factory ReminderManager() => _instance;
  ReminderManager._internal();

  final NotificationService _notificationService = NotificationService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Initialize reminders system
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _scheduleAllReminders();
  }

  // Schedule all active reminders
  Future<void> _scheduleAllReminders() async {
    await _scheduleGoalReminders();
    await _scheduleBudgetReminders();
    await _scheduleRecurringTransactionReminders();
  }

  // Goal-related reminders
  Future<void> _scheduleGoalReminders() async {
    try {
      final goals = await _databaseHelper.getGoals(
        status: GoalStatus.active,
      );

      for (final goal in goals) {
        await _scheduleGoalProgressReminder(goal);
        await _scheduleGoalDeadlineReminder(goal);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _scheduleGoalProgressReminder(Goal goal) async {
    final progress = goal.progressPercentage;
    
    // Send notification at key milestones: 50% and 90% progress (reduced from 25%, 50%, 75%, 90%)
    final milestones = [50.0, 90.0];
    
    for (final milestone in milestones) {
      if (progress >= milestone - 1 && progress <= milestone + 1) {
        await _notificationService.showNotification(
          id: NotificationService.goalProgressBaseId + goal.id! * 10 + milestone.toInt(),
          title: 'Étape importante 🎯',
          body: 'Vous avez atteint ${milestone.toInt()}% de votre objectif "${goal.title}"!',
          payload: 'goal_progress_${goal.id}',
          category: NotificationCategory.goalProgress,
        );
      }
    }
  }

  Future<void> _scheduleGoalDeadlineReminder(Goal goal) async {
    final now = DateTime.now();
    final daysUntilTarget = goal.targetDate.difference(now).inDays;
    
    // Send reminders at 7 days, 3 days, and 1 day before deadline
    final reminderDays = [7, 3, 1];
    
    for (final days in reminderDays) {
      if (daysUntilTarget == days) {
        final formatter = NumberFormat('#,##0', 'fr_FR');
        final remaining = formatter.format(goal.remainingAmount);
        
        await _notificationService.scheduleNotification(
          id: NotificationService.goalProgressBaseId + goal.id! * 100 + days,
          title: 'Rappel d\'objectif ⏰',
          body: 'Plus que $days jour${days > 1 ? 's' : ''} pour atteindre "${goal.title}". Reste: $remaining FCFA',
          scheduledDateTime: now.add(const Duration(hours: 9)), // 9 AM
          payload: 'goal_deadline_${goal.id}',
          category: NotificationCategory.goalProgress,
        );
      }
    }
  }

  // Budget-related reminders
  Future<void> _scheduleBudgetReminders() async {
    try {
      final budgets = await _databaseHelper.getBudgets();
      
      for (final budget in budgets) {
        await _checkBudgetLimits(budget);
        await _scheduleBudgetResetReminder(budget);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _checkBudgetLimits(Budget budget) async {
    final spent = await _databaseHelper.getSpentAmountForBudget(budget);
    final percentage = (spent / budget.amount) * 100;
    
    // Send critical alerts at 75% and 95% of budget (reduced from 50%, 75%, 90%, 95%)
    if (percentage >= 75 && percentage < 95) {
      await _notificationService.showNotification(
        id: NotificationService.budgetLimitBaseId + budget.id! * 10 + 75,
        title: 'Budget à 75% ⚠️',
        body: 'Vous avez dépensé 75% du budget "${budget.category}" ce mois-ci.',
        payload: 'budget_warning_${budget.id}',
        category: NotificationCategory.budgetLimit,
      );
    } else if (percentage >= 95) {
      await _notificationService.showNotification(
        id: NotificationService.budgetLimitBaseId + budget.id! * 10 + 95,
        title: 'Budget critique! 🚨',
        body: 'Vous avez dépensé 95% du budget "${budget.category}". Attention!',
        payload: 'budget_limit_${budget.id}',
        category: NotificationCategory.budgetLimit,
      );
    }
  }

  Future<void> _scheduleBudgetResetReminder(Budget budget) async {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final reminderDate = nextMonth.subtract(const Duration(days: 3));
    
    if (reminderDate.isAfter(now)) {
      await _notificationService.scheduleNotification(
        id: NotificationService.budgetReminderBaseId + budget.id!,
        title: 'Planification du budget 📊',
        body: 'N\'oubliez pas de planifier votre budget pour le mois prochain!',
        scheduledDateTime: reminderDate.add(const Duration(hours: 18)), // 6 PM
        payload: 'budget_planning_${budget.id}',
      );
    }
  }

  // Recurring transaction reminders
  Future<void> _scheduleRecurringTransactionReminders() async {
    try {
      final allTransactions = await _databaseHelper.getRecurringTransactions();
      final activeTransactions = allTransactions.where((t) => t.isActive).toList();
      
      for (final transaction in activeTransactions) {
        await _scheduleRecurringTransactionReminder(transaction);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _scheduleRecurringTransactionReminder(
    RecurringTransaction transaction
  ) async {
    final nextDate = _calculateNextOccurrence(transaction);
    if (nextDate != null) {
      final reminderDate = nextDate.subtract(const Duration(hours: 2));
      
      if (reminderDate.isAfter(DateTime.now())) {
        final formatter = NumberFormat('#,##0', 'fr_FR');
        final amount = formatter.format(transaction.amount);
        
        await _notificationService.scheduleNotification(
          id: NotificationService.recurringTransactionBaseId + transaction.id!,
          title: 'Transaction récurrente 🔄',
          body: 'Rappel: ${transaction.title} - $amount FCFA prévu aujourd\'hui',
          scheduledDateTime: reminderDate,
          payload: 'recurring_${transaction.id}',
          category: NotificationCategory.recurringTransaction,
        );
      }
    }
  }

  // Helper method to calculate next occurrence for recurring transactions
  DateTime? _calculateNextOccurrence(RecurringTransaction transaction) {
    final lastDate = transaction.nextDueDate;
    
    switch (transaction.frequency) {
      case 'daily':
        return lastDate.add(const Duration(days: 1));
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case 'yearly':
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
      default:
        return null;
    }
  }

  // Manual notification methods
  Future<void> notifyGoalAchievement(Goal goal) async {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    final amount = formatter.format(goal.targetAmount);
    
    await _notificationService.showNotification(
      id: NotificationService.goalProgressBaseId + goal.id! * 1000,
      title: 'Objectif atteint! 🎯✨',
      body: 'Bravo! Vous avez atteint votre objectif "${goal.title}" de $amount FCFA!',
      payload: 'goal_completed_${goal.id}',
      category: NotificationCategory.goalProgress,
    );
  }

  Future<void> notifyBudgetExceeded(Budget budget, double amount) async {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    final budgetAmount = formatter.format(budget.amount);
    final exceededAmount = formatter.format(amount);
    
    await _notificationService.showNotification(
      id: NotificationService.budgetLimitBaseId + budget.id! * 1000,
      title: 'Budget dépassé! 💸',
      body: 'Budget "${budget.category}" ($budgetAmount FCFA) dépassé de $exceededAmount FCFA',
      payload: 'budget_exceeded_${budget.id}',
      category: NotificationCategory.budgetLimit,
    );
  }

  Future<void> notifyRecurringTransactionDue(RecurringTransaction transaction) async {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    final amount = formatter.format(transaction.amount);
    
    await _notificationService.showNotification(
      id: NotificationService.recurringTransactionBaseId + transaction.id! + 10000,
      title: 'Transaction due 📅',
      body: '${transaction.title} - $amount FCFA est due aujourd\'hui',
      payload: 'recurring_due_${transaction.id}',
      category: NotificationCategory.recurringTransaction,
    );
  }

  // Settings and management
  Future<void> updateGoalReminders(Goal goal) async {
    // Cancel old reminders
    await _cancelGoalReminders(goal.id!);
    
    // Schedule new reminders
    if (goal.status == GoalStatus.active) {
      await _scheduleGoalProgressReminder(goal);
      await _scheduleGoalDeadlineReminder(goal);
    }
  }

  Future<void> _cancelGoalReminders(int goalId) async {
    // Cancel progress reminders
    for (int i = 0; i < 10; i++) {
      await _notificationService.cancelNotification(
        NotificationService.goalProgressBaseId + goalId * 10 + i,
      );
    }
    
    // Cancel deadline reminders
    for (int i = 0; i < 10; i++) {
      await _notificationService.cancelNotification(
        NotificationService.goalProgressBaseId + goalId * 100 + i,
      );
    }
  }

  Future<void> updateBudgetReminders(Budget budget) async {
    // Cancel old reminders
    await _cancelBudgetReminders(budget.id!);
    
    // Schedule new reminders
    await _checkBudgetLimits(budget);
    await _scheduleBudgetResetReminder(budget);
  }

  Future<void> _cancelBudgetReminders(int budgetId) async {
    for (int i = 0; i < 20; i++) {
      await _notificationService.cancelNotification(
        NotificationService.budgetLimitBaseId + budgetId * 10 + i,
      );
    }
    
    await _notificationService.cancelNotification(
      NotificationService.budgetReminderBaseId + budgetId,
    );
  }

  Future<void> updateRecurringTransactionReminders(RecurringTransaction transaction) async {
    // Cancel old reminders
    await _notificationService.cancelNotification(
      NotificationService.recurringTransactionBaseId + transaction.id!,
    );
    
    // Schedule new reminders
    if (transaction.isActive) {
      await _scheduleRecurringTransactionReminder(transaction);
    }
  }

  Future<bool> requestPermissions() async {
    return await _notificationService.requestPermissions();
  }

  Future<void> cancelAllReminders() async {
    await _notificationService.cancelAllNotifications();
  }
}

// Extension to add database helper methods for reminders
extension DatabaseHelperReminders on DatabaseHelper {
  Future<double> getSpentAmountForBudget(Budget budget) async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final result = await db.query(
      'expenses',
      columns: ['SUM(amount) as total'],
      where: 'category = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        budget.category,
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
    );
    
    return result.isNotEmpty 
        ? (result.first['total'] as double?) ?? 0.0
        : 0.0;
  }
}