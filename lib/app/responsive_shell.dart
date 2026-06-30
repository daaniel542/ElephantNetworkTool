import 'package:flutter/material.dart';
import '../features/network/network_screen.dart';
import '../features/password/password_screen.dart';
import '../features/converter/converter_screen.dart';

/// Breakpoint below which the layout switches to mobile (bottom nav bar).
const double _kMobileBreakpoint = 720.0;

/// The top-level scaffold that adapts between a desktop sidebar layout and a
/// mobile bottom-navigation-bar layout based on the available screen width.
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Network Tools', icon: Icons.wifi),
    _NavItem(label: 'Password Gen', icon: Icons.lock_outline),
    _NavItem(label: 'Encoding', icon: Icons.code),
  ];

  static const List<Widget> _screens = [
    NetworkScreen(),
    PasswordScreen(),
    ConverterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _kMobileBreakpoint;

        if (isDesktop) {
          return _DesktopLayout(
            navItems: _navItems,
            selectedIndex: _selectedIndex,
            screens: _screens,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
          );
        } else {
          return _MobileLayout(
            navItems: _navItems,
            selectedIndex: _selectedIndex,
            screens: _screens,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
          );
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout — persistent left sidebar
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.navItems,
    required this.selectedIndex,
    required this.screens,
    required this.onDestinationSelected,
  });

  final List<_NavItem> navItems;
  final int selectedIndex;
  final List<Widget> screens;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: true,
            minExtendedWidth: 200,
            backgroundColor: theme.colorScheme.surface,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Net Utility\nToolkit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            destinations: navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: screens[selectedIndex]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout — bottom navigation bar, stacked content
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.navItems,
    required this.selectedIndex,
    required this.screens,
    required this.onDestinationSelected,
  });

  final List<_NavItem> navItems;
  final int selectedIndex;
  final List<Widget> screens;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple data class for navigation items
// ---------------------------------------------------------------------------

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
