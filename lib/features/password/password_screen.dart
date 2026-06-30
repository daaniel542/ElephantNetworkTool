import 'package:flutter/material.dart';
import 'password_controller.dart';
import 'password_service.dart';

/// Password Generator screen.
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  late final PasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PasswordController(service: PasswordService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Password Generator — TODO'),
    );
  }
}
