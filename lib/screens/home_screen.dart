import 'package:flutter/material.dart';
import 'package:property_tracker/screens/rental_manager_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/property_provider.dart';
import '../dashboard_screen.dart';
import '../overview_screen.dart';
import '../screens/properties_screen.dart';
import '../screens/running_costs_screen.dart';
import '../screens/municipality_payments_screen.dart';
import '../screens/rental_income_screen.dart';
import 'entry_screen.dart';

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

  void _navigateToSummary() {
    _switchToTab(2);
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
      DashboardScreen(onNavigateToSummary: _navigateToSummary),
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    return BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) {
        setState(() => _tab = i);
      },
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
          activeIcon: Icon(Icons.dashboard, color: primaryColor),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined, color: Colors.grey),
          activeIcon: Icon(Icons.calendar_today, color: primaryColor),
          label: 'Monthly',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined, color: Colors.grey),
          activeIcon: Icon(Icons.bar_chart, color: primaryColor),
          label: 'Summary',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_outlined, color: Colors.grey),
          activeIcon: Icon(Icons.menu, color: primaryColor),
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
                              'Current Property',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 20),
                            onPressed: () =>
                                _showPropertySelector(context, prov),
                            tooltip: 'Switch Property',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prov.selectedProperty?.name ?? 'None selected',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Property management
              _buildMenuItem(
                context,
                icon: Icons.home_work_outlined,
                iconColor: const Color(0xFF42A5F5),
                title: 'Manage Properties',
                subtitle: 'Add, edit or remove properties',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PropertiesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

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
              const SizedBox(height: 24),

              // Divider
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),

              // Financial Summary Section
              _buildFinancialSummary(context, prov),
              const SizedBox(height: 32), // Extra padding at bottom
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context, PropertyProvider prov) {
    // Show section even if no property selected, with a message
    final hasProperty = prov.selectedProperty != null;

    // Calculate totals only if property is selected
    double totalMunicipalityPayments = 0;
    double totalRentalIncome = 0;

    if (hasProperty) {
      for (final expense in prov.expenses) {
        totalMunicipalityPayments += expense.paymentToMunicipality;
        totalRentalIncome += expense.paymentReceived;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Financial Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasProperty)
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select a property to view details',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _buildFinancialCard(
              context,
              icon: Icons.account_balance,
              iconColor: const Color(0xFF42A5F5),
              title: 'Municipality Payments',
              amount: totalMunicipalityPayments,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MunicipalityPaymentsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildFinancialCard(
              context,
              icon: Icons.payments,
              iconColor: const Color(0xFF66BB6A),
              title: 'Rental Income',
              amount: totalRentalIncome,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RentalIncomeScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double amount,
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
                color: iconColor.withValues(alpha: 0.15),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatZAR(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
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

  String _formatZAR(double amount) {
    if (amount >= 1000000) {
      return 'R${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'R${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'R${amount.toStringAsFixed(2)}';
  }

  void _showPropertySelector(BuildContext context, PropertyProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Property'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: prov.properties.length,
            itemBuilder: (ctx, i) {
              final prop = prov.properties[i];
              final isSelected = prov.selectedProperty?.id == prop.id;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.home_outlined,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(prop.name),
                subtitle: prop.address != null ? Text(prop.address!) : null,
                selected: isSelected,
                onTap: () {
                  prov.selectProperty(prop);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
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
