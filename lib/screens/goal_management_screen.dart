import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../helpers/database_helper.dart';
import 'add_edit_goal_screen.dart';

class GoalManagementScreen extends StatefulWidget {
  const GoalManagementScreen({super.key});

  @override
  State<GoalManagementScreen> createState() => _GoalManagementScreenState();
}

class _GoalManagementScreenState extends State<GoalManagementScreen> with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Goal> _goals = [];
  late TabController _tabController;
  bool _isLoading = true;
  GoalStatus _currentFilter = GoalStatus.active;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final filters = [GoalStatus.active, GoalStatus.paused, GoalStatus.completed, GoalStatus.cancelled];
    _currentFilter = filters[_tabController.index];
    _loadGoals();
  }

  String _getStatusDisplayName(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return 'Actif';
      case GoalStatus.paused:
        return 'En pause';
      case GoalStatus.completed:
        return 'Terminé';
      case GoalStatus.cancelled:
        return 'Annulé';
    }
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _databaseHelper.getGoals(status: _currentFilter);
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des objectifs: $e'),
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard(
            'Objectifs actifs',
            _goals.where((g) => g.status == GoalStatus.active).length.toString(),
            Icons.flag,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Terminés',
            _goals.where((g) => g.status == GoalStatus.completed).length.toString(),
            Icons.check_circle,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'En retard',
            _goals.where((g) => g.isOverdue).length.toString(),
            Icons.warning,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Urgent',
            _goals.where((g) => g.priority == GoalPriority.urgent).length.toString(),
            Icons.priority_high,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun objectif ${_getStatusDisplayName(_currentFilter).toLowerCase()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour créer votre premier objectif',
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
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final color = Color(goal.colorValue);
    final progress = goal.progressPercentage;
    List<Widget> actionButtons = _buildActionButtons(goal, color);
    return GestureDetector(
      onTap: () => _showGoalDetails(goal),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: goal.isOverdue ? Colors.red.withOpacity(0.3) : color.withOpacity(0.2),
              width: goal.isOverdue ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getIconData(goal.iconName), color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: goal.typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  goal.typeDisplayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: goal.typeColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: goal.priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  goal.priorityDisplayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: goal.priorityColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (goal.isOverdue)
                      Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: progress >= 100 ? Colors.green : color,
                      ),
                    ),
                    Text(
                      '${_formatAmount(goal.currentAmount)} / ${_formatAmount(goal.targetAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 100 ? Colors.green : color,
                  ),
                  minHeight: 6,
                ),
                const SizedBox(height: 12),
                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Échéance',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(goal.targetDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: goal.isOverdue ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jours restants',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          goal.daysRemaining.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: goal.isOverdue ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restant',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatAmount(goal.remainingAmount),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actionButtons,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGoalDetails(Goal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(goal.colorValue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getIconData(goal.iconName), color: Color(goal.colorValue), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Description:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(goal.description ?? 'Aucune description', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Text('Montant cible:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_formatAmount(goal.targetAmount)),
                const SizedBox(height: 8),
                Text('Montant actuel:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_formatAmount(goal.currentAmount)),
                const SizedBox(height: 8),
                Text('Date de début:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_formatDate(goal.startDate)),
                const SizedBox(height: 8),
                Text('Date d\'échéance:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_formatDate(goal.targetDate)),
                const SizedBox(height: 8),
                Text('Priorité:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(goal.priorityDisplayName),
                const SizedBox(height: 8),
                Text('Statut:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(goal.statusDisplayName),
                const SizedBox(height: 8),
                Text('Jours restants:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(goal.daysRemaining.toString()),
                const SizedBox(height: 8),
                Text('Montant restant:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(_formatAmount(goal.remainingAmount)),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(goal.progressPercentage >= 100 ? Colors.green : Color(goal.colorValue)),
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Text('Progression: ${goal.progressPercentage.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'flag': Icons.flag,
      'savings': Icons.savings,
      'trending_up': Icons.trending_up,
      'trending_down': Icons.trending_down,
      'payment': Icons.payment,
      'home': Icons.home,
      'car': Icons.directions_car,
      'travel': Icons.flight,
      'education': Icons.school,
      'health': Icons.local_hospital,
      'gift': Icons.card_giftcard,
      'business': Icons.business,
      'star': Icons.star,
      'heart': Icons.favorite,
      'diamond': Icons.diamond,
    };
    return iconMap[iconName] ?? Icons.flag;
  }

  void _addGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditGoalScreen(),
      ),
    ).then((_) => _loadGoals());
  }

  void _editGoal(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditGoalScreen(goal: goal),
      ),
    ).then((_) => _loadGoals());
  }

  Future<void> _updateProgress(Goal goal) async {
    final controller = TextEditingController();
    final addedAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mettre à jour: ${goal.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Montant actuel: ${_formatAmount(goal.currentAmount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Montant à ajouter',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.pop(context, amount);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (addedAmount != null && addedAmount > 0 && mounted) {
      try {
        final newTotal = goal.currentAmount + addedAmount;
        await _databaseHelper.updateGoalProgress(goal.id!, newTotal);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progrès mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour du progrès'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _undoProgress(Goal goal) async {
    final controller = TextEditingController();
    final removedAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler progrès: ${goal.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Montant actuel: ${_formatAmount(goal.currentAmount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Montant à soustraire',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.pop(context, amount);
            },
            child: const Text('Soustraire'),
          ),
        ],
      ),
    );

    if (removedAmount != null && removedAmount > 0 && removedAmount <= goal.currentAmount && mounted) {
      try {
        final newTotal = goal.currentAmount - removedAmount;
        await _databaseHelper.updateGoalProgress(goal.id!, newTotal);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progrès annulé avec succès'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'annulation du progrès'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pauseGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mettre en pause: ${goal.title}'),
        content: const Text('Voulez-vous vraiment mettre cet objectif en pause ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _databaseHelper.updateGoal(goal.copyWith(status: GoalStatus.paused));
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Objectif mis en pause'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise en pause'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _resumeGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reprendre: ${goal.title}'),
        content: const Text('Voulez-vous vraiment reprendre cet objectif ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _databaseHelper.updateGoal(goal.copyWith(status: GoalStatus.active));
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Objectif repris'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la reprise'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terminer: ${goal.title}'),
        content: const Text('Voulez-vous vraiment marquer cet objectif comme terminé ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _databaseHelper.updateGoal(goal.copyWith(status: GoalStatus.completed, currentAmount: goal.targetAmount));
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Objectif marqué comme terminé'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la complétion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler: ${goal.title}'),
        content: const Text('Voulez-vous vraiment annuler cet objectif ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _databaseHelper.updateGoal(goal.copyWith(status: GoalStatus.cancelled));
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Objectif annulé'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'annulation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer: ${goal.title}'),
        content: const Text('Voulez-vous vraiment supprimer cet objectif ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _databaseHelper.deleteGoal(goal.id!);
        await _loadGoals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Objectif supprimé'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Widget> _buildActionButtons(Goal goal, Color color) {
    List<Widget> actionButtons = [
      TextButton.icon(
        onPressed: () => _editGoal(goal),
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Modifier'),
        style: TextButton.styleFrom(
          foregroundColor: color,
        ),
      ),
    ];
    if (goal.status == GoalStatus.active && !goal.isCompleted) {
      actionButtons.add(TextButton.icon(
        onPressed: () => _updateProgress(goal),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Progrès'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.green,
        ),
      ));
      actionButtons.add(TextButton.icon(
        onPressed: () => _undoProgress(goal),
        icon: const Icon(Icons.remove, size: 16),
        label: const Text('Annuler progrès'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
        ),
      ));
      actionButtons.add(TextButton.icon(
        onPressed: () => _pauseGoal(goal),
        icon: const Icon(Icons.pause, size: 16),
        label: const Text('Pause'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
        ),
      ));
      actionButtons.add(TextButton.icon(
        onPressed: () => _completeGoal(goal),
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text('Terminer'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      ));
      actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(TextButton.icon(
        onPressed: () => _cancelGoal(goal),
        icon: const Icon(Icons.cancel, size: 16),
        label: const Text('Annuler'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      ));
    }
    if (goal.status == GoalStatus.paused) {
      actionButtons.add(TextButton.icon(
        onPressed: () => _resumeGoal(goal),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Reprendre'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.green,
        ),
      ));
      actionButtons.add(TextButton.icon(
        onPressed: () => _completeGoal(goal),
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text('Terminer'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      ));
      actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(TextButton.icon(
        onPressed: () => _cancelGoal(goal),
        icon: const Icon(Icons.cancel, size: 16),
        label: const Text('Annuler'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      ));
    }
    // Delete button always available
    actionButtons.add(TextButton.icon(
      onPressed: () => _deleteGoal(goal),
      icon: const Icon(Icons.delete, size: 16),
      label: const Text('Supprimer'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
      ),
    ));
    return actionButtons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes objectifs'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGoals,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Actifs', icon: Icon(Icons.flag)),
            Tab(text: 'En pause', icon: Icon(Icons.pause)),
            Tab(text: 'Terminés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Annulés', icon: Icon(Icons.cancel)),
          ],
          isScrollable: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoalsList(),
                      _buildGoalsList(),
                      _buildGoalsList(),
                      _buildGoalsList(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        tooltip: 'Créer un objectif',
        child: const Icon(Icons.add),
      ),
    );
  }
}