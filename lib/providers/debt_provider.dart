import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../helpers/database_helper.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<Debt> _debts = [];
  List<DebtPayment> _payments = [];
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  List<Debt> get activeDebts => _debts.where((debt) => debt.status == DebtStatus.active).toList();
  List<DebtPayment> get payments => _payments;
  bool get isLoading => _isLoading;

  double get totalDebt => _debts.fold(0.0, (sum, debt) => sum + debt.currentBalance);
  double get totalOriginalDebt => _debts.fold(0.0, (sum, debt) => sum + debt.originalAmount);
  double get totalPaidOff => totalOriginalDebt - totalDebt;
  double get progressPercentage => totalOriginalDebt > 0 ? (totalPaidOff / totalOriginalDebt) * 100 : 0.0;
  
  double get totalMinimumPayments => activeDebts.fold(0.0, (sum, debt) => sum + debt.minimumPayment);
  double get totalInterestEstimate => activeDebts.fold(0.0, (sum, debt) => sum + debt.totalInterestEstimate);

  Debt? getHighestInterestDebt() {
    if (activeDebts.isEmpty) return null;
    return activeDebts.reduce((a, b) => a.interestRate > b.interestRate ? a : b);
  }

  Debt? getSmallestDebt() {
    if (activeDebts.isEmpty) return null;
    return activeDebts.reduce((a, b) => a.currentBalance < b.currentBalance ? a : b);
  }

  List<Debt> getDebtsByStrategy(PaymentStrategy strategy) {
    final active = activeDebts;
    switch (strategy) {
      case PaymentStrategy.avalanche:
        active.sort((a, b) => b.interestRate.compareTo(a.interestRate));
        break;
      case PaymentStrategy.snowball:
        active.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
        break;
      case PaymentStrategy.custom:
        // Keep current order or implement custom logic
        break;
    }
    return active;
  }

  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _debts = await _databaseHelper.getDebts();
      _payments = await _databaseHelper.getDebtPayments();
    } catch (e) {
      debugPrint('Error loading debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt(Debt debt) async {
    try {
      _isLoading = true;
      notifyListeners();

      final id = await _databaseHelper.insertDebt(debt);
      final newDebt = debt.copyWith(id: id);
      _debts.add(newDebt);
    } catch (e) {
      debugPrint('Error adding debt: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDebt(Debt debt) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseHelper.updateDebt(debt);
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = debt;
      }
    } catch (e) {
      debugPrint('Error updating debt: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDebt(int debtId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseHelper.deleteDebt(debtId);
      _debts.removeWhere((debt) => debt.id == debtId);
      _payments.removeWhere((payment) => payment.debtId == debtId);
    } catch (e) {
      debugPrint('Error deleting debt: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPayment(DebtPayment payment) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate that payment doesn't exceed current balance
      final debtIndex = _debts.indexWhere((d) => d.id == payment.debtId);
      if (debtIndex != -1) {
        final debt = _debts[debtIndex];
        if (payment.amount > debt.currentBalance) {
          throw Exception('Le montant du paiement (${payment.amount.toStringAsFixed(0)} FCFA) ne peut pas dépasser le solde restant (${debt.currentBalance.toStringAsFixed(0)} FCFA)');
        }
      }

      final id = await _databaseHelper.insertDebtPayment(payment);
      final newPayment = DebtPayment(
        id: id,
        debtId: payment.debtId,
        amount: payment.amount,
        paymentDate: payment.paymentDate,
        description: payment.description,
        isExtraPayment: payment.isExtraPayment,
        createdAt: payment.createdAt,
      );
      _payments.add(newPayment);

      // Update debt balance
      if (debtIndex != -1) {
        final debt = _debts[debtIndex];
        final updatedDebt = debt.copyWith(
          currentBalance: debt.currentBalance - payment.amount,
          updatedAt: DateTime.now(),
        );
        
        // Mark as paid off if balance is zero or negative
        if (updatedDebt.currentBalance <= 0) {
          final paidOffDebt = updatedDebt.copyWith(
            currentBalance: 0,
            status: DebtStatus.paidOff,
          );
          await _databaseHelper.updateDebt(paidOffDebt);
          _debts[debtIndex] = paidOffDebt;
        } else {
          await _databaseHelper.updateDebt(updatedDebt);
          _debts[debtIndex] = updatedDebt;
        }
      }
    } catch (e) {
      debugPrint('Error adding payment: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DebtPayment> getPaymentsForDebt(int debtId) {
    return _payments.where((payment) => payment.debtId == debtId).toList();
  }

  double getTotalPaymentsForDebt(int debtId) {
    return getPaymentsForDebt(debtId).fold(0.0, (sum, payment) => sum + payment.amount);
  }

  Map<String, double> getMonthlyPaymentHistory() {
    final Map<String, double> monthlyPayments = {};
    
    for (final payment in _payments) {
      final monthKey = '${payment.paymentDate.year}-${payment.paymentDate.month.toString().padLeft(2, '0')}';
      monthlyPayments[monthKey] = (monthlyPayments[monthKey] ?? 0.0) + payment.amount;
    }
    
    return monthlyPayments;
  }

  double calculateDebtFreeDate(double extraMonthlyPayment) {
    if (activeDebts.isEmpty) return 0;
    
    double totalBalance = totalDebt;
    double monthlyPayment = totalMinimumPayments + extraMonthlyPayment;
    int months = 0;
    const maxMonths = 360; // 30 years
    
    while (totalBalance > 0 && months < maxMonths) {
      // Calculate weighted average interest rate
      double totalInterest = 0;
      for (final debt in activeDebts) {
        if (debt.currentBalance > 0) {
          totalInterest += debt.currentBalance * (debt.interestRate / 100 / 12);
        }
      }
      
      totalBalance = totalBalance + totalInterest - monthlyPayment;
      months++;
      
      if (monthlyPayment <= totalInterest) break; // Never ending debt
    }
    
    return months.toDouble();
  }

  Map<String, dynamic> getDebtAnalytics() {
    return {
      'totalDebt': totalDebt,
      'totalPaidOff': totalPaidOff,
      'progressPercentage': progressPercentage,
      'highestInterestDebt': getHighestInterestDebt(),
      'smallestDebt': getSmallestDebt(),
      'totalMinimumPayments': totalMinimumPayments,
      'totalInterestEstimate': totalInterestEstimate,
      'monthsToDebtFree': calculateDebtFreeDate(0),
      'monthlyPaymentHistory': getMonthlyPaymentHistory(),
    };
  }
}