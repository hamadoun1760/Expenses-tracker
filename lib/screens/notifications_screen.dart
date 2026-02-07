import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../helpers/database_helper.dart';
import '../utils/theme.dart';
import 'expense_list_screen.dart';
import 'income_list_screen.dart';
import 'goal_management_screen.dart';
import 'statistics_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final notifications = await _databaseHelper.getNotifications(
        unreadOnly: _filter == 'unread'
      );
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    
    await _databaseHelper.markNotificationAsRead(notification.id!);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _databaseHelper.markAllNotificationsAsRead();
    _loadNotifications();
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    await _databaseHelper.deleteNotification(notification.id!);
    _loadNotifications();
  }

  Future<void> _deleteOldNotifications() async {
    await _databaseHelper.deleteOldNotifications(daysOld: 7);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'delete_old':
                  _deleteOldNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Tout marquer comme lu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_old',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Supprimer anciennes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab('Toutes', 'all'),
                ),
                Expanded(
                  child: _buildFilterTab('Non lues', 'unread'),
                ),
              ],
            ),
          ),
          
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _loadNotifications();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6C757D),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final timeAgo = _getTimeAgo(notification.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead 
            ? null 
            : Border.all(color: const Color(0xFF1976D2).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.categoryIcon,
                  color: notification.categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: const Color(0xFF2C2C2E),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6C757D),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        if (notification.actionText != null)
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: () {
                                print('DEBUG: Action button tapped - actionText: ${notification.actionText}, actionType: ${notification.actionType}');
                                _markAsRead(notification);
                                _handleNotificationAction(notification);
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  notification.actionText!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      _markAsRead(notification);
                      break;
                    case 'delete':
                      _deleteNotification(notification);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Marquer comme lu'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              _filter == 'unread' 
                  ? Icons.notifications_active_outlined 
                  : Icons.notifications_none_rounded,
              size: 48,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _filter == 'unread' 
                ? 'Aucune notification non lue'
                : 'Aucune notification',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'unread'
                ? 'Toutes vos notifications ont été lues'
                : 'Les notifications apparaîtront ici',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(AppNotification notification) {
    if (notification.actionType == null || notification.actionType!.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
      );
      return;
    }

    final actionType = notification.actionType!.trim();

    switch (actionType) {
      case 'see_expense_details':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
        );
        break;
      case 'see_income_details':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const IncomeListScreen()),
        );
        break;
      case 'see_goal_progress':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const GoalManagementScreen()),
        );
        break;
      case 'manage_recurring':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
        );
        break;
      case 'explore_statistics':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StatisticsScreen()),
        );
        break;
      case 'download_monthly_report':
        _showMonthlyReportDialog(notification);
        break;
      default:
        print('DEBUG: No case matched for actionType: "$actionType"');
        print('DEBUG: Available cases: see_expense_details, see_income_details, see_goal_progress, manage_recurring, explore_statistics, download_monthly_report');
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
        );
    }
  }

  void _showMonthlyReportDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Rapport Mensuel',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (notification.payload != null)
                Text(
                  'Période: ${notification.payload}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                _downloadMonthlyReport(notification);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Télécharger PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _downloadMonthlyReport(AppNotification notification) {
    // Show a snackbar indicating the download process
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Téléchargement du rapport en cours...'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );

    // In a real app, you would:
    // 1. Generate the PDF report
    // 2. Save it to device storage
    // 3. Open it with a PDF viewer
    // For now, we'll simulate this with a success message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rapport ${notification.payload ?? 'mensuel'} téléchargé avec succès',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }
}