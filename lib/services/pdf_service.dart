import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../data/models/bill_report.dart';
import '../data/models/eco_suggestion.dart';

class PDFService {
  Future<File?> generateBillPDF(
    BillReport report,
    List<EcoSuggestion> suggestions,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              _buildHeader(report),
              pw.SizedBox(height: 20),
              _buildSummary(report),
              pw.SizedBox(height: 20),
              _buildItemsTable(report),
              pw.SizedBox(height: 20),
              _buildCategoryBreakdown(report),
              pw.SizedBox(height: 20),
              _buildEcoSuggestions(suggestions),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/greenbill_${report.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e, stackTrace) {
      print('Error generating PDF: $e');
      print(stackTrace);
      return null;
    }
  }

  pw.Widget _buildHeader(BillReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      color: PdfColors.green700,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GreenBill Carbon Footprint Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(report.timestamp)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
          pw.Text(
            'Bill Type: ${report.billType == 'petrol' ? 'Petrol/Fuel' : 'Supermarket'}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(BillReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Carbon Footprint',
            '${report.totalCarbonFootprint.toStringAsFixed(2)} kg CO₂',
            PdfColors.red,
          ),
          _buildSummaryItem(
            'Eco Score',
            '${report.ecoScore}/100',
            _getScoreColor(report.ecoScore),
          ),
          _buildSummaryItem(
            'Total Items',
            '${report.items.length}',
            PdfColors.blue,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(BillReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Items Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Item', isHeader: true),
                _buildTableCell('Quantity', isHeader: true),
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('CO₂ (kg)', isHeader: true),
              ],
            ),
            ...report.items.map((item) {
              return pw.TableRow(
                children: [
                  _buildTableCell(item.name),
                  _buildTableCell('${item.quantity.toStringAsFixed(2)} ${item.unit}'),
                  _buildTableCell(item.category ?? 'Unknown'),
                  _buildTableCell((item.carbonFootprint ?? 0).toStringAsFixed(3)),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildCategoryBreakdown(BillReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category-wise Emissions',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...report.categoryBreakdown.entries.map((entry) {
          if (entry.value > 0) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${entry.key.toUpperCase()}:', 
                    style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('${entry.value.toStringAsFixed(2)} kg CO₂',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          }
          return pw.SizedBox();
        }).toList(),
      ],
    );
  }

  pw.Widget _buildEcoSuggestions(List<EcoSuggestion> suggestions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Eco-Friendly Suggestions',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...suggestions.map((suggestion) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ${suggestion.title}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  suggestion.description,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Potential savings: ${suggestion.potentialSavings.toStringAsFixed(1)} kg CO₂',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.green900),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.Text(
            'Generated by GreenBill - Track your carbon footprint',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Making environmental impact visible and actionable',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  PdfColor _getScoreColor(int score) {
    if (score >= 80) return PdfColors.green;
    if (score >= 60) return PdfColors.orange;
    return PdfColors.red;
  }
}
