import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'GreenBill';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Track Your Carbon Footprint';

  // Colors - Modern Green Theme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF69F0AE);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color backgroundGreen = Color(0xFFF1F8E9);
  static const Color accentGreen = Color(0xFF388E3C);
  static const Color deepGreen = Color(0xFF0D4F14);
  
  static const Color fuelColor = Color(0xFFFF5722);
  static const Color foodColor = Color(0xFF4CAF50);
  static const Color packagingColor = Color(0xFF2196F3);
  
  // Modern UI Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color shadowColor = Color(0x1A000000);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Text Styles - Modern Typography
  static const TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Eco Score Ranges
  static const int excellentScoreMin = 80;
  static const int goodScoreMin = 60;

  // Bill Types
  static const String billTypePetrol = 'petrol';
  static const String billTypeGrocery = 'grocery';
  static const String billTypeSupermarket = 'supermarket';

  // Category Names
  static const String categoryFuel = 'fuel';
  static const String categoryFood = 'food';
  static const String categoryPackaging = 'packaging';
}
