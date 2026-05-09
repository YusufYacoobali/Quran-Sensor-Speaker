import 'package:flutter/material.dart';

import 'pages/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const QuranSpeakerApp());
}

class QuranSpeakerApp extends StatelessWidget {
  const QuranSpeakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quran Speaker',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
