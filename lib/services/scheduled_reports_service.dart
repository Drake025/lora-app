import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'memory_service.dart';
import 'export_service.dart';
import 'cloud_upload_service.dart';

const String weeklyReportTask = 'weeklyReport';
const String monthlyReportTask = 'monthlyReport';

class ScheduledReportsService {
  static final ScheduledReportsService _instance = ScheduledReportsService._internal();
  factory ScheduledReportsService() => _instance;
  ScheduledReportsService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    _isInitialized = true;
  }

  Future<void> scheduleWeeklyReport({String time = '09:00'}) async {
    await Workmanager().registerPeriodicTask(
      weeklyReportTask,
      weeklyReportTask,
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        'type': 'weekly',
        'time': time,
      },
    );
  }

  Future<void> scheduleMonthlyReport({String time = '09:00'}) async {
    await Workmanager().registerPeriodicTask(
      monthlyReportTask,
      monthlyReportTask,
      frequency: const Duration(days: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        'type': 'monthly',
        'time': time,
      },
    );
  }

  Future<void> cancelWeeklyReport() async {
    await Workmanager().cancelByUniqueName(weeklyReportTask);
  }

  Future<void> cancelMonthlyReport() async {
    await Workmanager().cancelByUniqueName(monthlyReportTask);
  }

  Future<void> cancelAllReports() async {
    await Workmanager().cancelAll();
  }

  Future<void> generateReportNow({bool weekly = true}) async {
    final now = DateTime.now();
    DateTime startDate;
    
    if (weekly) {
      startDate = now.subtract(const Duration(days: 7));
    } else {
      startDate = DateTime(now.year, now.month - 1, now.day);
    }

    final memory = MemoryService.instance;
    
    final allHazards = await memory.getAllHazards();
    final allReflections = await memory.getAllReflections();
    final allLessons = await memory.getAllLessons();

    final hazards = allHazards.where((h) => 
      DateTime.parse(h['createdAt']).isAfter(startDate)).toList();
    final reflections = allReflections.where((r) => 
      DateTime.parse(r['createdAt']).isAfter(startDate)).toList();
    final lessons = allLessons.where((l) => 
      DateTime.parse(l['createdAt']).isAfter(startDate)).toList();

    final exportService = ExportService();
    
    final pdfFile = await exportService.exportAllToPDF(
      _convertToHazards(hazards),
      _convertToReflections(reflections),
      _convertToLessons(lessons),
      template: ReportTemplate.infographic,
    );

    final cloudUpload = CloudUploadService();
    await cloudUpload.uploadToCloud(pdfFile, folderName: weekly ? 'LIORA_Weekly' : 'LIORA_Monthly');
  }

  List<Hazard> _convertToHazards(List<Map<String, dynamic>> data) {
    return data.map((h) => Hazard(
      response: h['response'] ?? '',
      date: DateTime.parse(h['createdAt']),
      objectsDetected: List<String>.from(h['objects_detected'] ?? []),
      threatLevel: h['threat_level'] ?? 0,
      description: h['response'],
    )).toList();
  }

  List<Reflection> _convertToReflections(List<Map<String, dynamic>> data) {
    return data.map((r) => Reflection(
      text: r['text'] ?? r['content'] ?? '',
      date: DateTime.parse(r['createdAt']),
      tags: List<String>.from(r['tags'] ?? []),
      approved: r['approved'] ?? false,
    )).toList();
  }

  List<Lesson> _convertToLessons(List<Map<String, dynamic>> data) {
    return data.map((l) => Lesson(
      title: l['title'] ?? '',
      content: l['content'] ?? '',
      date: DateTime.parse(l['createdAt']),
      tags: List<String>.from(l['tags'] ?? []),
      approved: l['approved'] ?? false,
    )).toList();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == weeklyReportTask) {
      final service = ScheduledReportsService();
      await service.generateReportNow(weekly: true);
    } else if (task == monthlyReportTask) {
      final service = ScheduledReportsService();
      await service.generateReportNow(weekly: false);
    }
    return Future.value(true);
  });
}
