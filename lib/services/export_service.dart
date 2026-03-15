import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/hazard.dart';
import '../models/reflection.dart';
import '../models/lesson.dart';

enum ReportTemplate { narrative, tabular, infographic }

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  PdfColor _themeColor = PdfColors.purple;
  String _fontFamily = 'Helvetica';

  void setThemeColor(PdfColor color) {
    _themeColor = color;
  }

  void setFontFamily(String font) {
    _fontFamily = font;
  }

  Future<File> exportHazardsToPDF(
    List<Hazard> hazards, {
    ReportTemplate template = ReportTemplate.narrative,
    bool bilingual = false,
  }) async {
    final pdf = pw.Document();
    
    switch (template) {
      case ReportTemplate.narrative:
        _buildNarrativeReport(pdf, hazards: hazards, bilingual: bilingual);
        break;
      case ReportTemplate.tabular:
        _buildTabularReport(pdf, hazards: hazards, bilingual: bilingual);
        break;
      case ReportTemplate.infographic:
        _buildInfographicReport(pdf, hazards: hazards, bilingual: bilingual);
        break;
    }

    return _savePdf(pdf, 'lora_hazards');
  }

  Future<File> exportReflectionsToPDF(
    List<Reflection> reflections, {
    ReportTemplate template = ReportTemplate.narrative,
    bool bilingual = false,
  }) async {
    final pdf = pw.Document();
    
    switch (template) {
      case ReportTemplate.narrative:
        _buildNarrativeReport(pdf, reflections: reflections, bilingual: bilingual);
        break;
      case ReportTemplate.tabular:
        _buildTabularReport(pdf, reflections: reflections, bilingual: bilingual);
        break;
      case ReportTemplate.infographic:
        _buildInfographicReport(pdf, reflections: reflections, bilingual: bilingual);
        break;
    }

    return _savePdf(pdf, 'lora_reflections');
  }

  Future<File> exportLessonsToPDF(
    List<Lesson> lessons, {
    ReportTemplate template = ReportTemplate.narrative,
    bool bilingual = false,
  }) async {
    final pdf = pw.Document();
    
    switch (template) {
      case ReportTemplate.narrative:
        _buildNarrativeReport(pdf, lessons: lessons, bilingual: bilingual);
        break;
      case ReportTemplate.tabular:
        _buildTabularReport(pdf, lessons: lessons, bilingual: bilingual);
        break;
      case ReportTemplate.infographic:
        _buildInfographicReport(pdf, lessons: lessons, bilingual: bilingual);
        break;
    }

    return _savePdf(pdf, 'lora_lessons');
  }

  Future<File> exportAllToPDF(
    List<Hazard> hazards,
    List<Reflection> reflections,
    List<Lesson> lessons, {
    ReportTemplate template = ReportTemplate.narrative,
    bool bilingual = false,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildSummary(hazards.length, reflections.length, lessons.length),
          pw.SizedBox(height: 20),
          if (hazards.isNotEmpty) ...[
            _buildSectionTitle('Hazards'),
            ...hazards.map((h) => _buildHazardItem(h, bilingual)),
            pw.SizedBox(height: 20),
          ],
          if (reflections.isNotEmpty) ...[
            _buildSectionTitle('Reflections'),
            ...reflections.map((r) => _buildReflectionItem(r, bilingual)),
            pw.SizedBox(height: 20),
          ],
          if (lessons.isNotEmpty) ...[
            _buildSectionTitle('Lessons'),
            ...lessons.map((l) => _buildLessonItem(l, bilingual)),
          ],
        ],
      ),
    );

    return _savePdf(pdf, 'lora_complete_report');
  }

  void _buildNarrativeReport(
    pw.Document pdf, {
    List<Hazard>? hazards,
    List<Reflection>? reflections,
    List<Lesson>? lessons,
    bool bilingual = false,
  }) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          if (hazards != null && hazards.isNotEmpty) ...[
            _buildSectionTitle('Hazards Report'),
            ...hazards.map((h) => pw.Paragraph(
              text: _formatHazardNarrative(h, bilingual),
              style: const pw.TextStyle(fontSize: 11),
            )),
            pw.SizedBox(height: 20),
          ],
          if (reflections != null && reflections.isNotEmpty) ...[
            _buildSectionTitle('Reflections'),
            ...reflections.map((r) => pw.Paragraph(
              text: _formatReflectionNarrative(r, bilingual),
              style: const pw.TextStyle(fontSize: 11),
            )),
            pw.SizedBox(height: 20),
          ],
          if (lessons != null && lessons.isNotEmpty) ...[
            _buildSectionTitle('Lessons Learned'),
            ...lessons.map((l) => pw.Paragraph(
              text: _formatLessonNarrative(l, bilingual),
              style: const pw.TextStyle(fontSize: 11),
            )),
          ],
        ],
      ),
    );
  }

  void _buildTabularReport(
    pw.Document pdf, {
    List<Hazard>? hazards,
    List<Reflection>? reflections,
    List<Lesson>? lessons,
    bool bilingual = false,
  }) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            pw.SizedBox(height: 20),
            if (hazards != null && hazards.isNotEmpty) ...[
              _buildSectionTitle('Hazards'),
              _buildHazardsTable(hazards, bilingual),
              pw.SizedBox(height: 20),
            ],
            if (reflections != null && reflections.isNotEmpty) ...[
              _buildSectionTitle('Reflections'),
              _buildReflectionsTable(reflections, bilingual),
              pw.SizedBox(height: 20),
            ],
            if (lessons != null && lessons.isNotEmpty) ...[
              _buildSectionTitle('Lessons'),
              _buildLessonsTable(lessons, bilingual),
            ],
          ],
        ),
      ),
    );
  }

  void _buildInfographicReport(
    pw.Document pdf, {
    List<Hazard>? hazards,
    List<Reflection>? reflections,
    List<Lesson>? lessons,
    bool bilingual = false,
  }) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildStatsGrid(hazards?.length ?? 0, reflections?.length ?? 0, lessons?.length ?? 0),
            pw.SizedBox(height: 30),
            if (hazards != null && hazards.isNotEmpty) ...[
              _buildSectionTitle('Recent Hazards'),
              _buildHazardsList(hazards.take(5).toList()),
              pw.SizedBox(height: 20),
            ],
            if (reflections != null && reflections.isNotEmpty) ...[
              _buildSectionTitle('Recent Reflections'),
              _buildReflectionsList(reflections.take(5).toList()),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _themeColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'LIORA Report',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            DateFormat('MMM d, yyyy').format(DateTime.now()),
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(int hazards, int reflections, int lessons) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('Hazards', hazards, PdfColors.red),
        _buildStatCard('Reflections', reflections, PdfColors.blue),
        _buildStatCard('Lessons', lessons, PdfColors.green),
      ],
    );
  }

  pw.Widget _buildStatCard(String label, int count, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            count.toString(),
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(label),
        ],
      ),
    );
  }

  pw.Widget _buildStatsGrid(int hazards, int reflections, int lessons) {
    return pw.GridView(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Hazards', hazards, PdfColors.red),
        _buildStatCard('Reflections', reflections, PdfColors.blue),
        _buildStatCard('Lessons', lessons, PdfColors.green),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _themeColor.shade(0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildHazardsTable(List<Hazard> hazards, bool bilingual) {
    return pw.Table.fromTextArray(
      headers: bilingual 
          ? ['Date', 'Threat Level', 'Objects', 'Response', 'Petsa', 'Antas ng Banta', 'Bagay', 'Tugon']
          : ['Date', 'Threat Level', 'Objects', 'Response'],
      data: hazards.map((h) => bilingual
          ? [
              DateFormat('MMM d').format(h.date),
              '${h.threatLevel}%',
              h.objectsDetected.join(', '),
              h.response,
              DateFormat('MMM d').format(h.date),
              '${h.threatLevel}%',
              h.objectsDetected.join(', '),
              h.response,
            ]
          : [
              DateFormat('MMM d').format(h.date),
              '${h.threatLevel}%',
              h.objectsDetected.join(', '),
              h.response,
            ]).toList(),
    );
  }

  pw.Widget _buildReflectionsTable(List<Reflection> reflections, bool bilingual) {
    return pw.Table.fromTextArray(
      headers: bilingual
          ? ['Date', 'Reflection', 'Petsa', 'Pagninilay']
          : ['Date', 'Reflection'],
      data: reflections.map((r) => bilingual
          ? [
              DateFormat('MMM d').format(r.date),
              r.text,
              DateFormat('MMM d').format(r.date),
              r.text,
            ]
          : [
              DateFormat('MMM d').format(r.date),
              r.text,
            ]).toList(),
    );
  }

  pw.WWidget _buildLessonsTable(List<Lesson> lessons, bool bilingual) {
    return pw.Table.fromTextArray(
      headers: bilingual
          ? ['Date', 'Title', 'Content', 'Petsa', 'Pamagat', 'Nilalaman']
          : ['Date', 'Title', 'Content'],
      data: lessons.map((l) => bilingual
          ? [
              DateFormat('MMM d').format(l.date),
              l.title,
              l.content.length > 50 ? '${l.content.substring(0, 50)}...' : l.content,
              DateFormat('MMM d').format(l.date),
              l.title,
              l.content.length > 50 ? '${l.content.substring(0, 50)}...' : l.content,
            ]
          : [
              DateFormat('MMM d').format(l.date),
              l.title,
              l.content.length > 50 ? '${l.content.substring(0, 50)}...' : l.content,
            ]).toList(),
    );
  }

  pw.Widget _buildHazardsList(List<Hazard> hazards) {
    return pw.Column(
      children: hazards.map((h) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.red.shade(0.5)),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(DateFormat('MMM d, yyyy').format(h.date)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: h.threatLevel > 60 ? PdfColors.red : PdfColors.orange,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text('${h.threatLevel}%', style: const pw.TextStyle(color: PdfColors.white)),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(h.objectsDetected.join(', '), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  pw.Widget _buildReflectionsList(List<Reflection> reflections) {
    return pw.Column(
      children: reflections.map((r) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue.shade(0.5)),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(DateFormat('MMM d, yyyy').format(r.date), style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text(r.text, maxLines: 2, overflow: pw.TextOverflow.clip),
          ],
        ),
      )).toList(),
    );
  }

  String _formatHazardNarrative(Hazard h, bool bilingual) {
    final filipino = bilingual ? '\n\nFilipino: Naitala ang hazard na may antas ng banta na ${h.threatLevel}%. Mga bagay na nakita: ${h.objectsDetected.join(", ")}.' : '';
    return 'On ${DateFormat('MMMM d, yyyy').format(h.date)}, a hazard was detected with threat level ${h.threatLevel}%. Objects detected: ${h.objectsDetected.join(", ")}. Response: ${h.response}.$filipino';
  }

  String _formatReflectionNarrative(Reflection r, bool bilingual) {
    final filipino = bilingual ? '\n\nFilipino: ${r.text}' : '';
    return '${DateFormat('MMMM d, yyyy').format(r.date)}: ${r.text}$filipino';
  }

  String _formatLessonNarrative(Lesson l, bool bilingual) {
    final filipino = bilingual ? '\n\nFilipino: ${l.content}' : '';
    return '${DateFormat('MMMM d, yyyy').format(l.date)} - ${l.title}: ${l.content}$filipino';
  }

  pw.Widget _buildHazardItem(Hazard h, bool bilingual) {
    return pw.Paragraph(text: _formatHazardNarrative(h, bilingual));
  }

  pw.Widget _buildReflectionItem(Reflection r, bool bilingual) {
    return pw.Paragraph(text: _formatReflectionNarrative(r, bilingual));
  }

  pw.Widget _buildLessonItem(Lesson l, bool bilingual) {
    return pw.Paragraph(text: _formatLessonNarrative(l, bilingual));
  }

  Future<File> _savePdf(pw.Document pdf, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> exportToCSV(
    List<Hazard> hazards,
    List<Reflection> reflections,
    List<Lesson> lessons,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/lora_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    final buffer = StringBuffer();
    buffer.writeln('Type,Date,Content,Tags,Threat Level,Approved');
    
    for (var h in hazards) {
      buffer.writeln('Hazard,${h.date.toIso8601String()},"${h.response}","${h.objectsDetected.join(", ")}",${h.threatLevel},');
    }
    
    for (var r in reflections) {
      buffer.writeln('Reflection,${r.date.toIso8601String()},"${r.text.replaceAll('"', '""')}","${r.tags.join(", ")}",,${r.approved}');
    }
    
    for (var l in lessons) {
      buffer.writeln('Lesson,${l.date.toIso8601String()},"${l.title} - ${l.content.replaceAll('"', '""')}","${l.tags.join(", ")}",,${l.approved}');
    }
    
    await file.writeAsString(buffer.toString());
    return file;
  }
}
