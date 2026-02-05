import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../services/export_service.dart';
import '../helpers/database_helper.dart';
import '../services/security_service.dart';
import '../widgets/authentication_wrapper.dart';
import 'notification_settings_screen.dart';
import 'pin_setup_screen.dart';
import 'user_profile_screen.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ExportService _exportService = ExportService();
  
  bool _showDecimalAmounts = true;
  bool _showCategoryIcons = true;
  String _dateFormat = 'dd/MM/yyyy';
  bool _autoBackup = false;
  bool _isSecurityEnabled = false;
  String _authType = 'PIN';
  int _autoLockMinutes = 5;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showDecimalAmounts = prefs.getBool('show_decimal_amounts') ?? true;
      _showCategoryIcons = prefs.getBool('show_category_icons') ?? true;
      _dateFormat = prefs.getString('date_format') ?? 'dd/MM/yyyy';
      _autoBackup = prefs.getBool('auto_backup') ?? false;
    });
    
    // Load security settings
    _loadSecuritySettings();
  }
  


  Future<void> _loadSecuritySettings() async {
    final isEnabled = await SecurityService.isSecurityEnabled();
    final authType = await SecurityService.getAuthType();
    final autoLockTime = await SecurityService.getAutoLockTime();
    
    setState(() {
      _isSecurityEnabled = isEnabled;
      _authType = authType == AuthType.pin ? 'PIN' : 'Mot de passe';
      _autoLockMinutes = autoLockTime;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _showAboutDialog() async {
    showAboutDialog(
      context: context,
      applicationName: 'Expenses Tracking',
      applicationVersion: '2.1.0',
      applicationLegalese: '© 2026 Expenses Tracking App. Tous droits réservés.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Application moderne et intuitive pour une gestion complète de vos finances personnelles. '
          'Optimisée pour le marché francophone avec support natif du FCFA.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Fonctionnalités Principales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Suivi intelligent des dépenses et revenus'),
              Text('• Gestion budgétaire avec alertes automatiques'),
              Text('• Tableaux de bord et statistiques avancées'),
              Text('• Catégorisation personnalisée des transactions'),
              Text('• Gestion des dettes et créances'),
              Text('• Export multi-format (CSV, PDF)'),
              Text('• Interface française optimisée'),
              Text('• Support monnaie FCFA'),
              Text('• Synchronisation sécurisée des données'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Sécurité & Confidentialité',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Chiffrement de bout en bout'),
              Text('• Authentification par code PIN'),
              Text('• Stockage local sécurisé'),
              Text('• Aucune collecte de données personnelles'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Développé par Hamadou Kassogue • Version française • Mise à jour Janvier 2026',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Attention'),
        content: const Text(
          'Cette action supprimera toutes vos données de façon définitive. '
          'Voulez-vous vraiment continuer?\n\n'
          'Conseil: Exportez vos données avant de les supprimer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer tout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Clear all database data
        final expenses = await _databaseHelper.getExpenses();
        final incomes = await _databaseHelper.getIncomes();
        
        for (var expense in expenses) {
          await _databaseHelper.deleteExpense(expense.id!);
        }
        
        for (var income in incomes) {
          await _databaseHelper.deleteIncome(income.id!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les données ont été supprimées'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      await _exportService.exportData(
        format: ExportFormat.pdf,
        type: ExportType.all,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données exportées avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1976D2), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
  }) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: const Color(0xFF1976D2)) : null,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1976D2),
        activeTrackColor: const Color(0xFF1976D2).withOpacity(0.3),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }



  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure(s)';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s)';
    } else {
      return 'À l\'instant';
    }
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF1976D2)),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // User Profile Section
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_circle, color: const Color(0xFF1976D2)),
                            const SizedBox(width: 8),
                            Text(
                              'Mon Profil',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                      if (user != null) ...[
                        ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              border: Border.all(
                                color: const Color(0xFF1976D2),
                                width: 2,
                              ),
                            ),
                            child: user.profilePicture != null
                                ? ClipOval(
                                    child: Image.memory(
                                      user.profilePicture!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                          ),
                          title: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(user.email),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserProfileScreen(),
                              ),
                            );
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ] else ...[
                        const ListTile(
                          leading: Icon(Icons.account_circle, size: 50),
                          title: Text('Aucun utilisateur connecté'),
                          subtitle: Text('Créez un profil pour personnaliser l\'application'),
                        ),
                      ],
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // App Preferences Section
            _buildSettingsSection(
              title: 'Préférences',
              icon: Icons.tune_rounded,
              children: [
                _buildSwitchTile(
                  title: 'Afficher les décimales',
                  subtitle: 'Montants avec centimes (ex: 1500.00 FCFA)',
                  value: _showDecimalAmounts,
                  icon: Icons.pin,
                  onChanged: (value) {
                    setState(() {
                      _showDecimalAmounts = value;
                    });
                    _saveSetting('show_decimal_amounts', value);
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Icônes des catégories',
                  subtitle: 'Afficher les icônes colorées pour chaque catégorie',
                  value: _showCategoryIcons,
                  icon: Icons.category_rounded,
                  onChanged: (value) {
                    setState(() {
                      _showCategoryIcons = value;
                    });
                    _saveSetting('show_category_icons', value);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.date_range_rounded, color: Color(0xFF1976D2)),
                  title: const Text('Format de date'),
                  subtitle: Text('Actuel: $_dateFormat'),
                  trailing: DropdownButton<String>(
                    value: _dateFormat,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('25/01/2026')),
                      DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('01/25/2026')),
                      DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('2026-01-25')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _dateFormat = value;
                        });
                        _saveSetting('date_format', value);
                      }
                    },
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),

            // Security Section
            _buildSettingsSection(
              title: 'Sécurité',
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  title: 'Code PIN',
                  subtitle: _isSecurityEnabled 
                      ? 'Protection par $_authType activée'
                      : 'Protégez l\'application avec un PIN',
                  value: _isSecurityEnabled,
                  icon: Icons.lock,
                  onChanged: _toggleSecurity,
                ),
                if (_isSecurityEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                    title: const Text('Modifier le PIN'),
                    subtitle: const Text('Changer votre code PIN actuel'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePin,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Color(0xFF1976D2)),
                    title: const Text('Verrouillage automatique'),
                    subtitle: Text('Après $_autoLockMinutes minutes d\'inactivité'),
                    trailing: DropdownButton<int>(
                      value: _autoLockMinutes,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 min')),
                        DropdownMenuItem(value: 5, child: Text('5 min')),
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 60, child: Text('1 heure')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _setAutoLockTime(value);
                        }
                      },
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),

            // Notification Settings
            _buildSettingsSection(
              title: 'Notifications',
              icon: Icons.notifications_rounded,
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1976D2)),
                  title: const Text('Paramètres de notification'),
                  subtitle: const Text('Gérer les rappels et alertes'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),




            // Data Management Section
            _buildSettingsSection(
              title: 'Gestion des données',
              icon: Icons.storage_rounded,
              children: [
                _buildActionTile(
                  title: 'Exporter toutes les données',
                  subtitle: 'Sauvegarde complète en JSON',
                  icon: Icons.download_rounded,
                  onTap: _exportAllData,
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Sauvegarde automatique',
                  subtitle: 'Export automatique hebdomadaire',
                  value: _autoBackup,
                  icon: Icons.backup_rounded,
                  onChanged: (value) {
                    setState(() {
                      _autoBackup = value;
                    });
                    _saveSetting('auto_backup', value);
                  },
                ),
                const Divider(),
                _buildActionTile(
                  title: 'Effacer toutes les données',
                  subtitle: 'Suppression définitive (irréversible)',
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  onTap: _clearAllData,
                ),
              ],
            ),

            // Notifications Section
            // About Section
            _buildSettingsSection(
              title: 'À propos',
              icon: Icons.info_rounded,
              children: [
                _buildActionTile(
                  title: 'À propos de l\'app',
                  subtitle: 'Version, informations et crédits',
                  icon: Icons.info_outline_rounded,
                  onTap: _showAboutDialog,
                ),
              ],
            ),

            const SizedBox(height: 32),
            
            // Version info
            Center(
              child: Text(
                'Version 2.1.0 • Expenses Tracking App',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Security-related methods
  Future<void> _toggleSecurity(bool enabled) async {
    if (enabled) {
      // Show PIN setup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            onSuccess: () {
              Navigator.pop(context);
              _loadSecuritySettings();
              _notifySecurityChange();
            },
          ),
        ),
      );
    } else {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Désactiver la sécurité'),
          content: const Text(
            'Êtes-vous sûr de vouloir désactiver la protection par PIN? '
            'L\'application ne sera plus protégée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Désactiver', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await SecurityService.disableSecurity();
        if (success) {
          _loadSecuritySettings();
          _notifySecurityChange();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sécurité désactivée'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _changePin() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(
          isChangingPin: true,
          onSuccess: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN modifié avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _setAutoLockTime(int minutes) async {
    final success = await SecurityService.setAutoLockTime(minutes);
    if (success) {
      setState(() {
        _autoLockMinutes = minutes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verrouillage automatique: $minutes minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _notifySecurityChange() {
    // Notify the authentication wrapper that security status changed
    final authWrapper = AuthenticationInheritedWidget.of(context);
    authWrapper?.onSecurityStatusChanged();
  }
}