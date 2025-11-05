import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../data/models/bill_report.dart';

class CarbonInsightCard extends StatelessWidget {
  final List<BillReport> reports;

  const CarbonInsightCard({Key? key, required this.reports}) : super(key: key);

  Map<String, double> _calculateInsights() {
    if (reports.isEmpty) return {};

    // Calculate last month vs this month trend
    final now = DateTime.now();
    final thisMonth = reports.where((r) =>
        r.timestamp.year == now.year && r.timestamp.month == now.month);
    final lastMonth = reports.where((r) =>
        r.timestamp.year == now.year &&
        r.timestamp.month == now.month - 1);

    final thisMonthAvg = thisMonth.isEmpty
        ? 0.0
        : thisMonth.fold<double>(
                0, (sum, r) => sum + r.totalCarbonFootprint) /
            thisMonth.length;
    final lastMonthAvg = lastMonth.isEmpty
        ? 0.0
        : lastMonth.fold<double>(
                0, (sum, r) => sum + r.totalCarbonFootprint) /
            lastMonth.length;

    // Calculate by type breakdown
    final fuelTotal = reports
        .where((r) => r.billType == AppConstants.billTypePetrol)
        .fold<double>(0, (sum, r) => sum + r.totalCarbonFootprint);
    final groceryTotal = reports
        .where((r) => r.billType == AppConstants.billTypeGrocery)
        .fold<double>(0, (sum, r) => sum + r.totalCarbonFootprint);

    return {
      'monthlyChange': lastMonthAvg == 0
          ? 0
          : ((thisMonthAvg - lastMonthAvg) / lastMonthAvg) * 100,
      'fuelPercentage': reports.isEmpty
          ? 0
          : (fuelTotal / (fuelTotal + groceryTotal)) * 100,
      'groceryPercentage': reports.isEmpty
          ? 0
          : (groceryTotal / (fuelTotal + groceryTotal)) * 100,
    };
  }

  String _getInsightMessage(Map<String, double> insights) {
    final messages = <String>[];

    // Monthly change message
    if (insights['monthlyChange'] != 0) {
      messages.add(
          'Your carbon footprint has ${insights['monthlyChange']! > 0 ? 'increased' : 'decreased'} by ${insights['monthlyChange']!.abs().toStringAsFixed(1)}% compared to last month.');
    }

    // Category breakdown message
    if (insights['fuelPercentage']! > 60) {
      messages.add(
          'Fuel consumption makes up ${insights['fuelPercentage']!.toStringAsFixed(1)}% of your carbon footprint. Consider using public transport or carpooling when possible.');
    } else if (insights['groceryPercentage']! > 60) {
      messages.add(
          'Grocery purchases make up ${insights['groceryPercentage']!.toStringAsFixed(1)}% of your carbon footprint. Try choosing more local and seasonal products.');
    }

    if (messages.isEmpty) {
      return 'Keep tracking your carbon footprint to get personalized insights!';
    }

    return messages.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final insights = _calculateInsights();
    final message = _getInsightMessage(insights);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: AppConstants.primaryGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Carbon Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}