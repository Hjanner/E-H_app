import 'package:flutter/material.dart';
import 'package:ehstore_app/screens/inventory/inventory_screen.dart';
import 'package:ehstore_app/screens/sales/sales_screen.dart';
import 'package:ehstore_app/screens/more/customers/customers_screen.dart';
import 'package:ehstore_app/screens/reports/reports_screen.dart';
import 'package:ehstore_app/screens/settings/settings_screen.dart';
import 'package:ehstore_app/screens/more/more_screen.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/widgets/balance_card.dart';
import 'package:ehstore_app/widgets/quick_action_grid.dart';
import 'package:ehstore_app/widgets/alert_section.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/product_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ProductService _productService = ProductService();
  List<Product> _lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getLowStockProducts();
      setState(() {
        _lowStockProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Manejamos el error pero no mostramos mensajes en initState
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 
          ? AppBar(
              title: const Text('E&H'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadLowStockProducts,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BalanceCard(),
          const SizedBox(height: 16),
          const QuickActionGrid(),
          const SizedBox(height: 16),
          _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              )
            : AlertSection(
                title: 'Alerta de Stock bajo',
                items: _lowStockProducts,
              ),
        ],
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      Container(), // Home (ya manejado por _buildHomeContent)
      const InventoryScreen(),
      const SalesScreen(),
      const MoreScreen(),
    ];
  }
} 