import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart' as models;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'expensio.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        monthlySalary REAL DEFAULT 0,
        currency TEXT DEFAULT 'USD',
        profileImagePath TEXT,
        themeMode TEXT DEFAULT 'dark',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        isRecurring INTEGER DEFAULT 0,
        recurringType TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create categories table (custom categories)
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        isDefault INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE budgets(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
      await db.execute('ALTER TABLE transactions ADD COLUMN note TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN isRecurring INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE transactions ADD COLUMN recurringType TEXT');
    }
    if (oldVersion < 3) {
    // Add profileImagePath column for version 3
    await db.execute('ALTER TABLE users ADD COLUMN profileImagePath TEXT');
  }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultCategories = [
      ['food', 'Food & Dining', 'restaurant', '0xFFF59E0B', 1],
      ['transport', 'Transport', 'directions_car', '0xFF3B82F6', 1],
      ['shopping', 'Shopping', 'shopping_bag', '0xFFEC4899', 1],
      ['entertainment', 'Entertainment', 'movie', '0xFF8B5CF6', 1],
      ['bills', 'Bills & Utilities', 'receipt', '0xFFEF4444', 1],
      ['health', 'Healthcare', 'favorite', '0xFF10B981', 1],
      ['education', 'Education', 'school', '0xFF6366F1', 1],
      ['other', 'Other', 'category', '0xFF6B7280', 1],
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', {
        'id': cat[0],
        'userId': 'system',
        'name': cat[1],
        'icon': cat[2],
        'color': cat[3],
        'isDefault': cat[4],
        'createdAt': now,
      });
    }
  }

  // User operations
  Future<models.User> createUser(models.User user) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('users', {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'password': user.password,
      'monthlySalary': user.monthlySalary,
      'currency': user.currency,
      'themeMode': user.themeMode,
      'createdAt': now,
      'updatedAt': now,
    });
    
    return user;
  }

  Future<models.User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return models.User.fromDbJson(maps.first);
    }
    return null;
  }

  Future<models.User?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return models.User.fromDbJson(maps.first);
    }
    return null;
  }

  Future<models.User> updateUser(models.User user) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'users',
      {
        'fullName': user.fullName,
        'email': user.email,
        'monthlySalary': user.monthlySalary,
        'currency': user.currency,
        'themeMode': user.themeMode,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    
    return user;
  }

  Future<void> updateUserSettings(String userId, String currency, String themeMode) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'users',
      {
        'currency': currency,
        'themeMode': themeMode,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateMonthlySalary(String userId, double salary) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'users',
      {
        'monthlySalary': salary,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Transaction operations
  Future<models.Transaction> createTransaction(models.Transaction transaction, String userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('transactions', {
      'id': transaction.id,
      'userId': userId,
      'title': transaction.title,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type.toString().split('.').last,
      'category': transaction.category.toString().split('.').last,
      'note': transaction.note,
      'isRecurring': transaction.isRecurring ? 1 : 0,
      'recurringType': transaction.recurringType,
      'createdAt': now,
      'updatedAt': now,
    });
    
    return transaction;
  }

  Future<List<models.Transaction>> getTransactionsByUser(String userId, {int? year, int? month}) async {
    final db = await database;
    
    String where = 'userId = ?';
    List<dynamic> whereArgs = [userId];
    
    if (year != null && month != null) {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      where += ' AND date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    } else if (year != null) {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);
      where += ' AND date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromDbJson(maps[i]);
    });
  }

  Future<models.Transaction> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'transactions',
      {
        'title': transaction.title,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type.toString().split('.').last,
        'category': transaction.category.toString().split('.').last,
        'note': transaction.note,
        'isRecurring': transaction.isRecurring ? 1 : 0,
        'recurringType': transaction.recurringType,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    
    return transaction;
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getUserBalance(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> incomeResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE userId = ? AND type = 'income'
    ''', [userId]);
    
    final List<Map<String, dynamic>> expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE userId = ? AND type = 'expense'
    ''', [userId]);
    
    double income = incomeResult.first['total'] != null ? incomeResult.first['total'] as double : 0.0;
    double expense = expenseResult.first['total'] != null ? expenseResult.first['total'] as double : 0.0;
    
    return income - expense;
  }

  Future<Map<String, double>> getCategoryBreakdown(String userId, int year, int? month) async {
    final db = await database;
    
    String query = '''
      SELECT category, SUM(amount) as total FROM transactions 
      WHERE userId = ? AND type = 'expense' 
    ''';
    
    List<String> args = [userId];
    
    if (month != null) {
      query += ' AND strftime("%Y", date) = ? AND strftime("%m", date) = ?';
      args.add(year.toString());
      args.add(month.toString().padLeft(2, '0'));
    } else {
      query += ' AND strftime("%Y", date) = ?';
      args.add(year.toString());
    }
    
    query += ' GROUP BY category';
    
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    
    Map<String, double> breakdown = {};
    for (var row in results) {
      final categoryName = models.Category.values.firstWhere(
        (c) => c.toString().split('.').last == row['category'],
        orElse: () => models.Category.other,
      ).displayName;
      breakdown[categoryName] = row['total'] as double;
    }
    
    return breakdown;
  }

  // Budget operations
  Future<void> setBudget(String userId, String category, double amount, int month, int year) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = const Uuid().v4();
    
    await db.insert('budgets', {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<double?> getBudget(String userId, String category, int month, int year) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'userId = ? AND category = ? AND month = ? AND year = ?',
      whereArgs: [userId, category, month, year],
    );

    if (maps.isNotEmpty) {
      return maps.first['amount'] as double;
    }
    return null;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
  
}