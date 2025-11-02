class BillItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;
  String unit;
  double? carbonFootprint;
  String? category;

  BillItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.unit = 'kg',
    this.carbonFootprint,
    this.category,
  });

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'kg',
      carbonFootprint: map['carbonFootprint'] != null ? (map['carbonFootprint'] as num).toDouble() : null,
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'unit': unit,
      'carbonFootprint': carbonFootprint,
      'category': category,
    };
  }

  BillItem copyWith({
    String? id,
    String? name,
    double? quantity,
    double? unitPrice,
    double? total,
    String? unit,
    double? carbonFootprint,
    String? category,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      unit: unit ?? this.unit,
      carbonFootprint: carbonFootprint ?? this.carbonFootprint,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'BillItem{id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, total: $total, unit: $unit, carbonFootprint: $carbonFootprint, category: $category}';
  }
}