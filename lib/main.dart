import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ehstore_app/screens/home_screen.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/screens/customers/customer_list_screen.dart';
import 'package:ehstore_app/screens/customers/customer_detail_screen.dart';
import 'package:ehstore_app/screens/customers/customer_form_screen.dart';
import 'screens/inventory/products_screen.dart';
import 'package:ehstore_app/screens/sales/sales_screen.dart';
import 'package:ehstore_app/screens/sales/new_sale_screen.dart';
import 'package:ehstore_app/screens/sales/sale_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E&H Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
      routes: {
        // Rutas para clientes
        '/customer_list': (context) => const CustomerListScreen(),
        '/customer_form': (context) => CustomerFormScreen(
              customer: ModalRoute.of(context)?.settings.arguments as dynamic,
            ),
        '/sales': (context) => const SalesScreen(),
        '/sales/new': (context) => const NewSaleScreen(),
        '/sales/detail': (context) => SaleDetailScreen(
          saleId: ModalRoute.of(context)!.settings.arguments as String,
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/customer_detail') {
          return MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(
              customerId: settings.arguments as String,
            ),
          );
        }
        return null;
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductsScreen(),
    const Center(child: Text('Ventas')),
    const Center(child: Text('Clientes')),
    const Center(child: Text('Informes')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Ventas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Informes',
          ),
        ],
      ),
    );
  }
}
