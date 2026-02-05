import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Show error snackbar
  void showError(BuildContext context, String message, {String? title}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Show success message
  void showSuccess(BuildContext context, String message, {String? title}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show warning message
  void showWarning(BuildContext context, String message, {String? title}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Compris',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show loading dialog
  void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(message ?? 'Chargement en cours...'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hide loading dialog
  void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // Show confirmation dialog
  Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Handle and log errors
  Future<T?> handleAsyncOperation<T>(
    Future<T> Function() operation,
    BuildContext context, {
    String? errorMessage,
    String? loadingMessage,
    bool showLoading = false,
    bool showSuccessMessage = false,
    String? successMessage,
  }) async {
    try {
      if (showLoading && context.mounted) {
        showLoadingDialog(context, message: loadingMessage);
      }

      final result = await operation();

      if (showLoading && context.mounted) {
        hideLoadingDialog(context);
      }

      if (showSuccessMessage && context.mounted && successMessage != null) {
        showSuccess(context, successMessage);
      }

      return result;
    } catch (e) {
      if (showLoading && context.mounted) {
        hideLoadingDialog(context);
      }

      if (context.mounted) {
        showError(
          context,
          errorMessage ?? 'Une erreur inattendue s\'est produite',
          title: 'Erreur',
        );
      }

      // Log error for debugging
      if (kDebugMode) {
        print('Error in async operation: $e');
      }

      return null;
    }
  }

  // Retry mechanism
  Future<T?> retryOperation<T>(
    Future<T> Function() operation,
    BuildContext context, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? errorMessage,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        
        if (retryCount >= maxRetries) {
          if (context.mounted) {
            showError(
              context,
              errorMessage ?? 'Opération échouée après $maxRetries tentatives',
              title: 'Erreur',
            );
          }
          return null;
        }
        
        // Wait before retry
        await Future.delayed(delay);
      }
    }
    
    return null;
  }

  // Validate network connectivity (placeholder)
  Future<bool> checkConnectivity() async {
    // This would typically check actual network connectivity
    // For now, we'll assume connectivity is available
    return true;
  }

  // Show network error
  void showNetworkError(BuildContext context) {
    showError(
      context,
      'Vérifiez votre connexion internet et réessayez.',
      title: 'Problème de connexion',
    );
  }

  // Show validation error
  void showValidationError(BuildContext context, List<String> errors) {
    final errorText = errors.join('\n• ');
    showError(
      context,
      '• $errorText',
      title: 'Erreurs de validation',
    );
  }
}

// Custom exception classes
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException(this.message, {this.code, this.originalException});

  @override
  String toString() => 'AppException: $message';
}

class ValidationException extends AppException {
  final List<String> errors;

  ValidationException(this.errors) : super(errors.join(', '));
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.originalException});
}