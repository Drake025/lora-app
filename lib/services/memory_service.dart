import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class MemoryService {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  static MemoryService get instance => _instance;
  MemoryService._internal();

  static const String _reflectionsBoxName = 'reflections';
  static const String _hazardsBoxName = 'hazards';
  static const String _visionLogsBoxName = 'vision_logs';
  static const String _voiceLogsBoxName = 'voice_logs';
  static const String _lessonsBoxName = 'lessons';
  static const String _settingsBoxName = 'settings';

  late Box<Map> _reflectionsBox;
  late Box<Map> _hazardsBox;
  late Box<Map> _visionLogsBox;
  late Box<Map> _voiceLogsBox;
  late Box<Map> _lessonsBox;
  late Box<dynamic> _settingsBox;

  final _uuid = const Uuid();

  Future<void> init() async {
    _reflectionsBox = await Hive.openBox<Map>(_reflectionsBoxName);
    _hazardsBox = await Hive.openBox<Map>(_hazardsBoxName);
    _visionLogsBox = await Hive.openBox<Map>(_visionLogsBoxName);
    _voiceLogsBox = await Hive.openBox<Map>(_voiceLogsBoxName);
    _lessonsBox = await Hive.openBox<Map>(_lessonsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // ==================== REFLECTIONS ====================
  Future<Map<String, dynamic>> addReflection({
    required String text,
    List<String> tags = const [],
    bool approved = false,
  }) async {
    final reflection = {
      'id': _uuid.v4(),
      'text': text,
      'tags': tags,
      'approved': approved,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _reflectionsBox.put(reflection['id'], reflection);
    return reflection;
  }

  Future<List<Map<String, dynamic>>> getAllReflections() async {
    return _reflectionsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
  }

  Future<void> approveReflection(String id) async {
    final reflection = _reflectionsBox.get(id);
    if (reflection != null) {
      reflection['approved'] = true;
      reflection['updatedAt'] = DateTime.now().toIso8601String();
      await _reflectionsBox.put(id, reflection);
    }
  }

  // ==================== HAZARDS ====================
  Future<Map<String, dynamic>> addHazard({
    required List<String> objectsDetected,
    required int threatLevel,
    required String response,
    String? recordingPath,
    String? cloudRecordingUrl,
  }) async {
    final hazard = {
      'id': _uuid.v4(),
      'objects_detected': objectsDetected,
      'threat_level': threatLevel,
      'response': response,
      'recording_path': recordingPath,
      'cloud_recording_url': cloudRecordingUrl,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _hazardsBox.put(hazard['id'], hazard);
    return hazard;
  }

  Future<List<Map<String, dynamic>>> getAllHazards() async {
    return _hazardsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
  }

  Future<void> deleteHazard(String id) async {
    await _hazardsBox.delete(id);
  }

  // ==================== VISION LOGS ====================
  Future<Map<String, dynamic>> addVisionLog({
    required String imagePath,
    required List<String> objectsDetected,
    String? description,
  }) async {
    final log = {
      'id': _uuid.v4(),
      'image_path': imagePath,
      'objects_detected': objectsDetected,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _visionLogsBox.put(log['id'], log);
    return log;
  }

  Future<List<Map<String, dynamic>>> getAllVisionLogs() async {
    return _visionLogsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
  }

  // ==================== VOICE LOGS ====================
  Future<Map<String, dynamic>> addVoiceLog({
    required String transcript,
    required String response,
    List<String> tags = const [],
  }) async {
    final log = {
      'id': _uuid.v4(),
      'transcript': transcript,
      'response': response,
      'tags': tags,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _voiceLogsBox.put(log['id'], log);
    return log;
  }

  Future<List<Map<String, dynamic>>> getAllVoiceLogs() async {
    return _voiceLogsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
  }

  // ==================== LESSONS ====================
  Future<Map<String, dynamic>> addLesson({
    required String title,
    required String content,
    String? source,
    List<String> tags = const [],
    bool approved = false,
  }) async {
    final lesson = {
      'id': _uuid.v4(),
      'title': title,
      'content': content,
      'source': source,
      'tags': tags,
      'approved': approved,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _lessonsBox.put(lesson['id'], lesson);
    return lesson;
  }

  Future<List<Map<String, dynamic>>> getAllLessons() async {
    return _lessonsBox.values.map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
  }

  Future<void> approveLesson(String id) async {
    final lesson = _lessonsBox.get(id);
    if (lesson != null) {
      lesson['approved'] = true;
      lesson['updatedAt'] = DateTime.now().toIso8601String();
      await _lessonsBox.put(id, lesson);
    }
  }

  // ==================== SEARCH ====================
  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    
    for (var box in [_reflectionsBox, _hazardsBox, _visionLogsBox, _voiceLogsBox, _lessonsBox]) {
      for (var item in box.values) {
        final map = Map<String, dynamic>.from(item);
        final text = map.toString().toLowerCase();
        if (text.contains(lowerQuery)) {
          results.add(map);
        }
      }
    }
    return results;
  }

  // ==================== SETTINGS ====================
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  String get userVoice {
    return getSetting<String>('userVoice') ?? 'warm, narrative, reflective';
  }

  Future<void> setUserVoice(String voice) async {
    await saveSetting('userVoice', voice);
  }

  List<String> get interests {
    return getSetting<List>('interests')?.cast<String>() ?? ['education', 'spirituality', 'creativity', 'law', 'safety'];
  }

  Future<void> setInterests(List<String> newInterests) async {
    await saveSetting('interests', newInterests);
  }

  bool get threatDetectionEnabled {
    return getSetting<bool>('threatDetectionEnabled') ?? true;
  }

  Future<void> setThreatDetection(bool enabled) async {
    await saveSetting('threatDetectionEnabled', enabled);
  }

  bool get autoRecordingEnabled {
    return getSetting<bool>('autoRecordingEnabled') ?? true;
  }

  Future<void> setAutoRecording(bool enabled) async {
    await saveSetting('autoRecordingEnabled', enabled);
  }

  int get threatConfidenceThreshold {
    return getSetting<int>('threatConfidenceThreshold') ?? 80;
  }

  Future<void> setThreatConfidenceThreshold(int threshold) async {
    await saveSetting('threatConfidenceThreshold', threshold);
  }

  // ==================== STATS ====================
  Map<String, int> getStats() {
    return {
      'reflections': _reflectionsBox.length,
      'hazards': _hazardsBox.length,
      'vision_logs': _visionLogsBox.length,
      'voice_logs': _voiceLogsBox.length,
      'lessons': _lessonsBox.length,
    };
  }

  Future<void> clearAllData() async {
    await _reflectionsBox.clear();
    await _hazardsBox.clear();
    await _visionLogsBox.clear();
    await _voiceLogsBox.clear();
    await _lessonsBox.clear();
  }
}
