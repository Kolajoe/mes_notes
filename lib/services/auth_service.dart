import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static const String _sessionUserIdKey = 'session_user_id';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<int> register(User user) async {
    final db = await _databaseHelper.database;

    final hashedPassword = _hashPassword(user.password);

    final userMap = user.toMap();

    userMap['password'] = hashedPassword;

    return await db.insert(
      'users',
      userMap,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<User?> login(String username, String password) async {
    final db = await _databaseHelper.database;

    final hashedPassword = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final user = User.fromMap(result.first);

    await _saveSession(user.id!);

    return user;
  }

  Future<bool> usernameExists(String username) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> _saveSession(int userId) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt(_sessionUserIdKey, userId);
  }

  Future<int?> getSessionUserId() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getInt(_sessionUserIdKey);
  }

  Future<User?> getCurrentUser() async {
    final userId = await getSessionUserId();

    if (userId == null) {
      return null;
    }

    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      await logout();
      return null;
    }

    return User.fromMap(result.first);
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_sessionUserIdKey);
  }
}
