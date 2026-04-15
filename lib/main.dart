import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart';
import 'core/theme/app_theme.dart';

Future<void> NearCartAppMain() async {
  // 1. THIS MUST BE THE ABSOLUTE FIRST LINE
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Firebase
    await Firebase.initializeApp();

    // 3. Set orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 4. Set UI Overlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // 5. Finally run the app
    runApp(
      const ProviderScope(
        child: NearCartApp(),
      ),
    );
  } catch (e) {
    // This will help you see if Firebase initialization itself is failing
    debugPrint("Error during initialization: $e");
  }
}

class NearCartApp extends StatelessWidget {
  const NearCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearCart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // keep your existing theme
      home: const AuthGate(), // ← routes based on auth state
    );
  }
}

/*
Staging users

musfiq677@gmail.com
12345678
Musfiq Rahman

mira@gmail.com
12345678
Munalisa Mira

 */