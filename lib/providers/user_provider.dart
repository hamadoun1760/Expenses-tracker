import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../helpers/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isUserLoggedIn => _currentUser != null;

  Future<void> initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user exists in local storage
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      
      if (userId != null) {
        final user = await _databaseHelper.getUser(userId);
        if (user != null) {
          _currentUser = user;
        } else {
          // User ID exists but user not found in database, clear it
          await prefs.remove('current_user_id');
        }
      }
      
      // If no user exists, create a default user
      if (_currentUser == null) {
        await _createDefaultUser();
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      await _createDefaultUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultUser() async {
    try {
      final defaultUser = User(
        firstName: 'Utilisateur',
        lastName: 'Default',
        email: 'user@example.com',
        createdAt: DateTime.now(),
      );
      
      final userId = await _databaseHelper.insertUser(defaultUser);
      _currentUser = defaultUser.copyWith(id: userId);
      
      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', userId);
      
    } catch (e) {
      debugPrint('Error creating default user: $e');
    }
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _databaseHelper.updateUser(updatedUser);
      _currentUser = updatedUser;
      
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(User user) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userId = await _databaseHelper.insertUser(user);
      _currentUser = user.copyWith(id: userId);
      
      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', userId);
      
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser() async {
    if (_currentUser?.id == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _databaseHelper.deleteUser(_currentUser!.id!);
      _currentUser = null;
      
      // Remove user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  // User preferences getters
  String get userLanguage => _currentUser?.language ?? 'fr';
  String get userTheme => _currentUser?.theme ?? 'system';
  String get userCurrency => _currentUser?.defaultCurrency ?? 'EUR';
  bool get userNotificationsEnabled => _currentUser?.notificationsEnabled ?? true;
  bool get userBiometricEnabled => _currentUser?.biometricEnabled ?? false;

  // Update user preferences
  Future<void> updateUserLanguage(String language) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      language: language,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateUserTheme(String theme) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      theme: theme,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateUserCurrency(String currency) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      defaultCurrency: currency,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateUserNotifications(bool enabled) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      notificationsEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  Future<void> updateUserBiometric(bool enabled) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      biometricEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }
}