import 'dart:io';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';
import '../services/memory_service.dart';

class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;

  static const List<String> _hazardObjects = [
    'knife', 'scissors', 'weapon', 'fire', 'flame', 'smoke',
    'gun', 'knife', 'blade', 'broken glass', 'cable', 'wire',
    'chemical', 'poison', 'hazard', 'crowd', 'person', 'stranger'
  ];

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  CameraController? get cameraController => _cameraController;

  Future<void> init() async {
    await Tflite.loadModel(
      model: 'assets/models/ssd_mobilenet_v1_metadata_2.tflite',
      labels: 'assets/models/labelmap.txt',
    );
  }

  Future<void> initCamera({bool frontCamera = false}) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == (frontCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  Future<XFile?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      final image = await _cameraController!.takePicture();
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    if (_isProcessing) {
      return {'objects': [], 'threat_level': 0, 'hazards': []};
    }

    _isProcessing = true;
    try {
      final output = await Tflite.runModelOnImage(
        path: imagePath,
        numResults: 10,
        threshold: 0.5,
      );

      final objects = <String>[];
      final hazards = <String>[];
      int maxConfidence = 0;

      if (output != null) {
        for (var result in output) {
          final label = result['label'].toString().toLowerCase();
          final confidence = ((result['confidence'] as double) * 100).round();
          
          objects.add('$label ($confidence%)');
          
          if (confidence > maxConfidence) {
            maxConfidence = confidence;
          }

          for (var hazard in _hazardObjects) {
            if (label.contains(hazard)) {
              hazards.add('$label ($confidence%)');
              break;
            }
          }
        }
      }

      final threatLevel = _calculateThreatLevel(hazards, maxConfidence);

      await MemoryService.instance.addVisionLog(
        imagePath: imagePath,
        objectsDetected: objects,
        description: 'Hazard level: $threatLevel%',
      );

      return {
        'objects': objects,
        'hazards': hazards,
        'threat_level': threatLevel,
        'image_path': imagePath,
      };
    } catch (e) {
      return {'objects': [], 'hazards': [], 'threat_level': 0, 'error': e.toString()};
    } finally {
      _isProcessing = false;
    }
  }

  int _calculateThreatLevel(List<String> hazards, int maxConfidence) {
    if (hazards.isEmpty) return 0;
    
    int level = 0;
    for (var hazard in hazards) {
      if (hazard.contains('weapon') || hazard.contains('knife') || hazard.contains('gun')) {
        level += 40;
      } else if (hazard.contains('fire') || hazard.contains('smoke')) {
        level += 30;
      } else if (hazard.contains('broken') || hazard.contains('glass')) {
        level += 25;
      } else {
        level += 15;
      }
    }
    
    level = (level * maxConfidence / 100).round();
    return level.clamp(0, 100);
  }

  Future<void> disposeCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }

  Future<String> saveImageToStorage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'vision_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${directory.path}/$fileName';
    await image.saveTo(savedPath);
    return savedPath;
  }
}
