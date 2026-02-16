import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    final transactionsBox = await Hive.openBox<Transaction>('transactions');
    _transactions = transactionsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final transactionsBox = await Hive.openBox<Transaction>('transactions');
    await transactionsBox.add(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    final transactionsBox = await Hive.openBox<Transaction>('transactions');
    
    int? indexToDelete;
    for (var i = 0; i < transactionsBox.length; i++) {
      final transaction = transactionsBox.getAt(i);
      if (transaction != null && transaction.id == id) {
        indexToDelete = i;
        break;
      }
    }
    
    if (indexToDelete != null) {
      await transactionsBox.deleteAt(indexToDelete);
      await loadTransactions();
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
}