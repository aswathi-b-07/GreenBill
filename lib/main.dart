import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
// FFI sqlite support for desktop
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'data/providers/bills_provider.dart';
import 'data/repositories/emission_factors_repository.dart';
import 'services/suggestion_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // When running on desktop (Windows/macOS/Linux) use the ffi
  // implementation for sqflite. This must be done before any
  // openDatabase/use of the global sqflite openDatabase API.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ensures portrait-only orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await EmissionFactorsRepository().loadEmissionFactors();
  await SuggestionService().loadSuggestions();

  runApp(const GreenBillApp());
}

class GreenBillApp extends StatelessWidget {
  const GreenBillApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BillsProvider()),
      ],
      child: MaterialApp(
        title: 'GreenBill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}