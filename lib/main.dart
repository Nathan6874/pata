import 'package:pata/app/app.dart';
import 'package:pata/data/local/hive_service.dart';
import 'package:pata/splash_animated.dart';  // ← Nouvelle import
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr_FR', null);
  await Firebase.initializeApp();
  await HiveService.init();
  
  runApp(
    const ProviderScope(
      child: MyApp(),  // ← Changement ici
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PATA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AnimatedSplashScreen(),  // ← Écran animé au démarrage
    );
  }
}