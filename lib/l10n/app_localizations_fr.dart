// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Suivi des Dépenses';

  @override
  String get allExpenses => 'Toutes les Dépenses';

  @override
  String get statistics => 'Statistiques';

  @override
  String get addExpense => 'Ajouter une Dépense';

  @override
  String get editExpense => 'Modifier la Dépense';

  @override
  String get totalExpenses => 'Total des Dépenses';

  @override
  String get currency => 'FCFA';

  @override
  String get allCategories => 'Toutes les Catégories';

  @override
  String get noExpensesYet => 'Aucune dépense pour le moment';

  @override
  String get tapToAddExpense =>
      'Appuyez sur le bouton + pour ajouter votre première dépense';

  @override
  String get manageFinances => 'Gérez vos finances intelligemment';

  @override
  String get title => 'Titre';

  @override
  String get enterExpenseTitle => 'Entrez le titre de la dépense';

  @override
  String get amount => 'Montant';

  @override
  String get enterAmount => 'Entrez le montant';

  @override
  String get category => 'Catégorie';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description (Optionnelle)';

  @override
  String get enterDescription => 'Entrez une description';

  @override
  String get saveExpense => 'Enregistrer la Dépense';

  @override
  String get updateExpense => 'Mettre à Jour la Dépense';

  @override
  String get cancel => 'Annuler';

  @override
  String get pleaseEnterTitle => 'Veuillez entrer un titre';

  @override
  String get titleMinLength => 'Le titre doit contenir au moins 2 caractères';

  @override
  String get pleaseEnterAmount => 'Veuillez entrer un montant';

  @override
  String get pleaseEnterValidAmount =>
      'Veuillez entrer un montant valide supérieur à 0';

  @override
  String get expenseAddedSuccessfully => 'Dépense ajoutée avec succès';

  @override
  String get expenseUpdatedSuccessfully => 'Dépense mise à jour avec succès';

  @override
  String get errorSavingExpense =>
      'Erreur lors de l\'enregistrement de la dépense';

  @override
  String get categoryBreakdown => 'Répartition par Catégorie';

  @override
  String get monthlyBreakdown => 'Répartition Mensuelle';

  @override
  String get noExpensesToAnalyze => 'Aucune dépense à analyser';

  @override
  String get noMonthlyData => 'Aucune donnée mensuelle disponible';

  @override
  String get noExpensesInCategory => 'Aucune dépense dans cette catégorie';

  @override
  String categoryPercent(String percent) {
    return '$percent% du total';
  }

  @override
  String get food => 'Alimentation';

  @override
  String get transportation => 'Transport';

  @override
  String get entertainment => 'Divertissement';

  @override
  String get shopping => 'Achats';

  @override
  String get health => 'Santé';

  @override
  String get education => 'Éducation';

  @override
  String get other => 'Autre';

  @override
  String get deleteExpense => 'Supprimer la Dépense';

  @override
  String confirmDelete(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\" ?';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get errorLoadingExpenses => 'Erreur lors du chargement des dépenses';

  @override
  String get expenseDeletedSuccessfully => 'Dépense supprimée avec succès';

  @override
  String get errorDeletingExpense =>
      'Erreur lors de la suppression de la dépense';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get theme => 'Thème';

  @override
  String get settings => 'Paramètres';

  @override
  String get export => 'Exporter';

  @override
  String get import => 'Importer';

  @override
  String get search => 'Rechercher';

  @override
  String get filter => 'Filtrer';

  @override
  String get budgets => 'Budgets';

  @override
  String get setBudget => 'Définir un budget';

  @override
  String get editBudget => 'Modifier le budget';

  @override
  String get budgetAmount => 'Montant du budget';

  @override
  String get monthly => 'Mensuel';

  @override
  String get yearly => 'Annuel';

  @override
  String get period => 'Période';

  @override
  String get budgetCreated => 'Budget créé avec succès';

  @override
  String get budgetUpdated => 'Budget mis à jour avec succès';

  @override
  String get budgetDeleted => 'Budget supprimé avec succès';

  @override
  String get noBudgetsSet => 'Aucun budget défini';

  @override
  String get createFirstBudget =>
      'Créez votre premier budget pour suivre vos dépenses';

  @override
  String get budgetExceeded => 'Budget dépassé';

  @override
  String budgetWarning(String percent) {
    return 'Attention: $percent% du budget utilisé';
  }

  @override
  String get searchExpenses => 'Rechercher des dépenses';

  @override
  String get searchHint => 'Titre, description ou catégorie';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByAmount => 'Montant';

  @override
  String get sortByTitle => 'Titre';

  @override
  String get sortByCategory => 'Catégorie';

  @override
  String get ascending => 'Croissant';

  @override
  String get descending => 'Décroissant';

  @override
  String get dateRange => 'Plage de dates';

  @override
  String get amountRange => 'Plage de montants';

  @override
  String get from => 'De';

  @override
  String get to => 'À';

  @override
  String get selectStartDate => 'Sélectionner la date de début';

  @override
  String get selectEndDate => 'Sélectionner la date de fin';

  @override
  String get exportData => 'Exporter les données';

  @override
  String get importData => 'Importer les données';

  @override
  String get exportExpenses => 'Exporter les dépenses';

  @override
  String get exportBudgets => 'Exporter les budgets';

  @override
  String get fullBackup => 'Sauvegarde complète';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String get fileExported => 'Fichier exporté avec succès';

  @override
  String get fileImported => 'Fichier importé avec succès';

  @override
  String get exportError => 'Erreur lors de l\'exportation';

  @override
  String get importError => 'Erreur lors de l\'importation';

  @override
  String get selectFile => 'Sélectionner un fichier';

  @override
  String get csvFormat => 'Format CSV';

  @override
  String get jsonFormat => 'Format JSON';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';

  @override
  String get error => 'Erreur';

  @override
  String get warning => 'Attention';

  @override
  String get success => 'Succès';

  @override
  String get close => 'Fermer';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirmer';

  @override
  String get networkError => 'Erreur de connexion';
}
