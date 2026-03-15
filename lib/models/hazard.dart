import 'package:hive/hive.dart';

part 'hazard.g.dart';

@HiveType(typeId: 0)
class Hazard extends HiveObject {
  @HiveField(0)
  String response;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<String> objectsDetected;

  @HiveField(3)
  int threatLevel;

  @HiveField(4)
  bool synced;

  @HiveField(5)
  String? localRecordingPath;

  @HiveField(6)
  String? cloudRecordingUrl;

  @HiveField(7)
  String? description;

  Hazard({
    required this.response,
    required this.date,
    required this.objectsDetected,
    required this.threatLevel,
    this.synced = false,
    this.localRecordingPath,
    this.cloudRecordingUrl,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'response': response,
    'date': date.toIso8601String(),
    'objectsDetected': objectsDetected,
    'threatLevel': threatLevel,
    'synced': synced,
    'localRecordingPath': localRecordingPath,
    'cloudRecordingUrl': cloudRecordingUrl,
    'description': description,
  };

  factory Hazard.fromJson(Map<String, dynamic> json) => Hazard(
    response: json['response'] ?? '',
    date: DateTime.parse(json['date']),
    objectsDetected: List<String>.from(json['objectsDetected'] ?? []),
    threatLevel: json['threatLevel'] ?? 0,
    synced: json['synced'] ?? false,
    localRecordingPath: json['localRecordingPath'],
    cloudRecordingUrl: json['cloudRecordingUrl'],
    description: json['description'],
  );
}
