import 'package:flutter/material.dart';
import '../screens/pin_entry_screen.dart';
import '../services/security_service.dart';

class AuthenticationWrapper extends StatefulWidget {
  final Widget child;

  const AuthenticationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper>
    with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isSecurityEnabled = false;
  bool _isLoading = true;
  DateTime? _lastPauseTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSecurityStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // App is paused - immediately lock if security is enabled
      _lastPauseTime = DateTime.now();
      if (_isSecurityEnabled && _isAuthenticated) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed - check if we need to show the lock screen
      if (_lastPauseTime != null && _isSecurityEnabled && !_isAuthenticated) {
        // Lock screen will be shown by the build method since _isAuthenticated is false
      }
      _lastPauseTime = null;
    }
  }

  Future<void> _checkSecurityStatus() async {
    try {
      final isEnabled = await SecurityService.isSecurityEnabled();
      setState(() {
        _isSecurityEnabled = isEnabled;
        _isAuthenticated = !isEnabled; // If security is disabled, user is authenticated
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSecurityEnabled = false;
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  void _onAuthenticationSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onSecurityStatusChanged() {
    _checkSecurityStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isSecurityEnabled && !_isAuthenticated) {
      return PinEntryScreen(
        onSuccess: _onAuthenticationSuccess,
        canCancel: false,
      );
    }

    return AuthenticationInheritedWidget(
      onSecurityStatusChanged: _onSecurityStatusChanged,
      child: widget.child,
    );
  }
}

class AuthenticationInheritedWidget extends InheritedWidget {
  final VoidCallback onSecurityStatusChanged;

  const AuthenticationInheritedWidget({
    super.key,
    required this.onSecurityStatusChanged,
    required super.child,
  });

  static AuthenticationInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthenticationInheritedWidget>();
  }

  @override
  bool updateShouldNotify(AuthenticationInheritedWidget oldWidget) {
    return onSecurityStatusChanged != oldWidget.onSecurityStatusChanged;
  }
}