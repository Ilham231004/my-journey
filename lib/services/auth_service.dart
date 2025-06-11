import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  static const String userBoxName = 'users';
  static const String sessionBoxName = 'session';

  Future<void> register(String username, String name, String password) async {
    var box = await Hive.openBox<User>(userBoxName);
    if (box.values.any((u) => u.username == username)) {
      throw Exception('Username already exists');
    }
    String hash = sha256.convert(utf8.encode(password)).toString();
    final user = User(username: username, name: name, passwordHash: hash);
    await box.add(user);
  }

  Future<User?> login(String username, String password) async {
    var box = await Hive.openBox<User>(userBoxName);
    String hash = sha256.convert(utf8.encode(password)).toString();
    final user = box.values.cast<User?>().firstWhere(
      (u) => u != null && u.username == username && u.passwordHash == hash,
      orElse: () => null,
    );
    if (user != null) {
      var sessionBox = await Hive.openBox(sessionBoxName);
      await sessionBox.put('isLoggedIn', true);
      await sessionBox.put('username', user.username);
    }
    return user;
  }

  Future<void> logout() async {
    var sessionBox = await Hive.openBox(sessionBoxName);
    await sessionBox.clear();
  }

  Future<bool> isLoggedIn() async {
    var sessionBox = await Hive.openBox(sessionBoxName);
    return sessionBox.get('isLoggedIn', defaultValue: false);
  }
}
