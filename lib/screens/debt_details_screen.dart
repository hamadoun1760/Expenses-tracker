import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../services/whatsapp_service.dart';
import '../widgets/modern_animations.dart';
import 'add_edit_debt_screen.dart';
import 'simple_add_debt_screen.dart';

class DebtDetailsScreen extends StatefulWidget {
  final Debt debt;

  const DebtDetailsScreen({super.key, required this.debt});

  @override
  State<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends State<DebtDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _paymentAmountController = TextEditingController();
  final _paymentDescriptionController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _isExtraPayment = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _paymentAmountController.dispose();
    _paymentDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFEEF2F7),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Consumer<DebtProvider>(
              builder: (context, debtProvider, child) {
                final currentDebt = debtProvider.debts.firstWhere(
                  (d) => d.id == widget.debt.id,
                  orElse: () => widget.debt,
                );
                final payments = debtProvider.getPaymentsForDebt(widget.debt.id!);

                return CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(context, currentDebt),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildDebtHeader(context, currentDebt),
                          _buildDebtSummary(context, currentDebt),
                          _buildProgressCard(context, currentDebt),
                          _buildQuickActions(context, currentDebt),
                          _buildPaymentHistory(context, payments),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, Debt debt) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
      ),
      actions: [
        IconButton(
          onPressed: () => _editDebt(context, debt),
          icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
          tooltip: 'Modifier',
        ),
        IconButton(
          onPressed: () => _deleteDebt(context, debt),
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Supprimer',
        ),
      ],
    );
  }

  Widget _buildDebtHeader(BuildContext context, Debt debt) {
    final isDette = debt.transactionType == DebtTransactionType.dette;
    final headerGradientColors = isDette
        ? [const Color(0xFF1976D2), const Color(0xFF42A5F5)]
        : [const Color(0xFF388E3C), const Color(0xFF66BB6A)];
    final headerShadowColor = isDette 
        ? const Color(0xFF1976D2)
        : const Color(0xFF388E3C);
    final headerIcon = isDette
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: headerGradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: headerShadowColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                headerIcon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    debt.typeDisplayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (debt.status == DebtStatus.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummary(BuildContext context, Debt debt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedCard(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Solde Actuel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${debt.currentBalance.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'sur ${debt.originalAmount.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedCard(
              delay: 200,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Paiement Min.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${debt.minimumPayment.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${debt.interestRate.toStringAsFixed(1)}% TAE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Debt debt) {
    final estimatedPayoffDate = debt.estimatedPayoffDate;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedCard(
        delay: 400,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: debt.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      debt.statusDisplayName,
                      style: TextStyle(
                        color: debt.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: debt.paidPercentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(debt.paidPercentage * 100).toStringAsFixed(1)}% remboursé',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: debt.statusColor,
                    ),
                  ),
                  Text(
                    '${((1 - debt.paidPercentage) * 100).toStringAsFixed(1)}% restant',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (estimatedPayoffDate != null) ...[
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remboursement estimé: ${DateFormat('dd/MM/yyyy').format(estimatedPayoffDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Debt debt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedCard(
                  delay: 600,
                  child: BouncyButton(
                    onPressed: () => _addPayment(context, debt),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1976D2),
                            Color(0xFF42A5F5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ajouter Paiement',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedCard(
                  delay: 800,
                  child: BouncyButton(
                    onPressed: () => _showProjections(context, debt),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF1976D2),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.analytics,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Projections',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1976D2),
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCard(
            delay: 1000,
            child: BouncyButton(
              onPressed: () => _sendWhatsAppReminder(context, debt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF25D366),
                      Color(0xFF128C7E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.message,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Rappel WhatsApp',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(BuildContext context, List<DebtPayment> payments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedCard(
        delay: 1000,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Historique des Paiements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (payments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun paiement enregistré',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: payment.isExtraPayment
                              ? Colors.green.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          payment.isExtraPayment ? Icons.star : Icons.payment,
                          color: payment.isExtraPayment ? Colors.green : Colors.blue,
                        ),
                      ),
                      title: Text(
                        '${payment.amount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(payment.paymentDate),
                          ),
                          if (payment.description != null && payment.description!.isNotEmpty)
                            Text(
                              payment.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      trailing: payment.isExtraPayment
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Extra',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editDebt(BuildContext context, Debt debt) async {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    
    if (debt.transactionType == DebtTransactionType.creance) {
      // Use SimpleAddDebtScreen for créances
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SimpleAddDebtScreen(
            transactionType: debt.transactionType,
            debt: debt,
          ),
        ),
      );
    } else {
      // Use AddEditDebtScreen for dettes
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddEditDebtScreen(
            debt: debt,
            transactionType: debt.transactionType,
          ),
        ),
      );
    }
    
    // Reload debts after returning from edit
    if (mounted) {
      await debtProvider.loadDebts();
    }
  }

  void _deleteDebt(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${debt.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<DebtProvider>(context, listen: false)
                    .deleteDebt(debt.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dette supprimée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addPayment(BuildContext context, Debt debt) {
    _paymentAmountController.clear();
    _paymentDescriptionController.clear();
    _paymentDate = DateTime.now();
    _isExtraPayment = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF42A5F5),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ajouter un Paiement',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rembourser votre dette',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _paymentAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Montant *',
                              hintText: debt.minimumPayment.toStringAsFixed(0),
                              prefixIcon: const Icon(Icons.money),
                              suffixText: 'FCFA',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                              labelStyle: const TextStyle(
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _paymentDescriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description (optionnelle)',
                              hintText: 'Note sur le paiement...',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                              labelStyle: const TextStyle(
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            title: const Text('Paiement supplémentaire'),
                            subtitle: const Text('En plus du paiement minimum'),
                            value: _isExtraPayment,
                            onChanged: (value) {
                              setState(() {
                                _isExtraPayment = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF1976D2),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () async {
                                if (_paymentAmountController.text.trim().isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Erreur'),
                                      content: const Text('Veuillez entrer un montant'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                                
                                final paymentAmount = double.tryParse(_paymentAmountController.text);
                                
                                if (paymentAmount == null || paymentAmount <= 0) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Erreur'),
                                      content: const Text('Veuillez entrer un montant valide'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                                
                                if (paymentAmount > debt.currentBalance) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Montant Invalide'),
                                      content: Text('Le montant ne peut pas dépasser le solde restant (${debt.currentBalance.toStringAsFixed(0)} FCFA)'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                                
                                setState(() {
                                  _isLoading = true;
                                });
                                
                                try {
                                  final payment = DebtPayment(
                                    debtId: debt.id!,
                                    amount: paymentAmount,
                                    paymentDate: _paymentDate,
                                    description: _paymentDescriptionController.text.trim().isEmpty
                                        ? null
                                        : _paymentDescriptionController.text.trim(),
                                    isExtraPayment: _isExtraPayment,
                                    createdAt: DateTime.now(),
                                  );

                                  await Provider.of<DebtProvider>(context, listen: false)
                                      .addPayment(payment);

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Paiement ajouté avec succès'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Ajouter Paiement',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
            },
          );
        },
      ),
    );
  }

  void _showProjections(BuildContext context, Debt debt) {
    // ===== VALIDATION LAYER =====
    final monthlyPayment = debt.minimumPayment;
    final currentBalance = debt.currentBalance;
    final annualRate = debt.interestRate;

    // Guard: Check for invalid inputs
    if (currentBalance <= 0) {
      _showErrorDialog(context, 'Erreur', 'Le solde du prêt doit être supérieur à 0.');
      return;
    }

    if (monthlyPayment <= 0) {
      _showErrorDialog(context, 'Erreur', 'Le paiement mensuel doit être supérieur à 0.');
      return;
    }

    if (annualRate < 0 || annualRate > 100) {
      _showErrorDialog(context, 'Erreur', 'Le taux d\'intérêt doit être entre 0 et 100%.');
      return;
    }

    final interestRate = annualRate / 100 / 12; // Monthly rate
    final monthlyInterest = currentBalance * interestRate;

    // Warning: Check if payment barely covers interest
    if (monthlyPayment < monthlyInterest * 0.95) {
      _showWarningDialog(
        context,
        'Attention',
        'Le paiement mensuel (${monthlyPayment.toStringAsFixed(0)} FCFA) est inférieur aux intérêts mensuels (${monthlyInterest.toStringAsFixed(0)} FCFA). La dette augmentera.',
      );
      return;
    }

    // ===== CALCULATION LAYER =====
    List<Map<String, dynamic>> projections = [];
    double remainingBalance = currentBalance;
    DateTime currentDate = DateTime.now();
    double totalInterestPaid = 0;
    const int maxMonths = 60;
    const double balanceThreshold = 0.01; // Stop when balance < 0.01 (essentially paid off)

    // Calculate projections for up to 60 months or until debt is paid off
    for (int i = 0; i < maxMonths && remainingBalance > balanceThreshold; i++) {
      final interestPayment = remainingBalance * interestRate;
      final principalPayment = (monthlyPayment - interestPayment).clamp(0, remainingBalance);
      final totalPayment = interestPayment + principalPayment;

      remainingBalance -= principalPayment;
      totalInterestPaid += interestPayment;

      // Round to 2 decimal places for currency accuracy
      projections.add({
        'month': i + 1,
        'date': currentDate.add(Duration(days: 30 * (i + 1))),
        'payment': (totalPayment * 100).round() / 100,
        'principal': (principalPayment * 100).round() / 100,
        'interest': (interestPayment * 100).round() / 100,
        'balance': (remainingBalance.clamp(0, double.infinity) * 100).round() / 100,
      });

      if (remainingBalance <= balanceThreshold) break;
    }

    // Guard: Check if no projections were generated
    if (projections.isEmpty) {
      _showErrorDialog(context, 'Erreur', 'Impossible de calculer les projections. Vérifiez les données du prêt.');
      return;
    }

    // Guard: Check if debt never gets paid off (safety net)
    if (projections.length == maxMonths && projections.last['balance'] as double > balanceThreshold) {
      _showWarningDialog(
        context,
        'Attention',
        'Au rythme actuel de ${monthlyPayment.toStringAsFixed(0)} FCFA par mois, le prêt ne sera pas remboursé dans 5 ans. Augmentez votre paiement mensuel.',
      );
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Projections de Remboursement',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${debt.name} - ${debt.typeDisplayName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProjectionStat('Solde Actuel', '${currentBalance.toStringAsFixed(0)} FCFA'),
                          const SizedBox(height: 12),
                          _buildProjectionStat('Paiement Mensuel', '${monthlyPayment.toStringAsFixed(0)} FCFA'),
                          const SizedBox(height: 12),
                          _buildProjectionStat('Mois Estimés', '${projections.length}'),
                          const SizedBox(height: 12),
                          _buildProjectionStat('Intérêts Totaux', '${totalInterestPaid.toStringAsFixed(0)} FCFA', isImportant: true),
                          const SizedBox(height: 12),
                          if (projections.isNotEmpty)
                            _buildProjectionStat(
                              'Date Estimée de Remboursement',
                              DateFormat('dd/MM/yyyy').format(projections.last['date'] as DateTime),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Détail des Paiements (premiers 12 mois)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 8,
                          headingRowHeight: 40,
                          dataRowHeight: 36,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Mois',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Paiement',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Capital',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Intérêts',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Solde',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                          rows: projections
                              .take(12)
                              .map(
                                (proj) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text('${proj['month']}', style: const TextStyle(fontSize: 11)),
                                    ),
                                    DataCell(
                                      Text(
                                        (proj['payment'] as double).toStringAsFixed(0),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        (proj['principal'] as double).toStringAsFixed(0),
                                        style: const TextStyle(color: Colors.green, fontSize: 11),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        (proj['interest'] as double).toStringAsFixed(0),
                                        style: const TextStyle(color: Colors.red, fontSize: 11),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        (proj['balance'] as double).toStringAsFixed(0),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectionStat(String label, String value, {bool isImportant = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isImportant ? Colors.red : const Color(0xFF1976D2),
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  // ===== ERROR HANDLING HELPERS =====
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  // ===== WHATSAPP REMINDER =====
  Future<void> _sendWhatsAppReminder(BuildContext context, Debt debt) async {
    try {
      if (debt.phoneNumber.isEmpty) {
        _showErrorDialog(
          context,
          'Numéro absent',
          'Veuillez ajouter un numéro de téléphone pour ce débiteur/créancier.',
        );
        return;
      }

      await WhatsAppService().sendDebtReminder(
        phoneNumber: debt.phoneNumber,
        name: debt.debtorCreditorName,
        amount: debt.currentBalance,
        description: debt.description,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rappel envoyé via WhatsApp ✓'),
            backgroundColor: Color(0xFF25D366),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Erreur WhatsApp',
          'WhatsApp n\'est pas installé ou une erreur est survenue: ${e.toString()}',
        );
      }
    }
  }
}
