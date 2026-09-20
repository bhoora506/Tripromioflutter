import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait for the initial phase.
  // This can be removed or extended in a later phase.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TripromioApp());

  // Initialise FCM foundation (Phase H1-A) after the UI is running.
  // Intentionally NOT awaited — permission dialog and token fetch are
  // network-dependent and must not delay app startup or the SplashScreen.
  // Firebase.initializeApp() above has already completed, so all Firebase
  // APIs are safe to call from here.
  // The singleton ensures initialize() runs exactly once.
  PushNotificationService.instance.initialize();
}

/// Root widget of the Tripromio application.
class TripromioApp extends StatelessWidget {
  const TripromioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Routing
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
