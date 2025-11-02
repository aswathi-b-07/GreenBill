import 'package:flutter/material.dart';
import '../services/categorization_service.dart';
import '../data/models/bill_item.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'results_screen.dart';

class OCRProcessingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> extractedItems;
  final String billType;
  final String imagePath;

  const OCRProcessingScreen({
    Key? key,
    required this.extractedItems,
    required this.billType,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<OCRProcessingScreen> createState() => _OCRProcessingScreenState();
}

class _OCRProcessingScreenState extends State<OCRProcessingScreen> {
  List<BillItem> _processedItems = [];
  bool _isProcessing = false;
  final CategorizationService _categorizationService = CategorizationService();

  @override
  void initState() {
    super.initState();
    _processItems();
  }

  Future<void> _processItems() async {
    setState(() => _isProcessing = true);

    try {
      List<BillItem> items = [];

      for (var itemData in widget.extractedItems) {
        final item = await _categorizationService.categorizeAndCalculate(itemData);
        items.add(item);
      }

      setState(() {
        _processedItems = items;
        _isProcessing = false;
      });

      // Auto-navigate after showing items briefly
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _navigateToResults();
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error processing items: $e',
          isError: true,
        );
        Navigator.pop(context);
      }
    }
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          items: _processedItems,
          billType: widget.billType,
          imagePath: widget.imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Items'),
        backgroundColor: AppConstants.primaryGreen,
        automaticallyImplyLeading: false,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Calculating carbon footprint...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _processedItems.length,
              itemBuilder: (context, index) {
                final item = _processedItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Helpers.getCategoryColor(item.category).withOpacity(0.2),
                      child: Icon(
                        Helpers.getCategoryIcon(item.category),
                        color: Helpers.getCategoryColor(item.category),
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.quantity} ${item.unit} • ${Helpers.formatCarbon(item.carbonFootprint)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        item.category,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Helpers.getCategoryColor(item.category).withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
