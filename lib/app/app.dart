import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../screens/home_screen.dart';
import 'app_theme.dart';

class AlcaldiaApp extends StatelessWidget {
  const AlcaldiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
