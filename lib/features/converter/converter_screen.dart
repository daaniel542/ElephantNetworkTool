import 'package:flutter/material.dart';
import 'converter_controller.dart';
import 'converter_service.dart';

/// Encoding / Hashing Converter screen.
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late final ConverterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConverterController(service: ConverterService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Encoding Converter — TODO'),
    );
  }
}
