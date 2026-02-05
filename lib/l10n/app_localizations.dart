import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// All expenses drawer menu item
  ///
  /// In en, this message translates to:
  /// **'All Expenses'**
  String get allExpenses;

  /// Statistics screen title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Add expense button text
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// Edit expense screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// Total expenses label
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// Currency abbreviation
  ///
  /// In en, this message translates to:
  /// **'FCFA'**
  String get currency;

  /// Filter option for all categories
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// Empty state instruction
  ///
  /// In en, this message translates to:
  /// **'Appuyez sur le bouton + pour ajouter votre première dépense'**
  String get tapToAddExpense;

  /// App subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your finances smartly'**
  String get manageFinances;

  /// Title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Title field hint
  ///
  /// In en, this message translates to:
  /// **'Enter expense title'**
  String get enterExpenseTitle;

  /// Amount field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Amount field hint
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// Category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get description;

  /// Description field hint
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get updateExpense;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Title validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// Title minimum length validation
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 2 characters long'**
  String get titleMinLength;

  /// Amount validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// Amount validation error for invalid values
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than 0'**
  String get pleaseEnterValidAmount;

  /// Success message for adding expense
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully'**
  String get expenseAddedSuccessfully;

  /// Success message for updating expense
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully'**
  String get expenseUpdatedSuccessfully;

  /// Error message when saving fails
  ///
  /// In en, this message translates to:
  /// **'Error saving expense'**
  String get errorSavingExpense;

  /// Category breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// Monthly breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Monthly Breakdown'**
  String get monthlyBreakdown;

  /// Empty statistics message
  ///
  /// In en, this message translates to:
  /// **'No expenses to analyze'**
  String get noExpensesToAnalyze;

  /// Empty monthly data message
  ///
  /// In en, this message translates to:
  /// **'No monthly data available'**
  String get noMonthlyData;

  /// Message when no expenses in selected category
  ///
  /// In en, this message translates to:
  /// **'No expenses in this category'**
  String get noExpensesInCategory;

  /// Category percentage display
  ///
  /// In en, this message translates to:
  /// **'{percent}% of total'**
  String categoryPercent(String percent);

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Delete expense dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// Confirm delete expense message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String confirmDelete(String title);

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Error message when loading expenses fails
  ///
  /// In en, this message translates to:
  /// **'Error loading expenses'**
  String get errorLoadingExpenses;

  /// Success message after expense deletion
  ///
  /// In en, this message translates to:
  /// **'Expense deleted successfully'**
  String get expenseDeletedSuccessfully;

  /// Error message when expense deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting expense'**
  String get errorDeletingExpense;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @setBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get setBudget;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudget;

  /// No description provided for @budgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget Amount'**
  String get budgetAmount;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Budget created successfully'**
  String get budgetCreated;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated successfully'**
  String get budgetUpdated;

  /// No description provided for @budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted successfully'**
  String get budgetDeleted;

  /// No description provided for @noBudgetsSet.
  ///
  /// In en, this message translates to:
  /// **'No budgets set'**
  String get noBudgetsSet;

  /// No description provided for @createFirstBudget.
  ///
  /// In en, this message translates to:
  /// **'Create your first budget to track spending'**
  String get createFirstBudget;

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded'**
  String get budgetExceeded;

  /// No description provided for @budgetWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: {percent}% of budget used'**
  String budgetWarning(String percent);

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get searchExpenses;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Title, description or category'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// No description provided for @sortByAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sortByAmount;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortByTitle;

  /// No description provided for @sortByCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get sortByCategory;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount range'**
  String get amountRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get selectStartDate;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get selectEndDate;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @exportExpenses.
  ///
  /// In en, this message translates to:
  /// **'Export expenses'**
  String get exportExpenses;

  /// No description provided for @exportBudgets.
  ///
  /// In en, this message translates to:
  /// **'Export budgets'**
  String get exportBudgets;

  /// No description provided for @fullBackup.
  ///
  /// In en, this message translates to:
  /// **'Full backup'**
  String get fullBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @fileExported.
  ///
  /// In en, this message translates to:
  /// **'File exported successfully'**
  String get fileExported;

  /// No description provided for @fileImported.
  ///
  /// In en, this message translates to:
  /// **'File imported successfully'**
  String get fileImported;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get selectFile;

  /// No description provided for @csvFormat.
  ///
  /// In en, this message translates to:
  /// **'CSV format'**
  String get csvFormat;

  /// No description provided for @jsonFormat.
  ///
  /// In en, this message translates to:
  /// **'JSON format'**
  String get jsonFormat;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
