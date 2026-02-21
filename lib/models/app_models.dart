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
        return const Color(0xFFF59E0B); // Amber
      case Category.transport:
        return const Color(0xFF3B82F6); // Blue
      case Category.shopping:
        return const Color(0xFFEC4899); // Pink
      case Category.entertainment:
        return const Color(0xFF8B5CF6); // Purple
      case Category.bills:
        return const Color(0xFFEF4444); // Red
      case Category.health:
        return const Color(0xFF10B981); // Green
      case Category.education:
        return const Color(0xFF6366F1); // Indigo
      case Category.other:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String password;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'password': password,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        password: json['password'],
      );
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final Category category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.index,
        'category': category.index,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values[json['type']],
        category: Category.values[json['category']],
      );
}