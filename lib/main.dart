import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'utils/theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/expense_filter_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/user_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/onboarding_provider.dart';
import 'services/notification_service.dart';
import 'services/reminder_manager.dart';
import 'widgets/onboarding_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Initialize the database factory based on platform
  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // For desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  // For web and mobile platforms, we'll handle differently in DatabaseHelper
  
  // Initialize notification service
  await NotificationService().initialize();
  await ReminderManager().initialize();
  
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExpenseFilterProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => CurrencyProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => DebtProvider()),
        ChangeNotifierProvider(create: (context) => OnboardingProvider()),
      ],
      child: Consumer2<LocaleProvider, UserProvider>(
        builder: (context, localeProvider, userProvider, child) {
          // Initialize user provider if not already initialized
          if (!userProvider.isLoading && userProvider.currentUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              userProvider.initializeUser();
            });
          }
          
          return MaterialApp(
            title: 'Suivi des Dépenses',
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', ''), // French
              Locale('en', ''), // English
              Locale('es', ''), // Spanish
              Locale('ar', ''), // Arabic
              Locale('pt', ''), // Portuguese
              Locale('sw', ''), // Swahili
            ],
            locale: localeProvider.currentLocale,
            debugShowCheckedModeBanner: false,
            home: const OnboardingWrapper(),
          );
        },
      ),
    );
  }
}