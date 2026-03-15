import 'package:hive/hive.dart';

part 'reflection.g.dart';

@HiveType(typeId: 1)
class Reflection extends HiveObject {
  @HiveField(0)
  String text;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  bool synced;

  @HiveField(3)
  String? localAudioPath;

  @HiveField(4)
  String? cloudAudioUrl;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  String? transcript;

  @HiveField(7)
  bool approved;

  Reflection({
    required this.text,
    required this.date,
    this.synced = false,
    this.localAudioPath,
    this.cloudAudioUrl,
    this.tags = const [],
    this.transcript,
    this.approved = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'date': date.toIso8601String(),
    'synced': synced,
    'localAudioPath': localAudioPath,
    'cloudAudioUrl': cloudAudioUrl,
    'tags': tags,
    'transcript': transcript,
    'approved': approved,
  };

  factory Reflection.fromJson(Map<String, dynamic> json) => Reflection(
    text: json['text'] ?? '',
    date: DateTime.parse(json['date']),
    synced: json['synced'] ?? false,
    localAudioPath: json['localAudioPath'],
    cloudAudioUrl: json['cloudAudioUrl'],
    tags: List<String>.from(json['tags'] ?? []),
    transcript: json['transcript'],
    approved: json['approved'] ?? false,
  );
}
