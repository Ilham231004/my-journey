import 'package:hive/hive.dart';

class SessionService {
  static const String sessionBoxName = 'session';

  Future<bool> isLoggedIn() async {
    var box = await Hive.openBox(sessionBoxName);
    return box.get('isLoggedIn', defaultValue: false);
  }

  Future<void> setLoggedIn(bool value) async {
    var box = await Hive.openBox(sessionBoxName);
    await box.put('isLoggedIn', value);
  }

  Future<String?> getUsername() async {
    var box = await Hive.openBox(sessionBoxName);
    return box.get('username');
  }
}
