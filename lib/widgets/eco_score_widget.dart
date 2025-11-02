import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class EcoScoreWidget extends StatelessWidget {
  final int score;

  const EcoScoreWidget({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Helpers.getScoreColor(score);
    final label = Helpers.getScoreText(score);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 8,
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Eco Score: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Text(
            'Lower carbon consumption = higher score',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
