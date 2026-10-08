import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/questions.dart';
import 'firebase_options.dart';
import 'net/room.dart';
import 'prefs.dart';
import 'screens/home.dart';
import 'sfx.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  Sfx.muted = Prefs.muted;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    Online.ready = true;
  } catch (e) {
    debugPrint('Firebase não configurado, só o modo celular único vai funcionar: $e');
  }
  await Bank.load();
  runApp(const ViajouApp());
}

class ViajouApp extends StatelessWidget {
  const ViajouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIAJOU!',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
