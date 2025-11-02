import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/models/eco_suggestion.dart';

class SuggestionService {
  static final SuggestionService _instance = SuggestionService._internal();
  factory SuggestionService() => _instance;
  SuggestionService._internal();

  List<EcoSuggestion> _suggestions = [];
  bool _isLoaded = false;

  Future<void> loadSuggestions() async {
    if (_isLoaded) return;

    try {
      final data = await rootBundle.loadString('assets/data/eco_suggestions.json');
      final json = jsonDecode(data);
      
      _suggestions = (json['suggestions'] as List)
          .map((s) => EcoSuggestion.fromJson(s))
          .toList();
      
      _isLoaded = true;
    } catch (e) {
      print('Error loading suggestions: $e');
    }
  }

  List<EcoSuggestion> getSuggestionsForReport(Map<String, double> categoryBreakdown) {
    List<EcoSuggestion> relevant = [];
    
    // Sort categories by emissions (highest first)
    var sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Get suggestions for top 3 categories
    for (var entry in sortedCategories.take(3)) {
      if (entry.value > 0) {
        var categorySuggestions = _suggestions
            .where((s) => s.category == entry.key)
            .toList();
        
        if (categorySuggestions.isNotEmpty) {
          relevant.add(categorySuggestions.first);
        }
      }
    }
    
    // Ensure at least 2 suggestions
    if (relevant.length < 2 && _suggestions.isNotEmpty) {
      for (var suggestion in _suggestions) {
        if (!relevant.contains(suggestion)) {
          relevant.add(suggestion);
          if (relevant.length >= 3) break;
        }
      }
    }
    
    return relevant;
  }

  Future<List<EcoSuggestion>> getSuggestions(List<dynamic> billItems) async {
    List<EcoSuggestion> relevantSuggestions = [];
    
    // Analyze bill items to provide specific suggestions
    for (var item in billItems) {
      final itemName = item.name.toLowerCase();
      final category = item.category?.toLowerCase();
      
      // Fuel-specific suggestions
      if (category == 'fuel' || itemName.contains('petrol') || itemName.contains('diesel')) {
        relevantSuggestions.addAll(_getFuelSuggestions(item));
      }
      
      // Food-specific suggestions
      else if (category == 'food' || _isFoodItem(itemName)) {
        relevantSuggestions.addAll(_getFoodSuggestions(item));
      }
      
      // Packaging-specific suggestions
      else if (category == 'packaging' || _isPackagingItem(itemName)) {
        relevantSuggestions.addAll(_getPackagingSuggestions(item));
      }
    }
    
    // Remove duplicates and limit to 5 suggestions
    final uniqueSuggestions = <String, EcoSuggestion>{};
    for (var suggestion in relevantSuggestions) {
      uniqueSuggestions[suggestion.title] = suggestion;
    }
    
    // If no specific suggestions found, return general ones
    if (uniqueSuggestions.isEmpty) {
      return _suggestions.take(3).toList();
    }
    
    return uniqueSuggestions.values.take(5).toList();
  }
  
  List<EcoSuggestion> _getFuelSuggestions(dynamic item) {
    return [
      EcoSuggestion(
        title: 'Use Public Transport',
        description: 'Consider using public transport or carpooling to reduce fuel consumption by up to 50%.',
        category: 'fuel',
        potentialSavings: 50.0,
      ),
      EcoSuggestion(
        title: 'Drive Efficiently',
        description: 'Maintain steady speed, avoid rapid acceleration, and keep tires properly inflated to improve fuel efficiency.',
        category: 'fuel',
        potentialSavings: 25.0,
      ),
      EcoSuggestion(
        title: 'Consider Electric Vehicle',
        description: 'Electric vehicles can reduce your carbon footprint by up to 70% compared to petrol/diesel cars.',
        category: 'fuel',
        potentialSavings: 70.0,
      ),
    ];
  }
  
  List<EcoSuggestion> _getFoodSuggestions(dynamic item) {
    return [
      EcoSuggestion(
        title: 'Choose Local Produce',
        description: 'Buy locally grown fruits and vegetables to reduce transportation emissions by up to 30%.',
        category: 'food',
        potentialSavings: 30.0,
      ),
      EcoSuggestion(
        title: 'Reduce Meat Consumption',
        description: 'Consider plant-based alternatives or reduce meat portions to lower your carbon footprint significantly.',
        category: 'food',
        potentialSavings: 60.0,
      ),
      EcoSuggestion(
        title: 'Avoid Food Waste',
        description: 'Plan meals and store food properly to reduce waste and save money while helping the environment.',
        category: 'food',
        potentialSavings: 40.0,
      ),
    ];
  }
  
  List<EcoSuggestion> _getPackagingSuggestions(dynamic item) {
    return [
      EcoSuggestion(
        title: 'Bring Reusable Bags',
        description: 'Use cloth or reusable bags instead of plastic bags to reduce packaging waste.',
        category: 'packaging',
        potentialSavings: 35.0,
      ),
      EcoSuggestion(
        title: 'Choose Minimal Packaging',
        description: 'Opt for products with less packaging or bulk items to reduce waste.',
        category: 'packaging',
        potentialSavings: 25.0,
      ),
      EcoSuggestion(
        title: 'Recycle Properly',
        description: 'Ensure proper recycling of packaging materials to give them a second life.',
        category: 'packaging',
        potentialSavings: 20.0,
      ),
    ];
  }
  
  bool _isFoodItem(String itemName) {
    final foodKeywords = [
      'rice', 'wheat', 'bread', 'milk', 'cheese', 'yogurt', 'meat', 'chicken', 'fish',
      'vegetable', 'fruit', 'apple', 'banana', 'tomato', 'onion', 'potato', 'carrot',
      'cereal', 'pasta', 'noodles', 'snack', 'chips', 'biscuit', 'cookie'
    ];
    return foodKeywords.any((keyword) => itemName.contains(keyword));
  }
  
  bool _isPackagingItem(String itemName) {
    final packagingKeywords = [
      'bag', 'bottle', 'can', 'box', 'container', 'wrapper', 'packaging', 'plastic',
      'paper', 'cardboard', 'tin', 'jar', 'tube', 'pouch'
    ];
    return packagingKeywords.any((keyword) => itemName.contains(keyword));
  }

  List<EcoSuggestion> getAllSuggestions() {
    return _suggestions;
  }
}
