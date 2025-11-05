import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/carbon_diary_screen.dart';
import '../screens/bill_capture_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  // Use '/home' so navigation calls like Navigator.pushReplacementNamed(context, '/home') succeed
  static const String home = '/home';
  static const String profile = '/profile';
  static const String carbonDiary = '/carbon-diary';
  static const String billCapture = '/bill-capture';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
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