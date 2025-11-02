import '../data/models/bill_item.dart';
import '../data/repositories/emission_factors_repository.dart';

class CategorizationService {
  final EmissionFactorsRepository _emissionRepository = EmissionFactorsRepository();

  Future<void> _loadEmissionFactors() async {
    await _emissionRepository.loadEmissionFactors();
  }

  Future<String> categorizeItem(String itemName) async {
    await _loadEmissionFactors();
    
    final lowerName = itemName.toLowerCase();
    
    // Check for fuel items first
    if (lowerName.contains('petrol') || lowerName.contains('gasoline') || 
        lowerName.contains('diesel') || lowerName.contains('lpg') ||
        lowerName.contains('fuel') || lowerName.contains('gas')) {
      return 'fuel';
    }
    
    // Check for packaging items
    if (lowerName.contains('bag') || lowerName.contains('bottle') ||
        lowerName.contains('pack') || lowerName.contains('container') ||
        lowerName.contains('wrapper') || lowerName.contains('plastic') ||
        lowerName.contains('paper') || lowerName.contains('cardboard') ||
        lowerName.contains('glass') || lowerName.contains('metal') ||
        lowerName.contains('tin') || lowerName.contains('can')) {
      return 'packaging';
    }
    
    // Check for food categories
    if (lowerName.contains('meat') || lowerName.contains('chicken') || 
        lowerName.contains('beef') || lowerName.contains('pork') ||
        lowerName.contains('lamb') || lowerName.contains('fish') ||
        lowerName.contains('sausage') || lowerName.contains('bacon')) {
      return 'meat';
    } else if (lowerName.contains('milk') || lowerName.contains('cheese') || 
               lowerName.contains('yogurt') || lowerName.contains('butter') ||
               lowerName.contains('cream') || lowerName.contains('ice cream')) {
      return 'dairy';
    } else if (lowerName.contains('rice') || lowerName.contains('wheat') || 
               lowerName.contains('bread') || lowerName.contains('pasta') ||
               lowerName.contains('flour') || lowerName.contains('cereal') ||
               lowerName.contains('oats') || lowerName.contains('quinoa')) {
      return 'grains';
    } else if (lowerName.contains('apple') || lowerName.contains('banana') || 
               lowerName.contains('orange') || lowerName.contains('mango') ||
               lowerName.contains('grapes') || lowerName.contains('strawberry') ||
               lowerName.contains('carrot') || lowerName.contains('tomato') ||
               lowerName.contains('onion') || lowerName.contains('potato') ||
               lowerName.contains('lettuce') || lowerName.contains('spinach')) {
      return 'fruits';
    } else if (lowerName.contains('vegetable') || lowerName.contains('veggie') ||
               lowerName.contains('broccoli') || lowerName.contains('cauliflower') ||
               lowerName.contains('cabbage') || lowerName.contains('pepper')) {
      return 'vegetables';
    }
    
    return 'other'; // Default food category
  }

  Future<double> calculateEmissions(double quantity, String category, String itemType) async {
    await _loadEmissionFactors();
    
    double factor = 2.0; // Default factor
    
    if (itemType == 'fuel') {
      factor = _emissionRepository.getFuelEmissionFactor(category.toLowerCase()) ?? 2.31;
    } else if (itemType == 'food') {
      factor = _emissionRepository.getFoodEmissionFactor(category.toLowerCase()) ?? 2.0;
    } else if (itemType == 'packaging') {
      factor = _emissionRepository.getPackagingEmissionFactor(category.toLowerCase()) ?? 2.0;
    }
    
    return quantity * factor;
  }

  Future<double> calculateFoodEmissions(double quantity, String category) async {
    return await calculateEmissions(quantity, category, 'food');
  }

  Future<double> calculateFuelEmissions(double liters, String fuelType) async {
    return await calculateEmissions(liters, fuelType, 'fuel');
  }

  Future<double> calculatePackagingEmissions(double quantity, String category) async {
    return await calculateEmissions(quantity, category, 'packaging');
  }

  Map<String, double> calculateCategoryBreakdown(List<BillItem> items) {
    Map<String, double> breakdown = {};
    
    for (var item in items) {
      if (item.category != null && item.carbonFootprint != null) {
        final category = item.category!;
        breakdown[category] = (breakdown[category] ?? 0) + item.carbonFootprint!;
      }
    }
    
    return breakdown;
  }

  int calculateEcoScore(double totalCarbon, String billType) {
    // More accurate scoring system based on carbon footprint
    if (billType == 'petrol') {
      // For fuel bills, higher carbon footprint = lower score
      if (totalCarbon < 2) return 95;      // Excellent: Very low fuel consumption
      if (totalCarbon < 5) return 85;     // Very Good: Low fuel consumption
      if (totalCarbon < 10) return 70;    // Good: Moderate fuel consumption
      if (totalCarbon < 20) return 50;    // Fair: High fuel consumption
      if (totalCarbon < 30) return 30;    // Poor: Very high fuel consumption
      return 15;                          // Very Poor: Extremely high fuel consumption
    } else {
      // For grocery bills, consider food type and packaging
      if (totalCarbon < 0.5) return 95;   // Excellent: Very low carbon food
      if (totalCarbon < 1.5) return 85;   // Very Good: Low carbon food
      if (totalCarbon < 3) return 70;     // Good: Moderate carbon food
      if (totalCarbon < 6) return 50;     // Fair: High carbon food
      if (totalCarbon < 10) return 30;    // Poor: Very high carbon food
      return 15;                          // Very Poor: Extremely high carbon food
    }
  }
}