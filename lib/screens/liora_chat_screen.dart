import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/local_ai.dart';
import '../services/cloud_ai.dart';
import '../services/memory_service.dart';
import '../services/listening_service.dart';
import '../services/vision_service.dart';
import '../services/threat_detection_service.dart';
import '../services/alert_service.dart';
import '../widgets/message_bubble.dart';
import 'dashboard_screen.dart';
import 'camera_screen.dart';

class LioraChatScreen extends StatefulWidget {
  const LioraChatScreen({super.key});

  @override
  State<LioraChatScreen> createState() => _LioraChatScreenState();
}

class _LioraChatScreenState extends State<LioraChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isOnline = false;
  bool _isListening = false;
  String _selectedCategory = 'general';

  final LocalAIService _localAI = LocalAIService();
  final CloudAIService _cloudAI = CloudAIService();
  final ListeningService _listeningService = ListeningService();
  final VisionService _visionService = VisionService();
  final ThreatDetectionService _threatService = ThreatDetectionService();
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _initServices();
    _addWelcomeMessage();
  }

  Future<void> _initServices() async {
    await _listeningService.init();
    await _alertService.init();
    await _threatService.init();
    await _visionService.init();
    
    _listeningService.stateStream.listen((state) {
      if (state == ListeningState.listening) {
        setState(() => _isListening = true);
      } else if (state == ListeningState.idle || state == ListeningState.result) {
        setState(() => _isListening = false);
      }
    });
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'assistant',
      'content': '''✨ Welcome to LIORA

Your Personal AI Companion with:
• 👀 **Vision** - Analyze your surroundings
• 🎙️ **Listening** - Voice-powered conversations  
• 🛡️ **Threat Detection** - Safety monitoring
• 💾 **Memory** - Learns and grows with you

I'm here to help you reflect, learn, and stay safe.

What would you like to explore?''',
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _sendMessage() async {
    final input = _messageController.text.trim();
    if (input.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'content': input,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _scrollToBottom();

    String response;
    if (_isOnline) {
      response = await _cloudAI.generateResponse(input);
    } else {
      response = await _localAI.generateResponse(input);
    }

    await _listeningService.logVoiceInteraction(input, response);

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now(),
        'isOnline': _isOnline,
      });
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _listeningService.startListening(
        onResult: (text) {
          _messageController.text = text;
        },
        onThreatDetected: (alert) {
          _threatService.handleConcerningSound(alert);
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
    }
  }

  void _stopListening() {
    _listeningService.stopListening();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveToMemory() async {
    if (_messages.isEmpty) return;

    final lastMessage = _messages.lastWhere(
      (m) => m['role'] == 'assistant',
      orElse: () => {},
    );

    if (lastMessage.isEmpty) return;

    await MemoryService.instance.addReflection(
      text: lastMessage['content'],
      tags: [_selectedCategory],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $_selectedCategory'),
          backgroundColor: const Color(0xFF6B4EFF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMemoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save to Memory',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Choose category:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['general', 'education', 'spirituality', 'creativity', 'law', 'safety'].map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = cat);
                    Navigator.pop(context);
                    _saveToMemory();
                  },
                  selectedColor: const Color(0xFF6B4EFF),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, size: 28),
            SizedBox(width: 8),
            Text('LIORA'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.dashboard),
                  onPressed: _openDashboard,
                  tooltip: 'Dashboard',
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _openCamera,
                  tooltip: 'Vision',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isLoading || _isListening ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && (_isLoading || _isListening)) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isListening ? 'Listening...' : 'Thinking...',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                final message = _messages[index];
                return MessageBubble(
                  message: message['content'],
                  isUser: message['role'] == 'user',
                  timestamp: message['timestamp'],
                  isOnline: message['isOnline'] ?? true,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF16213E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.white54,
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    onPressed: _messages.isNotEmpty ? _showMemoryOptions : null,
                    color: Colors.white54,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: _openCamera,
                    color: Colors.white54,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message LIORA...',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B4EFF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _sendMessage,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _listeningService.dispose();
    super.dispose();
  }
}
