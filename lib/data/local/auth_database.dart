import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user.dart';

class AuthDatabase {
  static final AuthDatabase _instance = AuthDatabase._internal();
  static Database? _database;

  factory AuthDatabase() => _instance;

  AuthDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Use app documents directory on desktop platforms
      String dbPath;
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final appDocDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocDir.path, 'databases', 'auth.db');
        // Ensure the directory exists
        await Directory(dirname(dbPath)).create(recursive: true);
      } else {
        // For Android/iOS
        final dbDir = await getDatabasesPath();
        dbPath = join(dbDir, 'auth.db');
        // Ensure the directory exists
        await Directory(dirname(dbPath)).create(recursive: true);
      }
      
      print('Opening database at: $dbPath');
      
      return await openDatabase(
        dbPath,
        version: 1,
        onCreate: _createDb,
        onOpen: (db) async {
          print('Database opened successfully');
          // Verify tables exist
          final tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
          print('Tables in database: ${tables.map((t) => t['name']).join(', ')}');
        },
      );
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    print('Creating database tables...');
    try {
      await db.execute('''
        CREATE TABLE users(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      // Create index on email for faster lookups
      await db.execute('CREATE UNIQUE INDEX idx_users_email ON users(email)');
      print('Database tables created successfully');
    } catch (e, stackTrace) {
      print('Error creating database tables: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register a new user
  Future<User> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    
    // Check if email already exists
    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (existingUser.isNotEmpty) {
      throw 'Email already registered';
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final passwordHash = _hashPassword(password);

    final user = {
      'id': userId,
      'name': name,
      'email': email.toLowerCase(),
      'password_hash': passwordHash,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert('users', user);

    return User(
      id: userId,
      email: email,
      name: name,
    );
  }

  // Login user
  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw 'User not found';
    }

    final user = results.first;
    final passwordHash = _hashPassword(password);

    if (user['password_hash'] != passwordHash) {
      throw 'Invalid password';
    }

    return User(
      id: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String,
    );
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    return results.isNotEmpty;
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? password,
  }) async {
    final db = await database;
    
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (password != null) updates['password_hash'] = _hashPassword(password);

    if (updates.isEmpty) return;

    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    final db = await database;
    
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;

    final user = results.first;
    return User(
      id: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String,
    );
  }

  // Delete user account
  Future<void> deleteUser(String userId) async {
    final db = await database;
    
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Delete all bills associated with a user
  Future<void> deleteUserBills(String userId) async {
    final db = await database;
    
    await db.delete(
      'bills',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}