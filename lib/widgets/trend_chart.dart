import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/bill_report.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TrendChart extends StatelessWidget {
  final List<BillReport> reports;

  const TrendChart({Key? key, required this.reports}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(child: Text("No data for chart"));
    }

    final List<FlSpot> spots = [];
    reports.asMap().forEach((index, report) {
      spots.add(
        FlSpot(index.toDouble(), report.totalCarbonFootprint),
      );
    });

    final double maxY =
        reports.map((r) => r.totalCarbonFootprint).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carbon Footprint Trend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.2,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(0)}'),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final day = reports[value.toInt()].timestamp.day;
                        return Text('$day');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [AppConstants.primaryGreen, AppConstants.lightGreen],
                    ),
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, color: AppConstants.lightGreen.withOpacity(0.1)),
                    dotData: FlDotData(show: true),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
