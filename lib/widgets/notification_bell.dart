import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../screens/notifications_screen.dart';
import '../utils/theme.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> 
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  int _unreadCount = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _databaseHelper.getUnreadNotificationCount();
      if (mounted) {
        setState(() => _unreadCount = count);
        
        // Animate if there are new notifications
        if (count > 0) {
          _animationController.repeat(reverse: true);
        } else {
          _animationController.stop();
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    ).then((_) {
      // Refresh count when returning from notifications screen
      _loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _unreadCount > 0 ? _pulseAnimation.value : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _navigateToNotifications,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      _unreadCount > 0 
                          ? Icons.notifications_active_rounded 
                          : Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    
                    // Notification badge
                    if (_unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4444),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}