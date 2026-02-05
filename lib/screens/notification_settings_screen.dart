import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/reminder_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ReminderManager _reminderManager = ReminderManager();
  
  bool _notificationsEnabled = true;
  bool _goalProgressNotifications = true;
  bool _budgetLimitNotifications = true;
  bool _recurringTransactionReminders = true;
  bool _budgetPlanningReminders = true;
  bool _goalDeadlineReminders = true;
  
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _goalProgressNotifications = prefs.getBool('goal_progress_notifications') ?? true;
        _budgetLimitNotifications = prefs.getBool('budget_limit_notifications') ?? true;
        _recurringTransactionReminders = prefs.getBool('recurring_transaction_reminders') ?? true;
        _budgetPlanningReminders = prefs.getBool('budget_planning_reminders') ?? true;
        _goalDeadlineReminders = prefs.getBool('goal_deadline_reminders') ?? true;
        
        final hour = prefs.getInt('reminder_hour') ?? 9;
        final minute = prefs.getInt('reminder_minute') ?? 0;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('goal_progress_notifications', _goalProgressNotifications);
      await prefs.setBool('budget_limit_notifications', _budgetLimitNotifications);
      await prefs.setBool('recurring_transaction_reminders', _recurringTransactionReminders);
      await prefs.setBool('budget_planning_reminders', _budgetPlanningReminders);
      await prefs.setBool('goal_deadline_reminders', _goalDeadlineReminders);
      
      await prefs.setInt('reminder_hour', _reminderTime.hour);
      await prefs.setInt('reminder_minute', _reminderTime.minute);
      
      if (!_notificationsEnabled) {
        await _reminderManager.cancelAllReminders();
      } else {
        await _reminderManager.initialize();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres de notifications sauvegardés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted 
              ? 'Permissions accordées pour les notifications'
              : 'Permissions refusées pour les notifications',
          ),
          backgroundColor: granted ? Colors.green : Colors.orange,
        ),
      );
    }
    
    if (granted) {
      setState(() {
        _notificationsEnabled = true;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showNotification(
        id: 99999,
        title: 'Test de notification 🔔',
        body: 'Si vous voyez ceci, les notifications fonctionnent correctement!',
        category: NotificationCategory.reminder,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification test envoyée'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return SwitchListTile(
      secondary: icon != null ? Icon(icon) : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      value: value && _notificationsEnabled,
      onChanged: _notificationsEnabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres de notifications'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de notifications'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Sauvegarder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 48,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications & Rappels',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gérez vos préférences de notification pour rester informé de vos finances',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Permission & General Settings
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Paramètres généraux',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text(
                    'Notifications activées',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Active ou désactive toutes les notifications',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Heure des rappels'),
                  subtitle: Text(_reminderTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _notificationsEnabled ? _selectReminderTime : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Demander les permissions'),
                  subtitle: const Text('Autoriser les notifications sur cet appareil'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _requestPermissions,
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Tester les notifications'),
                  subtitle: const Text('Envoyer une notification de test'),
                  trailing: const Icon(Icons.send),
                  onTap: _notificationsEnabled ? _testNotification : null,
                ),
              ],
            ),
          ),
          
          // Goal Notifications
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notifications d\'objectifs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildSettingTile(
                  title: 'Progrès des objectifs',
                  subtitle: 'Notifications lors des étapes importantes (25%, 50%, 75%, 90%)',
                  value: _goalProgressNotifications,
                  onChanged: (value) {
                    setState(() {
                      _goalProgressNotifications = value;
                    });
                  },
                  icon: Icons.trending_up,
                ),
                _buildSettingTile(
                  title: 'Échéances d\'objectifs',
                  subtitle: 'Rappels 7, 3 et 1 jour avant l\'échéance',
                  value: _goalDeadlineReminders,
                  onChanged: (value) {
                    setState(() {
                      _goalDeadlineReminders = value;
                    });
                  },
                  icon: Icons.alarm,
                ),
              ],
            ),
          ),
          
          // Budget Notifications
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notifications de budget',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildSettingTile(
                  title: 'Limites de budget',
                  subtitle: 'Alertes à 80% et 95% du budget mensuel',
                  value: _budgetLimitNotifications,
                  onChanged: (value) {
                    setState(() {
                      _budgetLimitNotifications = value;
                    });
                  },
                  icon: Icons.account_balance_wallet,
                ),
                _buildSettingTile(
                  title: 'Planification mensuelle',
                  subtitle: 'Rappel de planifier le budget du mois suivant',
                  value: _budgetPlanningReminders,
                  onChanged: (value) {
                    setState(() {
                      _budgetPlanningReminders = value;
                    });
                  },
                  icon: Icons.event_note,
                ),
              ],
            ),
          ),
          
          // Transaction Notifications
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notifications de transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildSettingTile(
                  title: 'Transactions récurrentes',
                  subtitle: 'Rappels pour les transactions récurrentes programmées',
                  value: _recurringTransactionReminders,
                  onChanged: (value) {
                    setState(() {
                      _recurringTransactionReminders = value;
                    });
                  },
                  icon: Icons.repeat,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}