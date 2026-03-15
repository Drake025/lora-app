import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/vision_service.dart';
import '../services/threat_detection_service.dart';
import '../services/memory_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final VisionService _visionService = VisionService();
  final ThreatDetectionService _threatService = ThreatDetectionService();
  
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  String _status = 'Initializing camera...';
  Map<String, dynamic>? _lastAnalysis;
  int _threatLevel = 0;
  List<String> _hazards = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _status = 'Initializing camera...');
    await _visionService.initCamera();
    
    if (_visionService.isInitialized) {
      setState(() {
        _isInitialized = true;
        _status = 'Point at an area to analyze';
      });
    } else {
      setState(() => _status = 'Camera not available');
    }
  }

  Future<void> _analyzeCurrentFrame() async {
    if (!_isInitialized || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _status = 'Analyzing...';
    });

    final image = await _visionService.takePicture();
    if (image != null) {
      final savedPath = await _visionService.saveImageToStorage(image);
      final result = await _visionService.analyzeImage(savedPath);
      final analysis = await _threatService.analyzeVisionResult(result);

      setState(() {
        _lastAnalysis = result;
        _hazards = analysis.hazards;
        _threatLevel = analysis.threatLevel;
        _status = analysis.response;
        _isAnalyzing = false;
      });
    } else {
      setState(() {
        _isAnalyzing = false;
        _status = 'Failed to capture image';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LIORA Vision'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized
                ? _buildCameraPreview()
                : _buildLoadingState(),
          ),
          _buildAnalysisPanel(),
        ],
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton.extended(
              onPressed: _isAnalyzing ? null : _analyzeCurrentFrame,
              backgroundColor: _threatLevel > 60 
                  ? Colors.red 
                  : const Color(0xFF6B4EFF),
              icon: _isAnalyzing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
            )
          : null,
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_visionService.cameraController != null)
          CameraPreview(_visionService.cameraController!),
        
        // Scanning overlay
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _threatLevel > 60 
                    ? Colors.red 
                    : const Color(0xFF6B4EFF),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_threatLevel > 60)
                  const Icon(Icons.warning, color: Colors.red, size: 48),
              ],
            ),
          ),
        ),
        
        // Status indicator
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _threatLevel > 60 
                      ? Icons.warning 
                      : Icons.visibility,
                  color: _threatLevel > 60 
                      ? Colors.red 
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6B4EFF)),
          const SizedBox(height: 16),
          Text(
            _status,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel() {
    if (_lastAnalysis == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF16213E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Analysis Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_threatLevel > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _threatLevel > 60 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Threat: $_threatLevel%',
                      style: TextStyle(
                        color: _threatLevel > 60 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (_hazards.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _hazards.map((h) => Chip(
                  label: Text(h),
                  backgroundColor: Colors.red.withOpacity(0.3),
                )).toList(),
              ),
            ] else if (_lastAnalysis!['objects'] != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_lastAnalysis!['objects'] as List).map<Widget>((o) => Chip(
                  label: Text(o.toString()),
                  backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.3),
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _status,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _visionService.disposeCamera();
    super.dispose();
  }
}
