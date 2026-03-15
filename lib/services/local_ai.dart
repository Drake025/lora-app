import 'dart:math';
import '../services/memory_service.dart';

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  final Random _random = Random();

  final Map<String, List<String>> _responseTemplates = {
    'greeting': [
      "Hello! It's wonderful to connect with you. What's on your mind today?",
      "Hi there! I'm here to help you reflect and grow. What would you like to explore?",
      "Hey! Ready to dive into some thoughts together?",
    ],
    'default': [
      "I'd love to help you explore that. Let me share some thoughts...",
      "That's a meaningful question. Here's my perspective...",
      "Interesting reflection. Let me think about this with you...",
    ],
    'reflection': [
      "When we reflect on this, we might consider how it connects to our journey of growth...",
      "This reminds me of the importance of staying present while learning from the past...",
      "What a thoughtful question. Let's explore this together...",
    ],
    'law': [
      "From a legal perspective, this touches on important principles of fairness and justice...",
      "Let me share some legal insights that might help clarify this...",
    ],
    'education': [
      "In education, we often find that the best learning happens through reflection...",
      "This is a great teaching moment. Let me break this down...",
    ],
    'spirituality': [
      "Spiritually, this invites us to look deeper within ourselves...",
      "This question touches the heart. Let me share some wisdom...",
    ],
    'creativity': [
      "Art has a way of revealing truth. Let me spark some creative thoughts...",
      "Creativity blooms when we allow ourselves to explore freely...",
    ],
  };

  String _detectCategory(String input) {
    final lowerInput = input.toLowerCase();
    if (lowerInput.contains('legal') || lowerInput.contains('law') || lowerInput.contains('court') || lowerInput.contains('rights')) {
      return 'law';
    }
    if (lowerInput.contains('teach') || lowerInput.contains('learn') || lowerInput.contains('student') || lowerInput.contains('education')) {
      return 'education';
    }
    if (lowerInput.contains('god') || lowerInput.contains('faith') || lowerInput.contains('spirit') || lowerInput.contains('soul') || lowerInput.contains('pray')) {
      return 'spirituality';
    }
    if (lowerInput.contains('create') || lowerInput.contains('art') || lowerInput.contains('music') || lowerInput.contains('write') || lowerInput.contains('story')) {
      return 'creativity';
    }
    if (lowerInput.contains('reflect') || lowerInput.contains('think') || lowerInput.contains('feel') || lowerInput.contains('journey')) {
      return 'reflection';
    }
    if (lowerInput.contains('hello') || lowerInput.contains('hi') || lowerInput.contains('hey') || lowerInput.contains('good')) {
      return 'greeting';
    }
    return 'default';
  }

  Future<String> generateResponse(String input) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final category = _detectCategory(input);
    final templates = _responseTemplates[category] ?? _responseTemplates['default']!;
    final baseResponse = templates[_random.nextInt(templates.length)];

    final memory = await MemoryService.instance.searchAll(input);
    String contextSection = '';
    if (memory.isNotEmpty) {
      contextSection = '\n\nFrom your previous reflections: "${memory.first['text']}"';
    }

    return '$baseResponse$contextSection\n\n_[This is an offline response. Connect to the internet for enhanced responses with current knowledge.]_';
  }

  Future<String> generateReflection(String topic) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final reflections = [
      "Every challenge we face is an opportunity for growth. In moments of difficulty, remember that resilience is not about avoiding struggle, but about rising with deeper understanding.",
      "The journey of learning is never linear. Sometimes we take two steps back to understand the full picture. Trust the process.",
      "True wisdom comes from quiet reflection. In the stillness, we find answers that noise cannot provide.",
      "Your experiences shape you, but they don't define you. You have the power to choose how to interpret and use them.",
    ];

    return reflections[_random.nextInt(reflections.length)];
  }
}
