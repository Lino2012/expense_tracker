import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class StorageService {
  static const String _transactionsKey = 'transactions';
  static const String _salaryKey = 'monthly_salary';
  static const String _userKey = 'user_session';

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, transactionsJson);
  }

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    return transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveMonthlySalary(double salary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_salaryKey, salary);
  }

  static Future<double?> loadMonthlySalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_salaryKey);
  }

  static Future<void> saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userId);
  }

  static Future<String?> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}