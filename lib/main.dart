import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/isar_service.dart';
import 'presentation/app_shell.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> NearCartAppMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADD THIS
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  //await IsarService.instance.init();

  runApp(
    const ProviderScope(
      child: NearCartApp(),
    ),
  );
}
class NearCartApp extends StatelessWidget {
  const NearCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearCart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}
