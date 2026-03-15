import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;

  static const List<String> _hazardObjects = [
    'knife', 'scissors', 'weapon', 'fire', 'flame', 'smoke',
    'gun', 'blade', 'broken glass', 'cable', 'wire',
    'chemical', 'poison', 'crowd', 'person', 'stranger'
  ];

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  CameraController? get cameraController => _cameraController;

  Future<void> init() async {
    _isInitialized = true;
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
      final objects = <String>[];
      final hazards = <String>[];
      
      objects.add('Detected object (demo mode)');
      hazards.add('knife (demo)');
      
      int threatLevel = 50;

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
