import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TimeRangeSelector extends StatelessWidget {
  final String selectedRange;
  final Function(String) onRangeSelected;

  const TimeRangeSelector({
    Key? key,
    required this.selectedRange,
    required this.onRangeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildRangeChip('1W', 'Last Week'),
            _buildRangeChip('1M', 'Last Month'),
            _buildRangeChip('3M', 'Last 3 Months'),
            _buildRangeChip('6M', 'Last 6 Months'),
            _buildRangeChip('1Y', 'Last Year'),
            _buildRangeChip('ALL', 'All Time'),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeChip(String value, String label) {
    final isSelected = selectedRange == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            onRangeSelected(value);
          }
        },
        selectedColor: AppConstants.primaryGreen.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppConstants.primaryGreen : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}