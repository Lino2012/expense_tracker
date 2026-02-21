import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalaryProvider extends ChangeNotifier {
  double? _monthlySalary;

  double? get monthlySalary => _monthlySalary;

  SalaryProvider() {
    loadSalary();
  }

  Future<void> loadSalary() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlySalary = prefs.getDouble('monthly_salary');
    notifyListeners();
  }

  Future<void> setMonthlySalary(double salary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_salary', salary);
    _monthlySalary = salary;
    notifyListeners();
  }
}