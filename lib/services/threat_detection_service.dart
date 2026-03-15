import 'dart:async';
import '../services/memory_service.dart';
import '../services/vision_service.dart';
import '../services/alert_service.dart';

class ThreatDetectionService {
  static final ThreatDetectionService _instance = ThreatDetectionService._internal();
  factory ThreatDetectionService() => _instance;
  ThreatDetectionService._internal();

  final VisionService _visionService = VisionService();
  final AlertService _alertService = AlertService();
  
  bool _isMonitoring = false;
  int _threatConfidenceThreshold = 80;
  Timer? _monitoringTimer;
  
  final StreamController<ThreatAlert> _alertController = StreamController<ThreatAlert>.broadcast();
  Stream<ThreatAlert> get alertStream => _alertController.stream;

  bool get isMonitoring => _isMonitoring;
  int get threatConfidenceThreshold => _threatConfidenceThreshold;

  static const Map<String, int> _hazardWeights = {
    'weapon': 90,
    'gun': 95,
    'knife': 85,
    'blade': 80,
    'fire': 75,
    'flame': 75,
    'smoke': 60,
    'broken glass': 70,
    'chemical': 80,
    'poison': 85,
    'intruder': 80,
    'stranger': 40,
  };

  Future<void> init() async {
    _threatConfidenceThreshold = MemoryService.instance.threatConfidenceThreshold;
  }

  void setConfidenceThreshold(int threshold) {
    _threatConfidenceThreshold = threshold.clamp(0, 100);
    MemoryService.instance.setThreatConfidenceThreshold(_threatConfidenceThreshold);
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _alertController.add(ThreatAlert(
      type: ThreatType.info,
      message: 'Threat monitoring started',
      timestamp: DateTime.now(),
    ));
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  Future<ThreatAnalysis> analyzeVisionResult(Map<String, dynamic> visionResult) async {
    final hazards = List<String>.from(visionResult['hazards'] ?? []);
    final threatLevel = visionResult['threat_level'] as int? ?? 0;
    final imagePath = visionResult['image_path'] as String?;

    bool shouldAlert = threatLevel >= _threatConfidenceThreshold;
    bool shouldRecord = threatLevel >= 80;

    String response = '';
    if (hazards.isEmpty) {
      response = 'The area appears clear. No significant hazards detected.';
    } else {
      response = _generateThreatResponse(hazards, threatLevel);
    }

    if (shouldAlert) {
      final alert = ThreatAlert(
        type: ThreatType.warning,
        message: 'Hazard detected: ${hazards.join(", ")} (${threatLevel}%)',
        threatLevel: threatLevel,
        hazards: hazards,
        timestamp: DateTime.now(),
      );
      
      _alertController.add(alert);
      await _alertService.showThreatAlert(alert);

      await MemoryService.instance.addHazard(
        objectsDetected: hazards,
        threatLevel: threatLevel,
        response: response,
        recordingPath: shouldRecord ? imagePath : null,
      );
    }

    return ThreatAnalysis(
      hazards: hazards,
      threatLevel: threatLevel,
      shouldAlert: shouldAlert,
      shouldRecord: shouldRecord,
      response: response,
    );
  }

  String _generateThreatResponse(List<String> hazards, int threatLevel) {
    if (threatLevel >= 80) {
      return 'I\'ve detected significant hazards: ${hazards.join(", ")}. I\'m recording this for your safety review.';
    } else if (threatLevel >= 60) {
      return 'I notice some potential concerns: ${hazards.join(", ")}. Please review when convenient.';
    } else {
      return 'I detected ${hazards.join(", ")}. These are low-risk items but worth being aware of.';
    }
  }

  void handleConcerningSound(String sound) async {
    final alert = ThreatAlert(
      type: ThreatType.audio,
      message: 'Concerning sound detected: "$sound"',
      threatLevel: 70,
      hazards: [sound],
      timestamp: DateTime.now(),
    );

    _alertController.add(alert);
    await _alertService.showThreatAlert(alert);

    await MemoryService.instance.addHazard(
      objectsDetected: [sound],
      threatLevel: 70,
      response: 'Audio hazard detected: $sound',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentHazards({int limit = 10}) async {
    final hazards = await MemoryService.instance.getAllHazards();
    return hazards.take(limit).toList();
  }

  void dispose() {
    stopMonitoring();
    _alertController.close();
  }
}

class ThreatAnalysis {
  final List<String> hazards;
  final int threatLevel;
  final bool shouldAlert;
  final bool shouldRecord;
  final String response;

  ThreatAnalysis({
    required this.hazards,
    required this.threatLevel,
    required this.shouldAlert,
    required this.shouldRecord,
    required this.response,
  });
}
