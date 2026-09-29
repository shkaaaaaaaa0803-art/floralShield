import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/scan_history_model.dart';
import 'providers/auth_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (GEMINI_API_KEY)
  await dotenv.load(fileName: '.env');

  // Initialize Firebase (auth + cloud sync)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(ScanHistoryModelAdapter());

  // Initialize local notifications
  await NotificationService.init();

  runApp(const PlantDiseaseApp());
}

class PlantDiseaseApp extends StatelessWidget {
  const PlantDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ScanProvider needs to know the current signed-in user so it can
        // sync scan history to/from Firestore. ChangeNotifierProxyProvider
        // re-runs `update` every time AuthProvider notifies listeners
        // (sign-in, sign-out, session expiry), which is what actually
        // triggers ScanProvider.setUserId() - a plain ChangeNotifierProvider
        // for ScanProvider on its own would never learn about auth changes.
        ChangeNotifierProxyProvider<AuthProvider, ScanProvider>(
          create: (_) => ScanProvider(),
          update: (_, auth, scanProvider) {
            scanProvider!.setUserId(auth.uid);
            return scanProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: MaterialApp(
        title: 'FloraShield AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}