import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/carbon_diary_screen.dart';
import '../screens/bill_capture_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String carbonDiary = '/carbon-diary';
  static const String billCapture = '/bill-capture';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case carbonDiary:
        return MaterialPageRoute(builder: (_) => const CarbonDiaryScreen());
      case billCapture:
        return MaterialPageRoute(builder: (_) => const BillCaptureScreen());
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
