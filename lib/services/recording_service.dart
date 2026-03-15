import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  final RecorderController _recorderController = RecorderController();
  RecorderController get recorderController => _recorderController;

  bool _isRecording = false;
  String? _recordingPath;
  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;

  final _uuid = const Uuid();

  Future<void> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${_uuid.v4()}.m4a';
    _recordingPath = '${dir.path}/$fileName';

    await _recorderController.record(path: _recordingPath);
    _isRecording = true;
  }

  Future<String?> stopRecording() async {
    await _recorderController.stop();
    _isRecording = false;
    return _recordingPath;
  }

  Future<void> cancelRecording() async {
    await _recorderController.stop();
    _isRecording = false;
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _recordingPath = null;
  }

  Future<String?> transcribeAudio(String audioPath) async {
    // For actual transcription, you would use a service like:
    // - Google Cloud Speech-to-Text
    // - OpenAI Whisper
    // - Azure Speech Services
    
    // For now, return a placeholder - in production, integrate with an API
    return 'Voice recording saved. Transcription would be processed here.';
  }

  void dispose() {
    _recorderController.dispose();
  }
}
