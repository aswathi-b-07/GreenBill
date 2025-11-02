import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/carbon_diary_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String carbonDiary = '/carbon-diary';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case carbonDiary:
        return MaterialPageRoute(builder: (_) => const CarbonDiaryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
