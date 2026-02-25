import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _currentUserId;
  
  String? get currentUserId => _currentUserId;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionProvider() {
    // Will be initialized when user logs in
  }

  // Single initialize method
Future<void> initialize(String userId) async {
  debugPrint('📊 TransactionProvider - Initializing for user: $userId');
  _currentUserId = userId;
  debugPrint('📊 TransactionProvider - _currentUserId set to: $_currentUserId');
  
  // Ensure data consistency first
  await StorageService.ensureDataConsistency(userId);
  
  // Migrate data if needed
  await StorageService.migrateDataIfNeeded(userId);
  
  // Load transactions
  await loadTransactions();
  
  // Verify data integrity
  await verifyAndRepairData();
  
  debugPrint('📊 TransactionProvider - Initialization complete. Current user ID: $_currentUserId');
}

  // Single loadTransactions method
  Future<void> loadTransactions() async {
    if (_currentUserId == null) {
      debugPrint('Cannot load transactions: No user ID');
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Loading transactions for user: $_currentUserId');
      _transactions = await StorageService.getUserTransactions(_currentUserId!);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('Loaded ${_transactions.length} transactions');
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (_currentUserId == null) {
      debugPrint('Error: No current user ID');
      return;
    }
    
    try {
      debugPrint('Adding transaction for user: $_currentUserId');
      debugPrint('Current transactions count before: ${_transactions.length}');
      
      _transactions.insert(0, transaction);
      debugPrint('Transactions count after insert: ${_transactions.length}');
      
      await StorageService.saveUserTransactions(_currentUserId!, _transactions);
      debugPrint('Transactions saved to storage');
      
      notifyListeners();
      debugPrint('UI notified of changes');
      
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

  // Add this method to check data integrity on startup
  Future<void> verifyAndRepairData() async {
    if (_currentUserId == null) return;
    
    final isValid = await StorageService.verifyDataIntegrity(_currentUserId!);
    if (!isValid) {
      debugPrint('TransactionProvider - Data integrity issue detected, attempting repair');
      await loadTransactions(); // Reload from storage
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
  // Add this method to manually set user ID if needed
void setUserId(String userId) {
  debugPrint('📊 TransactionProvider - Manually setting user ID to: $userId');
  _currentUserId = userId;
  loadTransactions();
}
}