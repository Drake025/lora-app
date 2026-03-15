import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/memory_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _hazards = [];
  List<Map<String, dynamic>> _reflections = [];
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _visionLogs = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final memory = MemoryService.instance;
    final hazards = await memory.getAllHazards();
    final reflections = await memory.getAllReflections();
    final lessons = await memory.getAllLessons();
    final visionLogs = await memory.getAllVisionLogs();
    final stats = memory.getStats();

    setState(() {
      _hazards = hazards;
      _reflections = reflections;
      _lessons = lessons;
      _visionLogs = visionLogs;
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LIORA Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber), text: 'Hazards'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Lessons'),
            Tab(icon: Icon(Icons.auto_stories), text: 'Reflections'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
          indicatorColor: const Color(0xFF6B4EFF),
          labelColor: const Color(0xFF6B4EFF),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHazardsTab(),
          _buildLessonsTab(),
          _buildReflectionsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildHazardsTab() {
    if (_hazards.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shield_outlined,
        title: 'No Hazards Logged',
        subtitle: 'LIORA will alert you when hazards are detected',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hazards.length,
      itemBuilder: (context, index) {
        final hazard = _hazards[index];
        return _buildHazardCard(hazard);
      },
    );
  }

  Widget _buildHazardCard(Map<String, dynamic> hazard) {
    final threatLevel = hazard['threat_level'] as int? ?? 0;
    final objects = List<String>.from(hazard['objects_detected'] ?? []);
    final hasRecording = hazard['recording_path'] != null;

    Color threatColor;
    if (threatLevel >= 80) {
      threatColor = Colors.red;
    } else if (threatLevel >= 60) {
      threatColor = Colors.orange;
    } else {
      threatColor = Colors.yellow;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F3460),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: threatColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        threatLevel >= 60 ? Icons.warning : Icons.info_outline,
                        size: 16,
                        color: threatColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$threatLevel%',
                        style: TextStyle(
                          color: threatColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (hasRecording)
                  const Icon(Icons.videocam, color: Colors.red, size: 20),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => _shareHazard(hazard),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteHazard(hazard['id']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              objects.join(', '),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hazard['response'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy h:mm a').format(
                DateTime.parse(hazard['createdAt']),
              ),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    if (_lessons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        title: 'No Lessons Yet',
        subtitle: 'Save important insights as lessons',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        return _buildLessonCard(lesson);
      },
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final approved = lesson['approved'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F3460),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lesson['title'] ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    approved ? Icons.check_circle : Icons.check_circle_outline,
                    color: approved ? Colors.green : Colors.white38,
                  ),
                  onPressed: () => _toggleLessonApproval(lesson['id'], approved),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => _shareLesson(lesson),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lesson['content'] ?? '',
              style: const TextStyle(color: Colors.white70),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (lesson['tags'] != null && (lesson['tags'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                children: (lesson['tags'] as List).map<Widget>((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFF6B4EFF).withOpacity(0.3),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionsTab() {
    if (_reflections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.self_improvement,
        title: 'No Reflections',
        subtitle: 'Your thoughts and reflections will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reflections.length,
      itemBuilder: (context, index) {
        final reflection = _reflections[index];
        return _buildReflectionCard(reflection);
      },
    );
  }

  Widget _buildReflectionCard(Map<String, dynamic> reflection) {
    final approved = reflection['approved'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F3460),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reflection['text'] ?? '',
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    approved ? Icons.bookmark : Icons.bookmark_border,
                    color: approved ? const Color(0xFF6B4EFF) : Colors.white38,
                  ),
                  onPressed: () => _toggleReflectionApproval(reflection['id'], approved),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy').format(
                DateTime.parse(reflection['createdAt']),
              ),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Hazards Logged', _stats['hazards'] ?? 0, Icons.warning_amber, Colors.red),
          const SizedBox(height: 12),
          _buildStatCard('Lessons Saved', _stats['lessons'] ?? 0, Icons.school, const Color(0xFF6B4EFF)),
          const SizedBox(height: 12),
          _buildStatCard('Reflections', _stats['reflections'] ?? 0, Icons.auto_stories, Colors.blue),
          const SizedBox(height: 12),
          _buildStatCard('Vision Analyses', _stats['vision_logs'] ?? 0, Icons.visibility, Colors.green),
          const SizedBox(height: 12),
          _buildStatCard('Voice Interactions', _stats['voice_logs'] ?? 0, Icons.mic, Colors.orange),
          const SizedBox(height: 24),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF0F3460),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      color: const Color(0xFF0F3460),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Threat Detection', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Enable hazard detection', style: TextStyle(color: Colors.white54)),
              value: MemoryService.instance.threatDetectionEnabled,
              onChanged: (value) async {
                await MemoryService.instance.setThreatDetection(value);
                _loadData();
              },
              activeColor: const Color(0xFF6B4EFF),
            ),
            SwitchListTile(
              title: const Text('Auto-Recording', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Record when hazard detected', style: TextStyle(color: Colors.white54)),
              value: MemoryService.instance.autoRecordingEnabled,
              onChanged: (value) async {
                await MemoryService.instance.setAutoRecording(value);
                _loadData();
              },
              activeColor: const Color(0xFF6B4EFF),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: _showClearDataDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  void _shareHazard(Map<String, dynamic> hazard) {
    final text = 'LIORA Hazard Alert\n'
        'Threat Level: ${hazard['threat_level']}%\n'
        'Objects: ${(hazard['objects_detected'] as List).join(", ")}\n'
        'Response: ${hazard['response']}\n'
        'Time: ${hazard['createdAt']}';
    Share.share(text);
  }

  void _shareLesson(Map<String, dynamic> lesson) {
    final text = 'LIORA Lesson: ${lesson['title']}\n\n${lesson['content']}';
    Share.share(text);
  }

  Future<void> _deleteHazard(String id) async {
    await MemoryService.instance.deleteHazard(id);
    _loadData();
  }

  Future<void> _toggleLessonApproval(String id, bool current) async {
    if (!current) {
      await MemoryService.instance.approveLesson(id);
    }
    _loadData();
  }

  Future<void> _toggleReflectionApproval(String id, bool current) async {
    if (!current) {
      await MemoryService.instance.approveReflection(id);
    }
    _loadData();
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all hazards, lessons, reflections, and logs. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await MemoryService.instance.clearAllData();
              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
