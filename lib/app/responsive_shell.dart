import 'package:flutter/material.dart';

import '../features/converter/converter_screen.dart';
import '../features/network/network_screen.dart';
import '../features/password/password_screen.dart';

const double _kDesktopBreakpoint = 720.0;
const _background = Color(0xFFF8FAFC);
const _sidebar = Color(0xFF0F172A);
const _sidebarActive = Color(0xFF1E293B);
const _primary = Color(0xFF2563EB);
const _activeIcon = Color(0xFF60A5FA);
const _sidebarMuted = Color(0xFF94A3B8);
const _sidebarText = Color(0xFFCBD5E1);

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    _Destination(
      label: 'Network',
      mobileLabel: 'Network',
      glyph: '◌',
      screen: NetworkScreen(),
    ),
    _Destination(
      label: 'Password Generator',
      mobileLabel: 'Password',
      glyph: '▣',
      screen: PasswordScreen(),
    ),
    _Destination(
      label: 'Encoding/Decoding',
      mobileLabel: 'Encoding',
      glyph: '<>',
      screen: ConverterScreen(),
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kDesktopBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                _DesktopSidebar(
                  selectedIndex: _selectedIndex,
                  onSelected: _onDestinationSelected,
                ),
                Expanded(child: _destinations[_selectedIndex].screen),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: _background,
          body: _destinations[_selectedIndex].screen,
          bottomNavigationBar: _MobileNav(
            selectedIndex: _selectedIndex,
            onSelected: _onDestinationSelected,
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.mobileLabel,
    required this.glyph,
    required this.screen,
  });

  final String label;
  final String mobileLabel;
  final String glyph;
  final Widget screen;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: _sidebar,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: _SidebarBrand(),
              ),
              const SizedBox(height: 42),
              for (
                var index = 0;
                index < _ResponsiveShellState._destinations.length;
                index += 1
              ) ...[
                _SidebarItem(
                  destination: _ResponsiveShellState._destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: _SidebarFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? _sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? _primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              child: Text(
                destination.glyph,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? _activeIcon : _sidebarMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                destination.label,
                style: TextStyle(
                  color: selected ? Colors.white : _sidebarText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Image.asset(
            'assets/images/elephantlogo.png',
            width: 186,
            fit: BoxFit.contain,
            semanticLabel: 'Elephant Technology Limited logo',
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Version 1',
          style: TextStyle(
            color: _sidebarMuted,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (
              var index = 0;
              index < _ResponsiveShellState._destinations.length;
              index += 1
            )
              Expanded(
                child: _MobileNavItem(
                  destination: _ResponsiveShellState._destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : _sidebarMuted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            destination.glyph,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            destination.mobileLabel,
            style: TextStyle(
              color: selected ? const Color(0xFF0F172A) : _sidebarMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
