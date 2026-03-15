import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 2)
class Lesson extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? source;

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  bool approved;

  @HiveField(6)
  bool synced;

  Lesson({
    required this.title,
    required this.content,
    required this.date,
    this.source,
    this.tags = const [],
    this.approved = false,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'source': source,
    'tags': tags,
    'approved': approved,
    'synced': synced,
  };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    date: DateTime.parse(json['date']),
    source: json['source'],
    tags: List<String>.from(json['tags'] ?? []),
    approved: json['approved'] ?? false,
    synced: json['synced'] ?? false,
  );
}
