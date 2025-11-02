import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../data/models/bill_item.dart';
import 'results_screen.dart';
import '../utils/ocr_test_helper.dart';

class DebugOCRScreen extends StatefulWidget {
  final XFile imageFile;
  final String billType;

  const DebugOCRScreen({
    Key? key,
    required this.imageFile,
    required this.billType,
  }) : super(key: key);

  @override
  State<DebugOCRScreen> createState() => _DebugOCRScreenState();
}

class _DebugOCRScreenState extends State<DebugOCRScreen> {
  final OCRService _ocrService = OCRService();
  String _extractedText = '';
  bool _isProcessing = false;
  List<Map<String, dynamic>> _parsedItems = [];

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);

    try {
      // Extract text from image
      final extractedText = await _ocrService.extractTextFromImage(widget.imageFile);
      setState(() => _extractedText = extractedText);

      // Parse the extracted text
      final parsedData = await _ocrService.parseBillText(extractedText, widget.billType);
      
      setState(() {
        _parsedItems = parsedData.items.map((item) => {
          'name': item.name,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'total': item.total,
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error processing image: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Debug'),
        backgroundColor: AppConstants.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _processImage,
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extracted Text:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _extractedText.isEmpty ? 'No text extracted' : _extractedText,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Parsed Items:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_parsedItems.isEmpty)
                    const Text('No items parsed')
                  else
                    ..._parsedItems.map((item) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(item['name']),
                        subtitle: Text(
                          'Qty: ${item['quantity']} | Price: ₹${item['unitPrice'].toStringAsFixed(2)} | Total: ₹${item['total'].toStringAsFixed(2)}',
                        ),
                      ),
                    )),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _parsedItems.isNotEmpty
                              ? () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultsScreen(
                                        billItems: _parsedItems.map((item) => BillItem(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          name: item['name'],
                                          quantity: item['quantity'],
                                          unitPrice: item['unitPrice'],
                                          total: item['total'],
                                        )).toList(),
                                        billType: widget.billType,
                                        totalAmount: _parsedItems.fold<double>(0, (sum, item) => sum + item['total']),
                                        date: DateTime.now(),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Continue to Results'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await OCRTestHelper.testWithRealOCR(_extractedText, widget.billType);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Test Parsing'),
                        ),
                      ),
                    ],
                  ),
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
