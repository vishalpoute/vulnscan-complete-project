import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vulnscan/data/models/vulnerability_model.dart';

class PdfExportService {
  /// Generate and save PDF report
  /// Returns the file path if successful, null otherwise
  static Future<String?> exportReport({
    required ScanReport report,
    required String userTier, // 'free', 'pro', 'enterprise'
  }) async {
    try {
      final pdf = pw.Document();

      // Sort vulnerabilities by severity
      final sortedVulns = _sortBySeverity(report.vulnerabilities);

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildHeader(report),
            pw.SizedBox(height: 20),
            _buildSummary(report, userTier),
            pw.SizedBox(height: 30),
            if (sortedVulns.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No vulnerabilities found',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              )
            else
              ..._buildVulnerabilityList(sortedVulns, userTier),
          ],
        ),
      );

      // Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();
      final fileName = 'VulnScan_Report_${report.scanId}.pdf';
      final filePath = '${downloadsDir.path}/$fileName';

      // Save PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      return null;
    }
  }

  static pw.Widget _buildHeader(ScanReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VulnScan Security Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          report.repositoryName,
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(ScanReport report, String userTier) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Repository:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(report.repositoryUrl, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Scan Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(report.scanDate),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Vulnerabilities', '${report.totalVulnerabilities}'),
              _buildSummaryItem('Critical', '${report.criticalCount}', isRed: true),
              _buildSummaryItem('High', '${report.highCount}', isOrange: true),
              _buildSummaryItem('Medium', '${report.mediumCount}', isYellow: true),
            ],
          ),
          if (report.scanDuration != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text(
                'Scan Duration: ${report.scanDuration!.inMinutes}m ${report.scanDuration!.inSeconds % 60}s',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, {bool isRed = false, bool isOrange = false, bool isYellow = false}) {
    PdfColor color = PdfColors.black;
    if (isRed) color = PdfColors.red;
    if (isOrange) color = PdfColors.orange;
    if (isYellow) color = PdfColors.amber;

    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildVulnerabilityList(List<Vulnerability> vulnerabilities, String userTier) {
    final widgets = <pw.Widget>[
      pw.Text(
        'Vulnerabilities',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 12),
    ];

    bool isPro = userTier == 'pro' || userTier == 'enterprise';

    for (final vuln in vulnerabilities) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      vuln.title,
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(
                    vuln.severity.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _getSeverityColor(vuln.severity),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${vuln.filePath}:${vuln.lineNumber}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              if (vuln.cveId != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'CVE: ${vuln.cveId}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.grey100,
                child: pw.Text(
                  vuln.codeSnippet,
                  style: const pw.TextStyle(fontSize: 9),
                  maxLines: 3,
                ),
              ),
              if (isPro && vuln.aiExplanation != null) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Explanation: ${vuln.aiExplanation}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
              if (isPro && vuln.aiFixSuggestion != null) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Fix: ${vuln.aiFixSuggestion}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  static PdfColor _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return PdfColors.red;
      case 'high':
        return PdfColors.orange;
      case 'medium':
        return PdfColors.amber;
      case 'low':
        return PdfColors.yellow;
      default:
        return PdfColors.black;
    }
  }

  static List<Vulnerability> _sortBySeverity(List<Vulnerability> vulnerabilities) {
    const severityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
    final sorted = List<Vulnerability>.from(vulnerabilities);
    sorted.sort((a, b) {
      final aOrder = severityOrder[a.severity] ?? 4;
      final bOrder = severityOrder[b.severity] ?? 4;
      return aOrder.compareTo(bOrder);
    });
    return sorted;
  }

  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isWindows) {
      final downloadsPath = Platform.environment['USERPROFILE'];
      return Directory('$downloadsPath\\Downloads');
    } else if (Platform.isMacOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      return Directory('${appDocDir.path}/Downloads');
    } else if (Platform.isLinux) {
      return Directory('${Platform.environment['HOME']}/Downloads');
    }
    throw UnsupportedError('Unsupported platform');
  }
}
