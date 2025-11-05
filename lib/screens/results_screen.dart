import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/bill_item.dart';
import '../data/models/bill_report.dart';
import '../data/models/eco_suggestion.dart';
import '../data/repositories/bill_repository.dart';
import '../services/categorization_service.dart';
import '../services/suggestion_service.dart';
import '../services/pdf_service.dart';
import '../services/auth_service.dart';
import '../widgets/category_chart.dart';
import '../widgets/eco_score_widget.dart';
import '../widgets/emission_breakdown.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class ResultsScreen extends StatefulWidget {
  final List<BillItem> billItems;
  final String billType;
  final double totalAmount;
  final DateTime date;

  const ResultsScreen({
    Key? key,
    required this.billItems,
    required this.billType,
    required this.totalAmount,
    required this.date,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late BillReport _report;
  List<EcoSuggestion> _suggestions = [];
  bool _isSaving = false;

  final CategorizationService _categorizationService = CategorizationService();
  final SuggestionService _suggestionService = SuggestionService();
  final BillRepository _billRepository = BillRepository();
  final PDFService _pdfService = PDFService();

  @override
  void initState() {
    super.initState();
    _processItems();
  }

  Future<void> _processItems() async {
    // Calculate carbon footprint and categorize items
    for (var item in widget.billItems) {
      // First, categorize the item
      final category = await _categorizationService.categorizeItem(item.name);
      item.category = category;
      
      // Determine item type and calculate emissions accordingly
      if (category == 'fuel' || widget.billType == AppConstants.billTypePetrol) {
        // For fuel items
        item.unit = 'L';
        item.carbonFootprint = await _categorizationService.calculateFuelEmissions(
          item.quantity,
          category,
        );
      } else if (category == 'packaging') {
        // For packaging items
        item.unit = 'kg';
        item.carbonFootprint = await _categorizationService.calculatePackagingEmissions(
          item.quantity,
          category,
        );
      } else {
        // For food items (meat, dairy, fruits, vegetables, grains, other)
        item.unit = 'kg';
        item.carbonFootprint = await _categorizationService.calculateFoodEmissions(
          item.quantity,
          category,
        );
      }
    }

    setState(() {});

    // Generate suggestions based on items
    _suggestions = await _suggestionService.getSuggestions(widget.billItems);

    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Set the current user in the repository
    _billRepository.setCurrentUser(currentUser.id);

    // Create bill report
    _report = BillReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.id, // Associate with current user
      billType: widget.billType,
      timestamp: DateTime.now(), // Use current date instead of parsed date
      items: widget.billItems,
      totalAmount: widget.totalAmount,
      totalCarbonFootprint: widget.billItems.fold<double>(
        0,
        (sum, item) => sum + (item.carbonFootprint ?? 0),
      ),
      categoryBreakdown: _categorizationService.calculateCategoryBreakdown(widget.billItems),
      ecoScore: _categorizationService.calculateEcoScore(
        widget.billItems.fold<double>(0, (sum, item) => sum + (item.carbonFootprint ?? 0)),
        widget.billType,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveBill() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Verify user is logged in
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Verify report is ready
      if (_report == null) {
        throw Exception('Report not ready yet');
      }

      // Double check userId is set
      if (_report.userId != currentUser.id) {
        _report = BillReport(
          id: _report.id,
          userId: currentUser.id,
          billType: _report.billType,
          timestamp: _report.timestamp,
          items: _report.items,
          totalCarbonFootprint: _report.totalCarbonFootprint,
          totalAmount: _report.totalAmount,
          categoryBreakdown: _report.categoryBreakdown,
          ecoScore: _report.ecoScore,
          imagePath: _report.imagePath,
        );
      }

      print('Saving bill report: ${_report.toString()}');

      // Save bill report to database
      await _billRepository.saveBillReport(_report);

      // Generate and save PDF
      final pdfFile = await _pdfService.generateBillPDF(_report, _suggestions);

      if (mounted) {
        // Show success message
        Helpers.showSnackBar(
          context,
          'Bill saved successfully!',
        );

        // Share PDF
        if (pdfFile != null) {
          await Share.shareXFiles(
            [XFile(pdfFile.path)],
            text: 'Carbon footprint report for ${widget.billType}',
          );
        }

        // Navigate back to home
        if (mounted) {
          Navigator.popUntil(
            context,
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error saving bill: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildCarbonFootprintSummary() {
    final totalCarbon = widget.billItems.fold<double>(
      0,
      (sum, item) => sum + (item.carbonFootprint ?? 0),
    );
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carbon Footprint Calculation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.billItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} (${item.quantity} ${item.unit})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${Helpers.formatCarbon(item.carbonFootprint ?? 0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.fuelColor,
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Carbon Footprint:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Helpers.formatCarbon(totalCarbon),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.fuelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Eco Score: ${_categorizationService.calculateEcoScore(totalCarbon, widget.billType)}/100',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Analysis'),
        backgroundColor: AppConstants.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.billItems.isNotEmpty) ...[
              EcoScoreWidget(
                score: _categorizationService.calculateEcoScore(
                  widget.billItems.fold<double>(0, (sum, item) => sum + (item.carbonFootprint ?? 0)),
                  widget.billType,
                ),
              ),
              const SizedBox(height: 24),
              CategoryChart(categoryBreakdown: _categorizationService.calculateCategoryBreakdown(widget.billItems)),
              const SizedBox(height: 24),
              _buildCarbonFootprintSummary(),
              const SizedBox(height: 24),
              EmissionBreakdown(items: widget.billItems),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Eco-friendly Suggestions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._suggestions.map((suggestion) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.eco,
                      color: AppConstants.primaryGreen,
                    ),
                    title: Text(suggestion.title),
                    subtitle: Text(suggestion.description),
                  ),
                )),
              ],
            ] else
              const Center(
                child: Text('No items found in the bill'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveBill,
        label: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save & Share'),
        icon: _isSaving ? null : const Icon(Icons.save),
        backgroundColor: AppConstants.primaryGreen,
      ),
    );
  }
}