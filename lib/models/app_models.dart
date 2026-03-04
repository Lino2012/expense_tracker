import 'package:flutter/material.dart';

enum TransactionType { income, expense }

enum Category {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  health,
  education,
  other;

  String get displayName {
    switch (this) {
      case Category.food:
        return 'Food & Dining';
      case Category.transport:
        return 'Transport';
      case Category.shopping:
        return 'Shopping';
      case Category.entertainment:
        return 'Entertainment';
      case Category.bills:
        return 'Bills & Utilities';
      case Category.health:
        return 'Healthcare';
      case Category.education:
        return 'Education';
      case Category.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case Category.food:
        return Icons.restaurant;
      case Category.transport:
        return Icons.directions_car;
      case Category.shopping:
        return Icons.shopping_bag;
      case Category.entertainment:
        return Icons.movie;
      case Category.bills:
        return Icons.receipt;
      case Category.health:
        return Icons.favorite;
      case Category.education:
        return Icons.school;
      case Category.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case Category.food:
        return const Color(0xFFF59E0B);
      case Category.transport:
        return const Color(0xFF3B82F6);
      case Category.shopping:
        return const Color(0xFFEC4899);
      case Category.entertainment:
        return const Color(0xFF8B5CF6);
      case Category.bills:
        return const Color(0xFFEF4444);
      case Category.health:
        return const Color(0xFF10B981);
      case Category.education:
        return const Color(0xFF6366F1);
      case Category.other:
        return const Color(0xFF6B7280);
    }
  }

  static Category fromString(String value) {
    return Category.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => Category.other,
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String password;
  double monthlySalary;
  String currency;
  String themeMode;
  String? profileImagePath; // Add this field for profile picture
  final DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    this.monthlySalary = 0,
    this.currency = 'USD',
    this.themeMode = 'dark',
    this.profileImagePath, // Add this
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'password': password,
        'monthlySalary': monthlySalary,
        'currency': currency,
        'themeMode': themeMode,
        'profileImagePath': profileImagePath, // Add this
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        password: json['password'],
        monthlySalary: json['monthlySalary']?.toDouble() ?? 0,
        currency: json['currency'] ?? 'USD',
        themeMode: json['themeMode'] ?? 'dark',
        profileImagePath: json['profileImagePath'], // Add this
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toDbJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'password': password,
        'monthlySalary': monthlySalary,
        'currency': currency,
        'themeMode': themeMode,
        'profileImagePath': profileImagePath, // Add this
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory User.fromDbJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        password: json['password'],
        monthlySalary: json['monthlySalary']?.toDouble() ?? 0,
        currency: json['currency'] ?? 'USD',
        themeMode: json['themeMode'] ?? 'dark',
        profileImagePath: json['profileImagePath'], // Add this
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final Category category;
  String? note;
  bool isRecurring;
  String? recurringType;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.note,
    this.isRecurring = false,
    this.recurringType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.index,
        'category': category.index,
        'note': note,
        'isRecurring': isRecurring ? 1 : 0,
        'recurringType': recurringType,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values[json['type']],
        category: Category.values[json['category']],
        note: json['note'],
        isRecurring: json['isRecurring'] == 1,
        recurringType: json['recurringType'],
      );

  Map<String, dynamic> toDbJson(String userId) => {
        'id': id,
        'userId': userId,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.toString().split('.').last,
        'category': category.toString().split('.').last,
        'note': note,
        'isRecurring': isRecurring ? 1 : 0,
        'recurringType': recurringType,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory Transaction.fromDbJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        category: Category.fromString(json['category']),
        note: json['note'],
        isRecurring: json['isRecurring'] == 1,
        recurringType: json['recurringType'],
      );
}