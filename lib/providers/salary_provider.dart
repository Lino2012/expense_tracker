import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SalaryProvider extends ChangeNotifier {
  double? _monthlySalary;

  double? get monthlySalary => _monthlySalary;

  SalaryProvider() {
    loadSalary();
  }

  Future<void> loadSalary() async {
    final settingsBox = await Hive.openBox('settings');
    _monthlySalary = settingsBox.get('monthlySalary');
    notifyListeners();
  }

  Future<void> setMonthlySalary(double salary) async {
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put('monthlySalary', salary);
    _monthlySalary = salary;
    notifyListeners();
  }
}