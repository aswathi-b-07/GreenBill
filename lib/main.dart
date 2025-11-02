import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'data/providers/bills_provider.dart';
import 'data/repositories/emission_factors_repository.dart';
import 'services/suggestion_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensures portrait-only orientation (optionally comment if you want full support)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load datasets and eco suggestions at startup
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
        // Use named routes if you wish, or just initial home
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.generateRoute,
        home: const HomeScreen(),
      ),
    );
  }
}
