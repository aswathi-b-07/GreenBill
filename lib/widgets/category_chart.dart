import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categoryBreakdown;

  const CategoryChart({Key? key, required this.categoryBreakdown}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = categoryBreakdown.values.fold<double>(0, (sum, value) => sum + value);

    if (total == 0) {
      return const Center(child: Text('No emissions to display'));
    }

    final sections = categoryBreakdown.entries.map((e) {
      final percent = (e.value / total) * 100;
      return PieChartSectionData(
        color: Helpers.getCategoryColor(e.key),
        value: e.value,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emissions by Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
              startDegreeOffset: -90,
              centerSpaceColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: categoryBreakdown.keys.map((category) {
            return Row(
              children: [
                Container(
                  height: 12,
                  width: 12,
                  color: Helpers.getCategoryColor(category),
                ),
                const SizedBox(width: 6),
                Text(category.capitalize()),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

extension StringCap on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
