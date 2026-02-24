import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'dart:async';
import '../models/app_models.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _transactionsPrefix = 'transactions_';
  static const String _salaryPrefix = 'salary_';
  
  // Backup keys
  static const String _backupPrefix = 'backup_';
  static const String _backupMetadataKey = 'backup_metadata';
  static const String _dataVersionKey = 'data_version';
  static const String _userSettingsPrefix = 'settings_';
  
  // Current data version - increment this when data structure changes
  static const int _currentDataVersion = 1;
  
  // Auto-backup interval (in days)
  static const int _backupIntervalDays = 7;

  // User Management
  static Future<List<User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersString = prefs.getString(_usersKey);
      
      if (usersString != null && usersString.isNotEmpty) {
        final List<dynamic> usersJson = json.decode(usersString);
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('StorageService - Error getting users: $e');
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = users.map((u) => u.toJson()).toList();
      final usersString = json.encode(usersJson);
      await prefs.setString(_usersKey, usersString);
    } catch (e) {
      debugPrint('StorageService - Error saving users: $e');
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userString = prefs.getString(_currentUserKey);
      
      if (userString != null && userString.isNotEmpty) {
        return User.fromJson(json.decode(userString));
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error getting current user: $e');
      return null;
    }
  }

  static Future<void> setCurrentUser(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        final userString = json.encode(user.toJson());
        await prefs.setString(_currentUserKey, userString);
      } else {
        await prefs.remove(_currentUserKey);
      }
    } catch (e) {
      debugPrint('StorageService - Error setting current user: $e');
    }
  }

  // Transaction Management with Auto-backup
  static Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? transactionsString = prefs.getString('$_transactionsPrefix$userId');
      
      if (transactionsString != null && transactionsString.isNotEmpty) {
        final List<dynamic> transactionsJson = json.decode(transactionsString);
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      }
      
      // Try to restore from backup if no data found
      return await _restoreTransactionsFromBackup(userId) ?? [];
    } catch (e) {
      debugPrint('StorageService - Error getting transactions: $e');
      return [];
    }
  }

  static Future<void> saveUserTransactions(String userId, List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      final transactionsString = json.encode(transactionsJson);
      await prefs.setString('$_transactionsPrefix$userId', transactionsString);
      
      // Create backup after saving
      await _createBackup(userId, 'transactions', transactionsString);
      
      // Check if we need to create a full backup
      await _checkAndCreateFullBackup(userId);
    } catch (e) {
      debugPrint('StorageService - Error saving transactions: $e');
    }
  }

  // Salary Management with Auto-backup
  static Future<double?> getUserSalary(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salary = prefs.getDouble('$_salaryPrefix$userId');
      
      if (salary != null) {
        return salary;
      }
      
      // Try to restore from backup if no data found
      return await _restoreSalaryFromBackup(userId);
    } catch (e) {
      debugPrint('StorageService - Error getting salary: $e');
      return null;
    }
  }

  static Future<void> saveUserSalary(String userId, double salary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('$_salaryPrefix$userId', salary);
      
      // Create backup after saving
      await _createBackup(userId, 'salary', salary.toString());
      
      // Check if we need to create a full backup
      await _checkAndCreateFullBackup(userId);
    } catch (e) {
      debugPrint('StorageService - Error saving salary: $e');
    }
  }

  // User Settings Management
  static Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsString = prefs.getString('$_userSettingsPrefix$userId');
      
      if (settingsString != null && settingsString.isNotEmpty) {
        return json.decode(settingsString);
      }
      return {};
    } catch (e) {
      debugPrint('StorageService - Error getting user settings: $e');
      return {};
    }
  }

  static Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = json.encode(settings);
      await prefs.setString('$_userSettingsPrefix$userId', settingsString);
    } catch (e) {
      debugPrint('StorageService - Error saving user settings: $e');
    }
  }

  // Backup System - Long-term storage
  static Future<void> _createBackup(String userId, String dataType, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final backupKey = '$_backupPrefix${userId}_${dataType}_$timestamp';
      
      final backupData = {
        'userId': userId,
        'dataType': dataType,
        'data': data,
        'timestamp': timestamp,
        'version': _currentDataVersion,
      };
      
      await prefs.setString(backupKey, json.encode(backupData));
      
      // Clean up old backups (keep last 10 backups per data type)
      await _cleanupOldBackups(userId, dataType);
      
      debugPrint('StorageService - Backup created for $userId/$dataType');
    } catch (e) {
      debugPrint('StorageService - Error creating backup: $e');
    }
  }

  static Future<void> _createFullBackup(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all user data
      final transactions = await getUserTransactions(userId);
      final salary = await getUserSalary(userId);
      final settings = await getUserSettings(userId);
      
      final fullBackup = {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'version': _currentDataVersion,
        'data': {
          'transactions': transactions.map((t) => t.toJson()).toList(),
          'salary': salary,
          'settings': settings,
        },
      };
      
      // Store full backup with monthly retention
      final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
      await prefs.setString('$_backupPrefix${userId}_full_$monthKey', json.encode(fullBackup));
      
      // Update backup metadata
      await _updateBackupMetadata(userId, 'full_backup', monthKey);
      
      debugPrint('StorageService - Full backup created for user $userId');
    } catch (e) {
      debugPrint('StorageService - Error creating full backup: $e');
    }
  }

  static Future<void> _checkAndCreateFullBackup(String userId) async {
    try {
      final lastBackupTime = await _getLastFullBackupTime(userId);
      
      if (lastBackupTime == null) {
        // No backup exists, create one
        await _createFullBackup(userId);
      } else {
        final daysSinceLastBackup = DateTime.now().difference(lastBackupTime).inDays;
        if (daysSinceLastBackup >= _backupIntervalDays) {
          // Time to create a new full backup
          await _createFullBackup(userId);
        }
      }
    } catch (e) {
      debugPrint('StorageService - Error checking backup: $e');
    }
  }

  static Future<DateTime?> _getLastFullBackupTime(String userId) async {
    try {
      final metadata = await _getBackupMetadata(userId);
      
      if (metadata != null && metadata.containsKey('last_full_backup')) {
        return DateTime.parse(metadata['last_full_backup']);
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error getting last backup time: $e');
      return null;
    }
  }

  static Future<void> _updateBackupMetadata(String userId, String backupType, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? metadataString = prefs.getString(_backupMetadataKey);
      Map<String, dynamic> metadata = {};
      
      if (metadataString != null && metadataString.isNotEmpty) {
        metadata = json.decode(metadataString);
      }
      
      if (!metadata.containsKey(userId)) {
        metadata[userId] = {};
      }
      
      metadata[userId][backupType] = value;
      metadata[userId]['last_updated'] = DateTime.now().toIso8601String();
      
      await prefs.setString(_backupMetadataKey, json.encode(metadata));
    } catch (e) {
      debugPrint('StorageService - Error updating backup metadata: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getBackupMetadata(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? metadataString = prefs.getString(_backupMetadataKey);
      
      if (metadataString != null && metadataString.isNotEmpty) {
        final metadata = json.decode(metadataString);
        return metadata[userId];
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error getting backup metadata: $e');
      return null;
    }
  }

  // Public method to get backup metadata
  static Future<Map<String, dynamic>?> getBackupMetadata(String userId) async {
    return await _getBackupMetadata(userId);
  }

  // Data consistency methods
  static Future<void> ensureDataConsistency(String userId) async {
    try {
      debugPrint('StorageService - Ensuring data consistency for $userId');
      final transactions = await getUserTransactions(userId);
      final salary = await getUserSalary(userId);
      
      // If user has no data but backup exists, restore
      if (transactions.isEmpty && salary == null) {
        debugPrint('StorageService - No data found, attempting restore from backup');
        await restoreFromBackup(userId);
      }
    } catch (e) {
      debugPrint('StorageService - Error ensuring data consistency: $e');
    }
  }

  static Future<void> restoreFromBackup(String userId) async {
    try {
      final transactions = await _restoreTransactionsFromBackup(userId);
      final salary = await _restoreSalaryFromBackup(userId);
      
      if (transactions != null) {
        await saveUserTransactions(userId, transactions);
      }
      if (salary != null) {
        await saveUserSalary(userId, salary);
      }
    } catch (e) {
      debugPrint('StorageService - Error restoring from backup: $e');
    }
  }

  static Future<List<Transaction>?> _restoreTransactionsFromBackup(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Find the most recent transaction backup for this user
      final backupKeys = allKeys.where((key) => 
          key.startsWith('$_backupPrefix${userId}_transactions_')).toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending by timestamp
      
      if (backupKeys.isNotEmpty) {
        final latestBackupKey = backupKeys.first;
        final String? backupString = prefs.getString(latestBackupKey);
        
        if (backupString != null && backupString.isNotEmpty) {
          final backupData = json.decode(backupString);
          final transactionsJson = json.decode(backupData['data']);
          final transactions = (transactionsJson as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
          
          debugPrint('StorageService - Restored ${transactions.length} transactions from backup');
          return transactions;
        }
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error restoring transactions: $e');
      return null;
    }
  }

  static Future<double?> _restoreSalaryFromBackup(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Find the most recent salary backup for this user
      final backupKeys = allKeys.where((key) => 
          key.startsWith('$_backupPrefix${userId}_salary_')).toList()
        ..sort((a, b) => b.compareTo(a));
      
      if (backupKeys.isNotEmpty) {
        final latestBackupKey = backupKeys.first;
        final String? backupString = prefs.getString(latestBackupKey);
        
        if (backupString != null && backupString.isNotEmpty) {
          final backupData = json.decode(backupString);
          return double.parse(backupData['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('StorageService - Error restoring salary: $e');
      return null;
    }
  }

  static Future<void> _cleanupOldBackups(String userId, String dataType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Get all backup keys for this user and data type
      final backupKeys = allKeys.where((key) => 
          key.startsWith('$_backupPrefix${userId}_${dataType}_')).toList()
        ..sort((a, b) => b.compareTo(a)); // Sort newest first
      
      // Keep only the last 10 backups
      if (backupKeys.length > 10) {
        for (int i = 10; i < backupKeys.length; i++) {
          await prefs.remove(backupKeys[i]);
        }
      }
    } catch (e) {
      debugPrint('StorageService - Error cleaning up backups: $e');
    }
  }

  // Data version migration
  static Future<void> migrateDataIfNeeded(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt('$_dataVersionKey$userId') ?? 0;
      
      if (version < _currentDataVersion) {
        debugPrint('StorageService - Migrating data from version $version to $_currentDataVersion');
        
        // Perform data migration based on version
        if (version < 1) {
          await _migrateToV1(userId);
        }
        
        // Update version
        await prefs.setInt('$_dataVersionKey$userId', _currentDataVersion);
      }
    } catch (e) {
      debugPrint('StorageService - Error migrating data: $e');
    }
  }

  static Future<void> _migrateToV1(String userId) async {
    // Example migration logic - customize based on your needs
    debugPrint('StorageService - Migrating to version 1');
    
    // Create initial backup
    await _createFullBackup(userId);
  }

  // Clear user data (for logout)
  static Future<void> clearUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Don't delete backups, only active data
      await prefs.remove('$_transactionsPrefix$userId');
      await prefs.remove('$_salaryPrefix$userId');
      await prefs.remove('$_userSettingsPrefix$userId');
      await prefs.remove('$_dataVersionKey$userId');
      await prefs.remove(_currentUserKey);
      
      debugPrint('StorageService - Cleared active data for user $userId');
    } catch (e) {
      debugPrint('StorageService - Error clearing user data: $e');
    }
  }

  // Completely delete user data (for account deletion)
  static Future<void> deleteUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Remove all keys related to this user
      for (var key in allKeys) {
        if (key.contains(userId)) {
          await prefs.remove(key);
        }
      }
      
      // Remove from users list
      final users = await getAllUsers();
      users.removeWhere((u) => u.id == userId);
      await saveUsers(users);
      
      debugPrint('StorageService - Deleted all data for user $userId');
    } catch (e) {
      debugPrint('StorageService - Error deleting user data: $e');
    }
  }

  // Health check and data integrity verification
  static Future<bool> verifyDataIntegrity(String userId) async {
    try {
      final transactions = await getUserTransactions(userId);
      final salary = await getUserSalary(userId);
      
      // Verify data consistency
      bool valid = true;
      
      // Check for negative amounts in transactions
      if (transactions.any((t) => t.amount < 0)) {
        debugPrint('StorageService - Found negative amounts');
        valid = false;
      }
      
      // Check for future dates in transactions
      if (transactions.any((t) => t.date.isAfter(DateTime.now()))) {
        debugPrint('StorageService - Found future dates');
        valid = false;
      }
      
      // Check if salary is valid (if it exists)
      if (salary != null && salary < 0) {
        debugPrint('StorageService - Found negative salary');
        valid = false;
      }
      
      // Check for duplicate transaction IDs
      final ids = transactions.map((t) => t.id).toSet();
      if (ids.length != transactions.length) {
        debugPrint('StorageService - Found duplicate transaction IDs');
        valid = false;
      }
      
      // Check for reasonable amounts (optional)
      if (transactions.any((t) => t.amount > 1000000000)) { // Over 1 billion
        debugPrint('StorageService - Found unusually large amount');
        // Don't mark as invalid, just warn
      }
      
      return valid;
    } catch (e) {
      debugPrint('StorageService - Error verifying data integrity: $e');
      return false;
    }
  }

  // Export user data (for backup/restore feature)
  static Future<Map<String, dynamic>?> exportUserData(String userId) async {
    try {
      final transactions = await getUserTransactions(userId);
      final salary = await getUserSalary(userId);
      final settings = await getUserSettings(userId);
      
      return {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'version': _currentDataVersion,
        'data': {
          'transactions': transactions.map((t) => t.toJson()).toList(),
          'salary': salary,
          'settings': settings,
        },
      };
    } catch (e) {
      debugPrint('StorageService - Error exporting user data: $e');
      return null;
    }
  }

  // Import user data
  static Future<bool> importUserData(String userId, Map<String, dynamic> exportData) async {
    try {
      if (exportData['version'] != _currentDataVersion) {
        debugPrint('StorageService - Data version mismatch');
        return false;
      }
      
      final data = exportData['data'];
      
      // Restore transactions
      if (data['transactions'] != null) {
        final transactions = (data['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
        await saveUserTransactions(userId, transactions);
      }
      
      // Restore salary
      if (data['salary'] != null) {
        await saveUserSalary(userId, data['salary'].toDouble());
      }
      
      // Restore settings
      if (data['settings'] != null) {
        await saveUserSettings(userId, data['settings']);
      }
      
      debugPrint('StorageService - Successfully imported data for user $userId');
      return true;
    } catch (e) {
      debugPrint('StorageService - Error importing user data: $e');
      return false;
    }
  }
}