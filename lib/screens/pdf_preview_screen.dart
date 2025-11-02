import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/bill_report.dart';
import '../data/models/eco_suggestion.dart';
import '../services/pdf_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class PDFPreviewScreen extends StatefulWidget {
  final BillReport report;
  final List<EcoSuggestion> suggestions;

  const PDFPreviewScreen({
    Key? key,
    required this.report,
    required this.suggestions,
  }) : super(key: key);

  @override
  State<PDFPreviewScreen> createState() => _PDFPreviewScreenState();
}

class _PDFPreviewScreenState extends State<PDFPreviewScreen> {
  final PDFService _pdfService = PDFService();
  File? _pdfFile;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generatePDF();
  }

  Future<void> _generatePDF() async {
    setState(() => _isGenerating = true);

    try {
      final pdfFile = await _pdfService.generateBillPDF(
        widget.report,
        widget.suggestions,
      );

      setState(() {
        _pdfFile = pdfFile;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error generating PDF: $e',
          isError: true,
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        backgroundColor: AppConstants.primaryGreen,
        actions: [
          if (_pdfFile != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
              onPressed: _sharePDF,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Save PDF',
              onPressed: _savePDF,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print PDF',
              onPressed: _printPDF,
            ),
          ],
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Generating PDF...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we create your report',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _pdfFile != null
              ? PdfPreview(
                  build: (format) => _pdfFile!.readAsBytes(),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  pdfFileName:
                      'GreenBill_Report_${widget.report.id.substring(0, 8)}.pdf',
                  actions: [
                    PdfPreviewAction(
                      icon: const Icon(Icons.save_alt),
                      onPressed: (context, build, pageFormat) => _savePDF(),
                    ),
                  ],
                )
              : const Center(
                  child: Text('Failed to generate PDF'),
                ),
    );
  }

  Future<void> _sharePDF() async {
    if (_pdfFile == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        text: 'My Carbon Footprint Report from GreenBill\n'
            'Total CO₂: ${Helpers.formatCarbon(widget.report.totalCarbonFootprint)}\n'
            'Eco Score: ${widget.report.ecoScore}/100',
        subject: 'GreenBill Carbon Footprint Report',
      );

      if (mounted) {
        Helpers.showSnackBar(context, 'PDF shared successfully!');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error sharing PDF: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _savePDF() async {
    if (_pdfFile == null) return;

    try {
      Helpers.showSnackBar(
        context,
        'PDF saved to: ${_pdfFile!.path}',
      );
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving PDF: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _printPDF() async {
    if (_pdfFile == null) return;

    try {
      final pdfBytes = await _pdfFile!.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error printing PDF: $e',
          isError: true,
        );
      }
    }
  }
}
