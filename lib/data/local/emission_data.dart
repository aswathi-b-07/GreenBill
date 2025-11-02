// This file can be used for additional cached data or constants
class EmissionData {
  static const Map<String, double> defaultEmissionFactors = {
    'petrol': 2.27193,
    'diesel': 2.6444,
    'rice': 2.28,
    'wheat': 0.87,
    'milk': 1.6,
    'plastic_bag': 0.1,
  };

  static const Map<String, String> categoryColors = {
    'fuel': '#FF6B35',
    'food': '#4CAF50',
    'packaging': '#2196F3',
  };

  static const Map<String, String> categoryIcons = {
    'fuel': 'local_gas_station',
    'food': 'restaurant',
    'packaging': 'shopping_bag',
  };
}
