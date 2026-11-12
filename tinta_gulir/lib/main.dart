import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/progress.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GulirApp());
}

class GulirApp extends StatelessWidget {
  const GulirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinta Gulir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPalette[0],
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
