import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/converter/converter_controller.dart';
import '../features/converter/converter_service.dart';
import '../features/network/dns_service.dart';
import '../features/network/network_controller.dart';
import '../features/network/ping_service.dart';
import '../features/network/traceroute_service.dart';
import '../features/password/password_controller.dart';
import '../features/password/password_service.dart';
import 'responsive_shell.dart';

class NetUtilityApp extends StatelessWidget {
  const NetUtilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NetworkController(
            pingService: PingService(),
            dnsService: DnsService(),
            tracerouteService: TracerouteService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PasswordController(service: PasswordService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ConverterController(service: ConverterService()),
        ),
      ],
      child: MaterialApp(
        title: 'Net Utility Toolkit',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.dark),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const ResponsiveShell(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primary = Color(0xFF2563EB);
    const darkNavy = Color(0xFF0F172A);
    const darkerNavy = Color(0xFF020617);
    const muted = Color(0xFF94A3B8);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme.copyWith(
        primary: primary,
        surface: darkNavy,
        onSurface: Colors.white,
        surfaceContainer: darkNavy,
        surfaceContainerHighest: const Color(0xFF1E293B),
        outline: const Color(0xFF334155),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: darkerNavy,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkerNavy,
        indicatorColor: primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? Colors.white : muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
