import 'package:flutter/material.dart';
import '../data/models/bill_report.dart';
import '../utils/helpers.dart';

class BillCard extends StatelessWidget {
  final BillReport report;
  final VoidCallback? onTap;

  const BillCard({Key? key, required this.report, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Helpers.getCategoryColor(report.billType).withOpacity(0.2),
                child: Icon(
                  report.billType == 'petrol' ? Icons.local_gas_station : Icons.shopping_cart,
                  color: Helpers.getCategoryColor(report.billType),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Helpers.formatCarbon(report.totalCarbonFootprint),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatDateTime(report.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Helpers.getScoreColor(report.ecoScore),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${report.ecoScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
