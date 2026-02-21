import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import 'transaction_provider.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    loadCurrentUser();
  }

  Future<bool> login(String email, String password, TransactionProvider transactionProvider) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    debugPrint('Attempting login for email: $email'); // Debug print
    
    final users = await StorageService.getAllUsers();
    debugPrint('Found ${users.length} users'); // Debug print
    
    final user = users.firstWhere(
      (u) => u.email == email && u.password == password,
      orElse: () {
        debugPrint('No user found with email: $email'); // Debug print
        throw Exception('Invalid email or password');
      },
    );
    
    debugPrint('User found: ${user.fullName}'); // Debug print
    _currentUser = user;
    await StorageService.setCurrentUser(user);
    
    // Initialize transaction provider with user ID
    debugPrint('Initializing transaction provider for user: ${user.id}'); // Debug print
    await transactionProvider.initialize(user.id);
    
    _isLoading = false;
    notifyListeners();
    debugPrint('Login successful'); // Debug print
    return true;
  } catch (e) {
    debugPrint('Login error: $e'); // Debug print
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
    debugPrint('Attempting signup for email: $email'); // Debug print
    
    final users = await StorageService.getAllUsers();
    debugPrint('Existing users count: ${users.length}'); // Debug print
    
    if (users.any((u) => u.email == email)) {
      debugPrint('Email already exists: $email'); // Debug print
      throw Exception('Email already exists');
    }
    
    final newUser = User(
      id: const Uuid().v4(),
      fullName: fullName,
      email: email,
      password: password,
    );
    
    users.add(newUser);
    await StorageService.saveUsers(users);
    debugPrint('User saved. Total users now: ${users.length}'); // Debug print
    
    await StorageService.setCurrentUser(newUser);
    debugPrint('Current user set'); // Debug print
    
    _currentUser = newUser;
    
    // Initialize transaction provider with user ID
    debugPrint('Initializing transaction provider for new user: ${newUser.id}'); // Debug print
    await transactionProvider.initialize(newUser.id);
    
    _isLoading = false;
    notifyListeners();
    debugPrint('Signup successful'); // Debug print
    return true;
  } catch (e) {
    debugPrint('Signup error: $e'); // Debug print
    _error = e.toString().replaceAll('Exception: ', '');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  Future<void> logout(TransactionProvider transactionProvider) async {
    if (_currentUser != null) {
      await StorageService.clearUserData(_currentUser!.id);
    }
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _currentUser = await StorageService.getCurrentUser();
    notifyListeners();
  }
}