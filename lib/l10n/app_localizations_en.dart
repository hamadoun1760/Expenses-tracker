// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get allExpenses => 'All Expenses';

  @override
  String get statistics => 'Statistics';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get currency => 'FCFA';

  @override
  String get allCategories => 'All Categories';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get tapToAddExpense =>
      'Appuyez sur le bouton + pour ajouter votre première dépense';

  @override
  String get manageFinances => 'Manage your finances smartly';

  @override
  String get title => 'Title';

  @override
  String get enterExpenseTitle => 'Enter expense title';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description (Optional)';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get updateExpense => 'Update Expense';

  @override
  String get cancel => 'Cancel';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get titleMinLength => 'Title must be at least 2 characters long';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidAmount =>
      'Please enter a valid amount greater than 0';

  @override
  String get expenseAddedSuccessfully => 'Expense added successfully';

  @override
  String get expenseUpdatedSuccessfully => 'Expense updated successfully';

  @override
  String get errorSavingExpense => 'Error saving expense';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get monthlyBreakdown => 'Monthly Breakdown';

  @override
  String get noExpensesToAnalyze => 'No expenses to analyze';

  @override
  String get noMonthlyData => 'No monthly data available';

  @override
  String get noExpensesInCategory => 'No expenses in this category';

  @override
  String categoryPercent(String percent) {
    return '$percent% of total';
  }

  @override
  String get food => 'Food';

  @override
  String get transportation => 'Transportation';

  @override
  String get entertainment => 'Entertainment';

  @override
  String get shopping => 'Shopping';

  @override
  String get health => 'Health';

  @override
  String get education => 'Education';

  @override
  String get other => 'Other';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String confirmDelete(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get errorLoadingExpenses => 'Error loading expenses';

  @override
  String get expenseDeletedSuccessfully => 'Expense deleted successfully';

  @override
  String get errorDeletingExpense => 'Error deleting expense';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get theme => 'Theme';

  @override
  String get settings => 'Settings';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get budgets => 'Budgets';

  @override
  String get setBudget => 'Set Budget';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get budgetAmount => 'Budget Amount';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get period => 'Period';

  @override
  String get budgetCreated => 'Budget created successfully';

  @override
  String get budgetUpdated => 'Budget updated successfully';

  @override
  String get budgetDeleted => 'Budget deleted successfully';

  @override
  String get noBudgetsSet => 'No budgets set';

  @override
  String get createFirstBudget => 'Create your first budget to track spending';

  @override
  String get budgetExceeded => 'Budget exceeded';

  @override
  String budgetWarning(String percent) {
    return 'Warning: $percent% of budget used';
  }

  @override
  String get searchExpenses => 'Search expenses';

  @override
  String get searchHint => 'Title, description or category';

  @override
  String get noResults => 'No results found';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByAmount => 'Amount';

  @override
  String get sortByTitle => 'Title';

  @override
  String get sortByCategory => 'Category';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get dateRange => 'Date range';

  @override
  String get amountRange => 'Amount range';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get selectStartDate => 'Select start date';

  @override
  String get selectEndDate => 'Select end date';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data';

  @override
  String get exportExpenses => 'Export expenses';

  @override
  String get exportBudgets => 'Export budgets';

  @override
  String get fullBackup => 'Full backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get fileExported => 'File exported successfully';

  @override
  String get fileImported => 'File imported successfully';

  @override
  String get exportError => 'Export error';

  @override
  String get importError => 'Import error';

  @override
  String get selectFile => 'Select file';

  @override
  String get csvFormat => 'CSV format';

  @override
  String get jsonFormat => 'JSON format';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get success => 'Success';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get networkError => 'Network error';
}
