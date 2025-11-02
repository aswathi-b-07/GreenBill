class EcoSuggestion {
  final String title;
  final String description;
  final String category;
  final double potentialSavings;

  EcoSuggestion({
    required this.title,
    required this.description,
    required this.category,
    required this.potentialSavings,
  });

  factory EcoSuggestion.fromJson(Map<String, dynamic> json) {
    return EcoSuggestion(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      potentialSavings: (json['potentialSavings'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'potentialSavings': potentialSavings,
    };
  }
}
