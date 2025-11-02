import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../data/models/bill_item.dart';
import '../services/categorization_service.dart';
import 'results_screen.dart';
import 'debug_ocr_screen.dart';

class ScanScreen extends StatefulWidget {
  final XFile imageFile;
  final String billType;

  const ScanScreen({
    Key? key,
    required this.imageFile,
    required this.billType,
  }) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final OCRService _ocrService = OCRService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    if (!mounted) return;
    
    setState(() => _isProcessing = true);

    try {
      // Extract ML Kit RecognizedText and parse it using layout-aware parser
      final recognized = await _ocrService.extractRecognizedText(widget.imageFile);
      BillData parsedData;
      if (recognized != null) {
        parsedData = await _ocrService.parseRecognizedText(recognized, widget.billType);
      } else {
        // Fallback: extract plain text and parse
        final plain = await _ocrService.extractTextFromImage(widget.imageFile);
        parsedData = await _ocrService.parseBillText(plain, widget.billType);
      }

      if (parsedData.items.isEmpty) {
        if (!mounted) return;
        Helpers.showSnackBar(
          context,
          'No items were detected in the image. Opening debug view to inspect OCR.',
          isError: true,
        );
      }
      
      if (!mounted) return;
      
      // Check if items were found
      if (parsedData.items.isEmpty) {
        // Show debug screen to help diagnose the issue
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DebugOCRScreen(
              imageFile: widget.imageFile,
              billType: widget.billType,
            ),
          ),
        );
        return;
      }
      
      // Navigate to results screen with the parsed data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            billItems: parsedData.items,
            billType: widget.billType,
            totalAmount: parsedData.total,
            date: parsedData.date ?? DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        'Error processing image: $e',
        isError: true,
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Bill'),
        backgroundColor: AppConstants.primaryGreen,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Processing your bill...\nThis may take a few moments',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}