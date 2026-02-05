import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage onboarding state and persistence
class OnboardingProvider extends ChangeNotifier {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  
  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;
  bool _initialized = false;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLoading => _isLoading;

  /// Initialize the provider by checking if user has completed onboarding
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_initialized) {
      return;
    }
    
    _isLoading = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedOnboarding = prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking onboarding status: $e');
      }
      _hasCompletedOnboarding = false;
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      _hasCompletedOnboarding = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error completing onboarding: $e');
      }
    }
  }

  /// Reset onboarding (for testing purposes)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      _hasCompletedOnboarding = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting onboarding: $e');
      }
    }
  }
}
