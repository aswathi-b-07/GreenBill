import 'package:flutter/material.dart';
import '../data/models/bill_report.dart';
import '../data/models/eco_suggestion.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/emission_breakdown.dart';
import '../services/suggestion_service.dart';

class BillDetailsScreen extends StatefulWidget {
  final BillReport report;

  const BillDetailsScreen({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final SuggestionService _suggestionService = SuggestionService();
  List<EcoSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    await _suggestionService.loadSuggestions();
    final suggestions = await _suggestionService.getSuggestions(widget.report.items);
    setState(() {
      _suggestions = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Details - ${Helpers.formatDate(widget.report.timestamp)}'),
        backgroundColor: AppConstants.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              Helpers.showSnackBar(context, 'Share functionality coming soon!');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBillSummary(),
            const SizedBox(height: 20),
            _buildItemsList(),
            const SizedBox(height: 20),
            _buildEmissionBreakdown(),
            const SizedBox(height: 20),
            _buildEcoSuggestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.report.billType == AppConstants.billTypePetrol
                      ? Icons.local_gas_station
                      : Icons.shopping_cart,
                  color: widget.report.billType == AppConstants.billTypePetrol
                      ? AppConstants.fuelColor
                      : AppConstants.foodColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.billType == AppConstants.billTypePetrol
                            ? 'Fuel Bill'
                            : 'Grocery Bill',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Helpers.formatDateTime(widget.report.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Helpers.getScoreColor(widget.report.ecoScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.report.ecoScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Amount',
                  '₹${widget.report.totalAmount.toStringAsFixed(2)}',
                  AppConstants.primaryGreen,
                ),
                _buildSummaryItem(
                  'Carbon Footprint',
                  Helpers.formatCarbon(widget.report.totalCarbonFootprint),
                  AppConstants.fuelColor,
                ),
                _buildSummaryItem(
                  'Items',
                  '${widget.report.items.length}',
                  AppConstants.foodColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.report.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Helpers.getCategoryColor(item.category ?? 'other').withOpacity(0.2),
                  child: Icon(
                    Helpers.getCategoryIcon(item.category ?? 'other'),
                    color: Helpers.getCategoryColor(item.category ?? 'other'),
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${item.quantity.toStringAsFixed(2)} ${item.unit} • ₹${item.unitPrice.toStringAsFixed(2)}/unit',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      Helpers.formatCarbon(item.carbonFootprint ?? 0),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmissionBreakdown() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emission Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            EmissionBreakdown(
              items: widget.report.items,
              totalCarbon: widget.report.totalCarbonFootprint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoSuggestions() {
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eco Suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._suggestions.map((suggestion) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConstants.primaryGreen.withOpacity(0.2),
                  child: const Icon(
                    Icons.eco,
                    color: AppConstants.primaryGreen,
                  ),
                ),
                title: Text(
                  suggestion.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(suggestion.description),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${suggestion.potentialSavings.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppConstants.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
