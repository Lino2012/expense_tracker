import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_models.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _transactionsPrefix = 'transactions_';
  static const String _salaryPrefix = 'salary_';
  static const String _lastBackupKey = 'last_backup';
  static const String _backupDataKey = 'backup_data';

  // User Management
  static Future<List<User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersString = prefs.getString(_usersKey);
      debugPrint('StorageService - getAllUsers: usersString = $usersString'); // Debug print
      
      if (usersString != null && usersString.isNotEmpty) {
        final List<dynamic> usersJson = json.decode(usersString);
        debugPrint('StorageService - Found ${usersJson.length} users'); // Debug print
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      debugPrint('StorageService - No users found'); // Debug print
      return [];
    } catch (e) {
      debugPrint('StorageService - Error getting users: $e'); // Debug print
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = users.map((u) => u.toJson()).toList();
      final usersString = json.encode(usersJson);
      debugPrint('StorageService - Saving users: $usersString'); // Debug print
      await prefs.setString(_usersKey, usersString);
      debugPrint('StorageService - Users saved successfully'); // Debug print
    } catch (e) {
      debugPrint('StorageService - Error saving users: $e'); // Debug print
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userString = prefs.getString(_currentUserKey);
      debugPrint('StorageService - getCurrentUser: $userString'); // Debug print
      
      if (userString != null && userString.isNotEmpty) {
        return User.fromJson(json.decode(userString));
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error getting current user: $e'); // Debug print
      return null;
    }
  }

  static Future<void> setCurrentUser(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        final userString = json.encode(user.toJson());
        debugPrint('StorageService - Setting current user: $userString'); // Debug print
        await prefs.setString(_currentUserKey, userString);
      } else {
        debugPrint('StorageService - Removing current user'); // Debug print
        await prefs.remove(_currentUserKey);
      }
    } catch (e) {
      debugPrint('StorageService - Error setting current user: $e'); // Debug print
    }
  }

  // Rest of the methods remain the same...
  
  static Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? transactionsString = prefs.getString('$_transactionsPrefix$userId');
      debugPrint('StorageService - getUserTransactions for $userId: $transactionsString'); // Debug print
      
      if (transactionsString != null && transactionsString.isNotEmpty) {
        final List<dynamic> transactionsJson = json.decode(transactionsString);
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('StorageService - Error getting transactions: $e'); // Debug print
      return [];
    }
  }

  static Future<void> saveUserTransactions(String userId, List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      final transactionsString = json.encode(transactionsJson);
      debugPrint('StorageService - Saving transactions for $userId: $transactionsString'); // Debug print
      await prefs.setString('$_transactionsPrefix$userId', transactionsString);
      
      // Create backup after saving
      await createBackup(userId);
    } catch (e) {
      debugPrint('StorageService - Error saving transactions: $e'); // Debug print
    }
  }

  static Future<double?> getUserSalary(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salary = prefs.getDouble('$_salaryPrefix$userId');
      debugPrint('StorageService - getUserSalary for $userId: $salary'); // Debug print
      return salary;
    } catch (e) {
      debugPrint('StorageService - Error getting salary: $e'); // Debug print
      return null;
    }
  }

  static Future<void> saveUserSalary(String userId, double salary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint('StorageService - Saving salary for $userId: $salary'); // Debug print
      await prefs.setDouble('$_salaryPrefix$userId', salary);
      
      // Create backup after saving
      await createBackup(userId);
    } catch (e) {
      debugPrint('StorageService - Error saving salary: $e'); // Debug print
    }
  }

  // Backup System (Retains data for months)
  static Future<void> createBackup(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactions = await getUserTransactions(userId);
      final salary = await getUserSalary(userId);
      
      final backupData = {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'salary': salary,
      };
      
      // Get existing backups
      final String? backupsString = prefs.getString(_backupDataKey);
      Map<String, dynamic> backups = {};
      
      if (backupsString != null && backupsString.isNotEmpty) {
        backups = json.decode(backupsString);
      }
      
      // Store backup with timestamp
      backups[userId] = backupData;
      await prefs.setString(_backupDataKey, json.encode(backups));
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
      debugPrint('StorageService - Backup created for user $userId'); // Debug print
    } catch (e) {
      debugPrint('StorageService - Error creating backup: $e'); // Debug print
    }
  }

  // Restore data from backup (useful after long inactivity)
  static Future<bool> restoreFromBackup(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? backupsString = prefs.getString(_backupDataKey);
      
      if (backupsString != null && backupsString.isNotEmpty) {
        final Map<String, dynamic> backups = json.decode(backupsString);
        
        if (backups.containsKey(userId)) {
          final backup = backups[userId];
          
          // Restore transactions
          final transactions = (backup['transactions'] as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          await saveUserTransactions(userId, transactions);
          
          // Restore salary
          if (backup['salary'] != null) {
            await saveUserSalary(userId, backup['salary'].toDouble());
          }
          
          debugPrint('StorageService - Data restored from backup for user: $userId'); // Debug print
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('StorageService - Error restoring backup: $e'); // Debug print
      return false;
    }
  }

  // Check and restore if data is missing (called on app startup)
  static Future<void> ensureDataConsistency(String userId) async {
    debugPrint('StorageService - Ensuring data consistency for $userId'); // Debug print
    final transactions = await getUserTransactions(userId);
    final salary = await getUserSalary(userId);
    
    // If user has no data but backup exists, restore
    if (transactions.isEmpty && salary == null) {
      debugPrint('StorageService - No data found, attempting restore from backup'); // Debug print
      await restoreFromBackup(userId);
    }
  }

  // Clear user data (for logout)
  static Future<void> clearUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_transactionsPrefix$userId');
      await prefs.remove('$_salaryPrefix$userId');
      await prefs.remove(_currentUserKey);
      debugPrint('StorageService - Cleared data for user $userId'); // Debug print
    } catch (e) {
      debugPrint('StorageService - Error clearing user data: $e'); // Debug print
    }
  }

  // Get last backup time
  static Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? timeString = prefs.getString(_lastBackupKey);
      if (timeString != null && timeString.isNotEmpty) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error getting last backup time: $e'); // Debug print
      return null;
    }
  }
}