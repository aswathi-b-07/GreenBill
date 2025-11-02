import 'dart:convert';
import 'bill_item.dart';

class BillReport {
  final String id;
  final String billType;
  final DateTime timestamp;
  final List<BillItem> items;
  final double totalCarbonFootprint;
  final double totalAmount;
  final Map<String, double> categoryBreakdown;
  final int ecoScore;
  final String? imagePath;

  BillReport({
    required this.id,
    required this.billType,
    required this.timestamp,
    required this.items,
    required this.totalCarbonFootprint,
    required this.totalAmount,
    required this.categoryBreakdown,
    required this.ecoScore,
    this.imagePath,
  });

  factory BillReport.fromMap(Map<String, dynamic> map) {
    final itemsJson = map['items'] as String;
    final breakdownJson = map['categoryBreakdown'] as String;
    
    final itemsList = json.decode(itemsJson) as List<dynamic>;
    final breakdownMap = json.decode(breakdownJson) as Map<String, dynamic>;
    
    return BillReport(
      id: map['id'] as String,
      billType: map['billType'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      items: itemsList.map((item) => BillItem.fromMap(item)).toList(),
      totalCarbonFootprint: (map['totalCarbonFootprint'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      categoryBreakdown: breakdownMap.map((key, value) => MapEntry(key, (value as num).toDouble())),
      ecoScore: map['ecoScore'] as int,
      imagePath: map['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billType': billType,
      'timestamp': timestamp.toIso8601String(),
      'items': json.encode(items.map((item) => item.toMap()).toList()),
      'totalCarbonFootprint': totalCarbonFootprint,
      'totalAmount': totalAmount,
      'categoryBreakdown': json.encode(categoryBreakdown),
      'ecoScore': ecoScore,
      'imagePath': imagePath,
    };
  }

  @override
  String toString() {
    return 'BillReport{id: $id, billType: $billType, timestamp: $timestamp, items: $items, totalCarbonFootprint: $totalCarbonFootprint, totalAmount: $totalAmount}';
  }
}