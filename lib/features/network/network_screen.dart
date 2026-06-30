import 'package:flutter/material.dart';
import 'network_controller.dart';
import 'ping_service.dart';
import 'dns_service.dart';

/// Network Tools screen — hosts both the Ping and DNS Lookup sub-panels.
/// The controller is created and owned here so it lives for the screen lifetime.
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late final NetworkController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = NetworkController(
      pingService: PingService(),
      dnsService: DnsService(),
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ping'),
            Tab(text: 'DNS Lookup'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PingPanel(controller: _controller),
              _DnsPanel(controller: _controller),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ping sub-panel — placeholder; full implementation in a later iteration
// ---------------------------------------------------------------------------

class _PingPanel extends StatelessWidget {
  const _PingPanel({required this.controller});
  final NetworkController controller;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Ping panel — TODO'),
    );
  }
}

// ---------------------------------------------------------------------------
// DNS Lookup sub-panel — placeholder; full implementation in a later iteration
// ---------------------------------------------------------------------------

class _DnsPanel extends StatelessWidget {
  const _DnsPanel({required this.controller});
  final NetworkController controller;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('DNS Lookup panel — TODO'),
    );
  }
}
