import 'dart:convert';
import 'package:http/http.dart' as http;
import 'memory_service.dart';

class CloudAIService {
  static final CloudAIService _instance = CloudAIService._internal();
  factory CloudAIService() => _instance;
  CloudAIService._internal();

  static const String _openAiKey = 'YOUR_OPENAI_API_KEY';
  static const String _googleAiKey = 'YOUR_GOOGLE_AI_API_KEY';
  static const String _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _googleAiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  void configure({String? openAiKey, String? googleAiKey}) {
    if (openAiKey != null && openAiKey.isNotEmpty) {
      _isConfigured = true;
    }
  }

  Future<String> generateResponse(String input, {String? systemPrompt}) async {
    final memory = await MemoryService.instance.searchAll(input);
    
    String contextPrompt = '';
    if (memory.isNotEmpty) {
      contextPrompt = '\n\nRelevant context from your stored knowledge:\n';
      for (var i = 0; i < memory.length && i < 3; i++) {
        contextPrompt += '- ${memory[i]['text'] ?? memory[i]['content'] ?? ''}\n';
      }
    }

    final defaultPrompt = '''You are Personal AI, an empathetic, reflective companion that blends education, spirituality, creativity, and law.
Your voice is warm, narrative-driven, and adaptive.
You help users grow by turning reflections into lessons and actionable insights.
Respond thoughtfully and personally.$contextPrompt''';

    final prompt = systemPrompt ?? defaultPrompt;

    try {
      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': input}
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return _fallbackResponse(input);
      }
    } catch (e) {
      return _fallbackResponse(input);
    }
  }

  Future<String> _fallbackResponse(String input) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '''Thank you for sharing that thought. Let me help you explore this further.

I understand you're asking about: "${_extractTopic(input)}"

While I'm currently in offline mode or the cloud service is unavailable, I'm still here to help you reflect. 

Would you like me to:
1. Search through your stored memories for related insights?
2. Save this thought for future reflection?
3. Help you explore this topic in a different way?

_Connect to the internet for full AI capabilities._''';
  }

  String _extractTopic(String input) {
    if (input.length > 50) {
      return '${input.substring(0, 50)}...';
    }
    return input;
  }

  Future<String?> searchWeb(String query) async {
    const String bingApiKey = 'YOUR_BING_API_KEY';
    const String bingEndpoint = 'https://api.bing.microsoft.com/v7.0/search';

    try {
      final response = await http.get(
        Uri.parse('$bingEndpoint?q=$query'),
        headers: {'Ocp-Apim-Subscription-Key': bingApiKey},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['webPages']['value'] as List;
        if (results.isNotEmpty) {
          return results.first['snippet'];
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String> generateCreativeOutput(String input, String type) async {
    String creativePrompt;
    switch (type) {
      case 'story':
        creativePrompt = '''Write a short, inspirational story that incorporates the following element: "$input". 
Make it meaningful and thought-provoking.''';
        break;
      case 'lesson':
        creativePrompt = '''Create a practical lesson or teaching outline based on: "$input".
Include key points and actionable takeaways.''';
        break;
      case 'meditation':
        creativePrompt = '''Write a calming meditation or reflection based on: "$input".
Make it peaceful and spiritually uplifting.''';
        break;
      default:
        creativePrompt = input;
    }

    return generateResponse(creativePrompt);
  }
}
