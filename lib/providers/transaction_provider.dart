import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _currentUserId;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionProvider() {
    // Will be initialized when user logs in
  }

  Future<void> initialize(String userId) async {
  debugPrint('TransactionProvider - Initializing for user: $userId'); // Debug print
  _currentUserId = userId;
  await StorageService.ensureDataConsistency(userId);
  await loadTransactions();
}

  Future<void> loadTransactions() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await StorageService.getUserTransactions(_currentUserId!);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_currentUserId == null) return;
    
    try {
      _transactions.insert(0, transaction);
      await StorageService.saveUserTransactions(_currentUserId!, _transactions);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_currentUserId == null) return;
    
    try {
      _transactions.removeWhere((t) => t.id == id);
      await StorageService.saveUserTransactions(_currentUserId!, _transactions);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    if (_currentUserId == null) return;
    
    try {
      final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        await StorageService.saveUserTransactions(_currentUserId!, _transactions);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  // Enhanced Analytics Methods
  Map<int, double> getMonthlyExpenses(int year) {
    final Map<int, double> monthlyExpenses = {};
    
    for (int month = 1; month <= 12; month++) {
      final expenses = _transactions.where((t) {
        return t.type == TransactionType.expense &&
            t.date.year == year &&
            t.date.month == month;
      }).fold(0.0, (sum, t) => sum + t.amount);
      
      monthlyExpenses[month] = expenses;
    }
    
    return monthlyExpenses;
  }

  Map<int, double> getMonthlyIncome(int year) {
    final Map<int, double> monthlyIncome = {};
    
    for (int month = 1; month <= 12; month++) {
      final income = _transactions.where((t) {
        return t.type == TransactionType.income &&
            t.date.year == year &&
            t.date.month == month;
      }).fold(0.0, (sum, t) => sum + t.amount);
      
      monthlyIncome[month] = income;
    }
    
    return monthlyIncome;
  }

  Map<int, double> getWeeklyExpenses(int year, int month) {
    final Map<int, double> weeklyExpenses = {};
    
    final monthTransactions = _transactions.where((t) {
      return t.type == TransactionType.expense &&
          t.date.year == year &&
          t.date.month == month;
    }).toList();

    for (var transaction in monthTransactions) {
      final weekNumber = ((transaction.date.day - 1) / 7).floor() + 1;
      weeklyExpenses[weekNumber] = (weeklyExpenses[weekNumber] ?? 0) + transaction.amount;
    }
    
    return weeklyExpenses;
  }

  Map<String, double> getCategoryBreakdown(int year, int? month) {
    final Map<String, double> categoryExpenses = {};
    
    final filteredTransactions = _transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      if (t.date.year != year) return false;
      if (month != null && t.date.month != month) return false;
      return true;
    });

    for (var transaction in filteredTransactions) {
      categoryExpenses[transaction.category.displayName] = 
          (categoryExpenses[transaction.category.displayName] ?? 0) + transaction.amount;
    }
    
    return categoryExpenses;
  }

  double getYearlyIncome(int year) {
    return _transactions
        .where((t) => t.type == TransactionType.income && t.date.year == year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getYearlyExpense(int year) {
    return _transactions
        .where((t) => t.type == TransactionType.expense && t.date.year == year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getYearlySavings(int year) {
    return getYearlyIncome(year) - getYearlyExpense(year);
  }

  double getMonthlyAverage(int year) {
    final monthsWithData = _transactions
        .where((t) => t.date.year == year)
        .map((t) => t.date.month)
        .toSet()
        .length;
    
    return monthsWithData > 0 ? getYearlyExpense(year) / monthsWithData : 0;
  }

  double getHighestExpenseMonth(int year) {
    final monthlyExpenses = getMonthlyExpenses(year);
    return monthlyExpenses.values.isNotEmpty 
        ? monthlyExpenses.values.reduce((a, b) => a > b ? a : b) 
        : 0;
  }

  String getHighestExpenseMonthName(int year) {
    final monthlyExpenses = getMonthlyExpenses(year);
    if (monthlyExpenses.isEmpty) return 'N/A';
    
    final maxMonth = monthlyExpenses.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return DateFormat('MMMM').format(DateTime(year, maxMonth));
  }
}