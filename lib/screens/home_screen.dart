import 'package:flutter/material.dart';
import 'package:ehstore_app/screens/inventory/inventory_screen.dart';
import 'package:ehstore_app/screens/sales/sales_screen.dart';
import 'package:ehstore_app/screens/customers/customers_screen.dart';
import 'package:ehstore_app/screens/reports/reports_screen.dart';
import 'package:ehstore_app/screens/settings/settings_screen.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/widgets/balance_card.dart';
import 'package:ehstore_app/widgets/quick_action_grid.dart';
import 'package:ehstore_app/widgets/alert_section.dart';
import 'package:ehstore_app/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 
          ? AppBar(
              title: const Text('E&H'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () async {
                    final db = await _databaseService.database;
                    var tableInfo = await db.rawQuery("PRAGMA table_info(products)");
                    print("Estructura de tabla products: $tableInfo");
                  },
                ),
              ],
            )
          : null,
      body: _selectedIndex == 0 
          ? _buildHomeContent() 
          : _buildScreens()[_selectedIndex],

      //navigation bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppTheme.backgroundColor,
        elevation: 8,
        shadowColor: Colors.black12,
        //surfaceTintColor: AppTheme.primaryColor.withOpacity(0.1),
        indicatorColor: AppTheme.primaryColor.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 500),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, 
              color: _selectedIndex == 0 ? AppTheme.primaryColor : Colors.grey),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined,
              color: _selectedIndex == 1 ? AppTheme.primaryColor : Colors.grey),
            selectedIcon: Icon(Icons.inventory_2, color: AppTheme.primaryColor),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined,
              color: _selectedIndex == 2 ? AppTheme.primaryColor : Colors.grey),
            selectedIcon: Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
            label: 'Ventas',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz,
              color: _selectedIndex == 3 ? AppTheme.primaryColor : Colors.grey),
            selectedIcon: Icon(Icons.more_horiz, color: AppTheme.primaryColor),
            label: 'Más',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BalanceCard(),
            const SizedBox(height: 24),
            const QuickActionGrid(),
            const SizedBox(height: 24),
            const AlertSection(
              title: 'Alerta de Stock bajo',
              items: [], // TODO: Implementar items
            ),
            const SizedBox(height: 16),
            const AlertSection(
              title: 'Pedidos en camino',
              items: [], // TODO: Implementar items
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      Container(), // Home (ya manejado por _buildHomeContent)
      const InventoryScreen(),
      const SalesScreen(),
      const CustomersScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
  }
} 