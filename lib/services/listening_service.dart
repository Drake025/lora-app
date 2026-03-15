import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../services/memory_service.dart';

enum ListeningState {
  idle,
  listening,
  result,
  error,
}

class ListeningService {
  static final ListeningService _instance = ListeningService._internal();
  factory ListeningService() => _instance;
  ListeningService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _lastTranscript = '';
  String _lastError = '';

  final StreamController<ListeningState> _stateController = StreamController<ListeningState>.broadcast();
  Stream<ListeningState> get stateStream => _stateController.stream;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get lastTranscript => _lastTranscript;
  String get lastError => _lastError;

  static const List<String> _concerningSounds = [
    'help', 'help!', 'scream', 'shout', 'cry', 'crash', 'bang', 'break'
  ];

  Future<void> init() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _stateController.add(ListeningState.error);
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _stateController.add(ListeningState.idle);
          }
        },
      );
    } catch (e) {
      _isInitialized = false;
    }
  }

  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onThreatDetected,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) {
      return;
    }

    _lastWords = '';
    _isListening = true;
    _stateController.add(ListeningState.listening);

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        _lastWords = result.recognizedWords;
        _lastTranscript = _lastWords;
        
        _stateController.add(ListeningState.result);

        if (result.finalResult) {
          _isListening = false;
          _stateController.add(ListeningState.idle);

          if (onResult != null && _lastWords.isNotEmpty) {
            onResult(_lastWords);
          }

          _checkForConcerningSounds(_lastWords, onThreatDetected);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    _stateController.add(ListeningState.idle);
  }

  void _checkForConcerningSounds(String transcript, Function(String)? onThreatDetected) {
    final lowerTranscript = transcript.toLowerCase();
    for (var sound in _concerningSounds) {
      if (lowerTranscript.contains(sound)) {
        if (onThreatDetected != null) {
          onThreatDetected('Concerning sound detected: "$sound"');
        }
        break;
      }
    }
  }

  Future<void> logVoiceInteraction(String transcript, String response) async {
    await MemoryService.instance.addVoiceLog(
      transcript: transcript,
      response: response,
    );
  }

  Future<List<String>> getAvailableLocales() async {
    final locales = await _speechToText.locales();
    return locales.map((l) => l.name).toList();
  }

  void dispose() {
    _speechToText.cancel();
    _stateController.close();
  }
}
