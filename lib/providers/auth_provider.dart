import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart' as models;
import '../services/database_service.dart';
import 'transaction_provider.dart';

class AuthProvider extends ChangeNotifier {
  models.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  final DatabaseService _db = DatabaseService();

  AuthProvider() {
    loadCurrentUser();
  }

  Future<bool> login(String email, String password, TransactionProvider transactionProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 AuthProvider - Attempting login for email: $email');
      
      final user = await _db.getUserByEmail(email);
      
      if (user == null) {
        throw Exception('User not found');
      }
      
      if (user.password != password) {
        throw Exception('Invalid password');
      }
      
      debugPrint('🔐 AuthProvider - User found: ${user.fullName}, ID: ${user.id}');
      _currentUser = user;
      
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(user.toJson()));
      
      // Initialize transaction provider with user ID
      debugPrint('🔐 AuthProvider - Initializing transaction provider for user: ${user.id}');
      await transactionProvider.initialize(user.id);
      
      _isLoading = false;
      notifyListeners();
      debugPrint('🔐 AuthProvider - Login successful');
      return true;
    } catch (e) {
      debugPrint('🔐 AuthProvider - Login error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String fullName, String email, String password, TransactionProvider transactionProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 AuthProvider - Attempting signup for email: $email');
      
      // Check if user already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Email already exists');
      }
      
      final now = DateTime.now();
      final newUser = models.User(
        id: const Uuid().v4(),
        fullName: fullName,
        email: email,
        password: password,
        monthlySalary: 0,
        currency: 'USD',
        themeMode: 'dark',
        createdAt: now,
        updatedAt: now,
      );
      
      await _db.createUser(newUser);
      debugPrint('🔐 AuthProvider - User created: ${newUser.id}');
      
      _currentUser = newUser;
      
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(newUser.toJson()));
      
      // Initialize transaction provider with user ID
      debugPrint('🔐 AuthProvider - Initializing transaction provider for user: ${newUser.id}');
      await transactionProvider.initialize(newUser.id);
      
      _isLoading = false;
      notifyListeners();
      debugPrint('🔐 AuthProvider - Signup successful');
      return true;
    } catch (e) {
      debugPrint('🔐 AuthProvider - Signup error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(TransactionProvider transactionProvider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _currentUser = null;
    await transactionProvider.clear();
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userString = prefs.getString('current_user');
      if (userString != null) {
        _currentUser = models.User.fromJson(json.decode(userString));
        debugPrint('🔐 AuthProvider - Loaded current user: ${_currentUser?.fullName}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🔐 AuthProvider - Error loading current user: $e');
    }
  }

  Future<void> updateUserProfile(String fullName) async {
    if (_currentUser == null) return;
    
    try {
      final updatedUser = models.User(
        id: _currentUser!.id,
        fullName: fullName,
        email: _currentUser!.email,
        password: _currentUser!.password,
        monthlySalary: _currentUser!.monthlySalary,
        currency: _currentUser!.currency,
        themeMode: _currentUser!.themeMode,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _db.updateUser(updatedUser);
      
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(updatedUser.toJson()));
      
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('🔐 AuthProvider - Error updating profile: $e');
    }
  }

  Future<void> updateMonthlySalary(double salary) async {
    if (_currentUser == null) return;
    
    try {
      await _db.updateMonthlySalary(_currentUser!.id, salary);
      
      final updatedUser = models.User(
        id: _currentUser!.id,
        fullName: _currentUser!.fullName,
        email: _currentUser!.email,
        password: _currentUser!.password,
        monthlySalary: salary,
        currency: _currentUser!.currency,
        themeMode: _currentUser!.themeMode,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(updatedUser.toJson()));
      
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('🔐 AuthProvider - Error updating salary: $e');
    }
  }
  Future<void> updateProfileImage(String? imagePath) async {
  if (_currentUser == null) return;
  
  try {
    final updatedUser = models.User(
      id: _currentUser!.id,
      fullName: _currentUser!.fullName,
      email: _currentUser!.email,
      password: _currentUser!.password,
      monthlySalary: _currentUser!.monthlySalary,
      currency: _currentUser!.currency,
      themeMode: _currentUser!.themeMode,
      profileImagePath: imagePath,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await _db.updateUser(updatedUser);
    
    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', json.encode(updatedUser.toJson()));
    
    _currentUser = updatedUser;
    notifyListeners();
  } catch (e) {
    debugPrint('🔐 AuthProvider - Error updating profile image: $e');
  }
}
}