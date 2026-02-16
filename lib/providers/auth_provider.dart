import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final usersBox = await Hive.openBox<User>('users');
      
      // Find user with matching email and password
      User? foundUser;
      for (var i = 0; i < usersBox.length; i++) {
        final user = usersBox.getAt(i);
        if (user != null && user.email == email && user.password == password) {
          foundUser = user;
          break;
        }
      }

      if (foundUser == null) {
        throw Exception('Invalid email or password');
      }

      _currentUser = foundUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String fullName, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final usersBox = await Hive.openBox<User>('users');
      
      // Check if email already exists
      for (var i = 0; i < usersBox.length; i++) {
        final user = usersBox.getAt(i);
        if (user != null && user.email == email) {
          throw Exception('Email already exists');
        }
      }

      final newUser = User(
        id: const Uuid().v4(),
        fullName: fullName,
        email: email,
        password: password,
      );

      await usersBox.add(newUser);
      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}