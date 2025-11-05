import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../data/local/auth_database.dart';
import '../data/providers/bills_provider.dart';
import '../data/providers/bill_repository_provider.dart';

class AuthService {
  static const String _keyUserId = 'userId';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthDatabase _db = AuthDatabase();
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialize and check for stored credentials
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);

    if (userId != null) {
      _currentUser = await _db.getUserById(userId);
      if (_currentUser != null) {
        BillRepositoryProvider().setCurrentUser(_currentUser!.id);
      }
    }
  }

  // Login with email and password
  Future<void> loginWithEmail(String email, String password) async {
    try {
      print('Attempting login for email: $email');
      
      final user = await _db.loginUser(
        email: email,
        password: password,
      );
      
      print('Login successful for user: ${user.id}');
      
      // Store user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, user.id);
      print('User session stored in preferences');
      
      _currentUser = user;
      BillRepositoryProvider().setCurrentUser(user.id);
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      throw 'Login failed: ${e.toString()}';
    }
  }

  // Sign up with email and password
  Future<void> signupWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('Starting signup process for email: $email');
      
      // Check if email already exists
      print('Checking if email exists...');
      if (await _db.emailExists(email)) {
        throw 'Email already registered';
      }
      
      print('Email is available, creating new user...');
      final user = await _db.registerUser(
        name: name,
        email: email,
        password: password,
      );
      
      print('User registered successfully with ID: ${user.id}');
      
      // Store user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, user.id);
      print('User session stored in preferences');
      
      _currentUser = user;
      BillRepositoryProvider().setCurrentUser(user.id);
    } catch (e, stackTrace) {
      print('Signup error: $e');
      print('Stack trace: $stackTrace');
      throw 'Signup failed: ${e.toString()}';
    }
  }

  // Update user profile
  Future<void> updateProfile({String? name, String? password}) async {
    if (_currentUser == null) throw 'Not logged in';

    try {
      await _db.updateUserProfile(
        userId: _currentUser!.id,
        name: name,
        password: password,
      );

      if (name != null) {
        _currentUser = User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          name: name,
        );
      }
    } catch (e) {
      throw 'Profile update failed: ${e.toString()}';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      _currentUser = null;

      // Clear user's bills from memory
      BillsProvider().clear();
      
      // Clear the current user from the BillRepository
      BillRepositoryProvider().setCurrentUser('');
    } catch (e) {
      throw 'Logout failed: ${e.toString()}';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUser == null) throw 'Not logged in';

    try {
      // Delete user's bills first
      await _db.deleteUserBills(_currentUser!.id);
      
      // Then delete user account
      await _db.deleteUser(_currentUser!.id);
      
      // Finally logout
      await logout();
    } catch (e) {
      throw 'Account deletion failed: ${e.toString()}';
    }
  }

  // Check if email exists (for registration)
  Future<bool> emailExists(String email) async {
    return await _db.emailExists(email);
  }
}