import 'package:flutter/material.dart';
import '../data/models/bill_item.dart';
import '../utils/helpers.dart';

class EmissionBreakdown extends StatelessWidget {
  final List<BillItem> items;
  final double? totalCarbon;

  const EmissionBreakdown({Key? key, required this.items, this.totalCarbon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final grouped = <String, double>{};
    for (var item in items) {
      if (item.category != null && item.carbonFootprint != null) {
        grouped[item.category!] = (grouped[item.category!] ?? 0) + item.carbonFootprint!;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emission Breakdown per Item',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...items.where((item) => item.category != null && item.carbonFootprint != null).map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Helpers.getCategoryColor(item.category!).withOpacity(0.2),
                  child: Icon(
                    Helpers.getCategoryIcon(item.category!),
                    color: Helpers.getCategoryColor(item.category!),
                  ),
                ),
                title: Text(item.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity} ${item.unit} | ${Helpers.formatCarbon(item.carbonFootprint!)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    if (item.carbonFootprint != null && item.quantity > 0)
                      Text(
                        'Factor: ${(item.carbonFootprint! / item.quantity).toStringAsFixed(2)} kg CO₂/${item.unit}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                  ],
                ),
                trailing: Text(
                  item.category!.capitalize(),
                  style: TextStyle(
                    color: Helpers.getCategoryColor(item.category!),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

extension Capitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
