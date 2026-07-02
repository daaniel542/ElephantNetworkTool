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
        title: 'ENT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.light,
        home: const ResponsiveShell(),
      ),
    );
  }
}
