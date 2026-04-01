import 'package:flutter/material.dart';
import 'package:property_tracker/screens/rental_manager_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/property_provider.dart';
import '../dashboard_screen.dart';
import '../overview_screen.dart';
import 'entry_screen.dart';
import 'running_costs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static void navigateToTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_HomeScreenState>();
    state?._switchToTab(tabIndex);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;

  void _switchToTab(int tabIndex) {
    setState(() => _tab = tabIndex);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh data when app resumes
      context.read<PropertyProvider>().checkConnectivity();
      context.read<PropertyProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const EntryScreen(),
      const OverviewScreen(),
      const MenuPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: screens,
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) {
        setState(() => _tab = i);
      },
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Monthly',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Summary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_outlined),
          activeIcon: Icon(Icons.menu),
          label: 'Menu',
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PropertyProvider>(
        builder: (context, prov, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Property selector
              if (prov.properties.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Property',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.home_work,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prov.selectedProperty?.name ?? 'None selected',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Menu items
              _buildMenuItem(
                context,
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF4CAF50),
                title: 'Rental Manager',
                subtitle: 'Manage rent periods',
                onTap: () {
                  if (prov.selectedProperty != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentalManagerScreen(
                          propertyId: prov.selectedProperty!.id,
                          propertyName: prov.selectedProperty!.name,
                        ),
                      ),
                    );
                  } else if (prov.properties.isNotEmpty) {
                    prov.selectProperty(prov.properties.first).then((_) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RentalManagerScreen(
                              propertyId: prov.selectedProperty!.id,
                              propertyName: prov.selectedProperty!.name,
                            ),
                          ),
                        );
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF9C74CC),
                title: 'Running Costs',
                subtitle: 'Track garden, levies & other costs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RunningCostsScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
