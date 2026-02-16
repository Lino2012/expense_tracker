import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String fullName;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String password;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
  });
}

@HiveType(typeId: 1)
class Transaction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final DateTime date;
  
  @HiveField(4)
  final TransactionType type;
  
  @HiveField(5)
  final Category category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.index,
      'category': category.index,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values[json['type']],
      category: Category.values[json['category']],
    );
  }
}

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense
}

@HiveType(typeId: 3)
enum Category {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  shopping,
  @HiveField(3)
  entertainment,
  @HiveField(4)
  bills,
  @HiveField(5)
  health,
  @HiveField(6)
  education,
  @HiveField(7)
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
}