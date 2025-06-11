import 'package:hive/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;
  @HiveField(1)
  String name;
  @HiveField(2)
  String passwordHash;

  User({required this.username, required this.name, required this.passwordHash});
}
