import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../helpers/database_helper.dart';
import 'add_edit_account_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Account> _accounts = [];
  bool _isLoading = true;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _databaseHelper.getAccounts();
      double total = 0.0;
      for (final account in accounts) {
        if (account.isActive) {
          total += account.currentBalance;
        }
      }
      
      setState(() {
        _accounts = accounts;
        _totalBalance = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des comptes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(amount)} FCFA';
  }

  Widget _buildSummaryCard() {
    final activeAccounts = _accounts.where((account) => account.isActive).length;
    final inactiveAccounts = _accounts.where((account) => !account.isActive).length;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8F00), Color(0xFFFFB74D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solde total',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatAmount(_totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Comptes actifs', activeAccounts.toString()),
                _buildSummaryItem('Comptes inactifs', inactiveAccounts.toString()),
                _buildSummaryItem('Total comptes', _accounts.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsList() {
    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun compte trouvé',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour ajouter un compte',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  Widget _buildAccountCard(Account account) {
    final iconData = _getIconData(account.iconName);
    final color = Color(account.colorValue);
    final isPositive = account.currentBalance >= 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: account.isActive ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              iconData,
              color: color,
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: account.isActive ? Colors.black : Colors.grey[500],
                  ),
                ),
              ),
              if (!account.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Inactif',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.typeDisplayName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatAmount(account.currentBalance),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                ),
              ),
              if (account.description != null && account.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  account.description!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editAccount(account),
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
              ),
              IconButton(
                onPressed: () => _deleteAccount(account),
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Supprimer',
              ),
            ],
          ),
          onTap: () => _editAccount(account),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'account_balance': Icons.account_balance,
      'savings': Icons.savings,
      'credit_card': Icons.credit_card,
      'monetization_on_rounded': Icons.monetization_on_rounded,
      'trending_up': Icons.trending_up,
      'account_balance_wallet': Icons.account_balance_wallet,
      'business': Icons.business,
      'local_atm': Icons.local_atm,
      'payment': Icons.payment,
      'account_box': Icons.account_box,
      'wallet': Icons.wallet_outlined,
      'money': Icons.monetization_on,
      'euro': Icons.euro,
      'dollar': Icons.monetization_on,
    };
    return iconMap[iconName] ?? Icons.account_balance_wallet;
  }

  void _addAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditAccountScreen(),
      ),
    ).then((_) => _loadAccounts());
  }

  void _editAccount(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAccountScreen(account: account),
      ),
    ).then((_) => _loadAccounts());
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le compte "${account.name}"?\\n\\n'
          'Cette action ne peut pas être annulée et supprimera également toutes les transactions associées à ce compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _databaseHelper.deleteAccount(account.id!);
        await _loadAccounts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte supprimé avec succès'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes'),
        backgroundColor: const Color(0xFFFF8F00),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Mes comptes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildAccountsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        backgroundColor: const Color(0xFFFF8F00),
        tooltip: 'Ajouter un compte',
        child: const Icon(Icons.add),
      ),
    );
  }
}