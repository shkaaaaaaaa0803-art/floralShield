import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/diagnosis_model.dart';

class PdfReportService {
  static final PdfColor _forestGreen = PdfColor.fromHex('#1B4D3E');
  static final PdfColor _lightGrey = PdfColor.fromHex('#F2F2F2');
  static final PdfColor _redAccent = PdfColor.fromHex('#C0392B');
  static final PdfColor _greenAccent = PdfColor.fromHex('#27AE60');

  static Future<void> generateAndShare({
    required DiagnosisModel diagnosis,
    File? imageFile,
  }) async {
    final doc = pw.Document();

    pw.MemoryImage? plantImage;
    if (imageFile != null && await imageFile.exists()) {
      final bytes = await imageFile.readAsBytes();
      plantImage = pw.MemoryImage(bytes);
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              if (plantImage != null) ...[
                pw.Center(
                  child: pw.Container(
                    height: 180,
                    width: 180,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(plantImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              _buildSummarySection(diagnosis),
              pw.SizedBox(height: 16),
              if (!diagnosis.isHealthy) ...[
                if (diagnosis.symptoms.isNotEmpty)
                  _buildListSection('Symptoms', diagnosis.symptoms),
                if (diagnosis.treatment.isNotEmpty)
                  _buildListSection('Treatment', diagnosis.treatment),
                if (diagnosis.prevention.isNotEmpty)
                  _buildListSection('Prevention', diagnosis.prevention),
              ] else ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _lightGrey,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'This plant appears healthy. No disease was detected at the time of scanning.',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'PlantIQ_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'PlantIQ',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: _forestGreen,
              ),
            ),
            pw.Text(
              _formatDate(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          'Plant Diagnosis Report',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _forestGreen, thickness: 1.5),
      ],
    );
  }

  static pw.Widget _buildSummarySection(DiagnosisModel diagnosis) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                diagnosis.plantName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: diagnosis.isHealthy ? _greenAccent : _redAccent,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  diagnosis.isHealthy ? 'HEALTHY' : 'DISEASED',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          if (!diagnosis.isHealthy) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Disease: ${diagnosis.diseaseName}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _redAccent),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Text('Confidence: ${diagnosis.confidencePercent}%   ', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Severity: ${diagnosis.severityPercent}%', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildListSection(String title, List<String> items) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _forestGreen),
          ),
          pw.SizedBox(height: 6),
          ...items.map(
                (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
                  pw.Expanded(child: pw.Text(item, style: const pw.TextStyle(fontSize: 11))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'This report is AI-generated using PlantIQ and is intended for reference only. '
              'It should not replace advice from a certified agricultural expert.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}