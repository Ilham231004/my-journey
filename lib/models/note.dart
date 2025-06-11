import 'package:hive/hive.dart';
part 'note.g.dart';

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  String content;
  @HiveField(2)
  String imagePath;
  @HiveField(3)
  double latitude;
  @HiveField(4)
  double longitude;
  @HiveField(5)
  DateTime dateTime;
  @HiveField(6)
  double budget;
  @HiveField(7)
  String currency;
  @HiveField(8)
  String zonaWaktu;

  Note({
    required this.title,
    required this.content,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.budget,
    required this.currency,
    required this.zonaWaktu,
  });
}
