class EmissionFactor {
  final String id;
  final String name;
  final String category;
  final double emissionValue;
  final String unit;
  final String source;

  EmissionFactor({
    required this.id,
    required this.name,
    required this.category,
    required this.emissionValue,
    required this.unit,
    required this.source,
  });

  factory EmissionFactor.fromJson(Map<String, dynamic> json) {
    return EmissionFactor(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      emissionValue: (json['emissionValue'] as num).toDouble(),
      unit: json['unit'] as String,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'emissionValue': emissionValue,
      'unit': unit,
      'source': source,
    };
  }
}
