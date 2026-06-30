import 'package:flutter/material.dart';
import 'responsive_shell.dart';

class NetUtilityApp extends StatelessWidget {
  const NetUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Net Utility Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const ResponsiveShell(),
    );
  }
}
