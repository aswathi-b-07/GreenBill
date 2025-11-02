import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/emission_factor.dart';

class EmissionFactorsRepository {
  static final EmissionFactorsRepository _instance = EmissionFactorsRepository._internal();
  factory EmissionFactorsRepository() => _instance;
  EmissionFactorsRepository._internal();

  final Map<String, EmissionFactor> _emissionFactors = {};
  bool _isLoaded = false;

  Future<void> loadEmissionFactors() async {
    if (_isLoaded) return;

    try {
      await _loadFuelFactors();
      await _loadFoodFactors();
      await _loadPackagingFactors();
      _isLoaded = true;
    } catch (e) {
      print('Error loading emission factors: $e');
      throw Exception('Failed to load emission factors');
    }
  }

  Future<void> _loadFuelFactors() async {
    final fuelData = await rootBundle.loadString('assets/data/fuel_emission_factors.json');
    final fuelJson = json.decode(fuelData);
    fuelJson.forEach((key, value) {
      final factor = EmissionFactor(
        id: key,
        name: key.toUpperCase(),
        category: 'fuel',
        emissionValue: (value as num).toDouble(),
        unit: 'kg CO2/L',
        source: 'Default',
      );
      _emissionFactors[factor.id] = factor;
    });
  }

  Future<void> _loadFoodFactors() async {
    final foodData = await rootBundle.loadString('assets/data/food_emission_factors.json');
    final foodJson = json.decode(foodData);
    foodJson.forEach((key, value) {
      final factor = EmissionFactor(
        id: key,
        name: key.toUpperCase(),
        category: 'food',
        emissionValue: (value as num).toDouble(),
        unit: 'kg CO2/kg',
        source: 'Default',
      );
      _emissionFactors[factor.id] = factor;
    });
  }

  Future<void> _loadPackagingFactors() async {
    final packagingData = await rootBundle.loadString('assets/data/packaging_emission_factors.json');
    final packagingJson = json.decode(packagingData);
    packagingJson.forEach((key, value) {
      final factor = EmissionFactor(
        id: key,
        name: key.toUpperCase(),
        category: 'packaging',
        emissionValue: (value as num).toDouble(),
        unit: 'kg CO2/kg',
        source: 'Default',
      );
      _emissionFactors[factor.id] = factor;
    });
  }

  EmissionFactor? getEmissionFactor(String id) {
    return _emissionFactors[id];
  }

  List<EmissionFactor> searchByName(String name) {
    return _emissionFactors.values
        .where((factor) => factor.name.toLowerCase().contains(name.toLowerCase()))
        .toList();
  }

  List<EmissionFactor> getByCategory(String category) {
    return _emissionFactors.values
        .where((factor) => factor.category == category)
        .toList();
  }

  List<EmissionFactor> getAllFactors() {
    return _emissionFactors.values.toList();
  }

  double? getFoodEmissionFactor(String category) {
    final factors = getByCategory('food');
    for (var factor in factors) {
      if (factor.name.toLowerCase().contains(category.toLowerCase())) {
        return factor.emissionValue;
      }
    }
    return null;
  }

  double? getFuelEmissionFactor(String fuelType) {
    final factors = getByCategory('fuel');
    for (var factor in factors) {
      if (factor.name.toLowerCase().contains(fuelType.toLowerCase())) {
        return factor.emissionValue;
      }
    }
    return null;
  }

  double? getPackagingEmissionFactor(String category) {
    final factors = getByCategory('packaging');
    for (var factor in factors) {
      if (factor.name.toLowerCase().contains(category.toLowerCase())) {
        return factor.emissionValue;
      }
    }
    return null;
  }
}
