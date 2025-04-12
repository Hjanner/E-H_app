import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'products_screen.dart';
import 'purchases_screen.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExchangeRate();
  }
  
  Future<void> _loadExchangeRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRate = prefs.getDouble('exchange_rate');
      if (savedRate != null && savedRate > 0) {
        Product.exchangeRate = savedRate;
      }
    } catch (e) {
      // Si hay un error, se mantiene la tasa por defecto
      print('Error al cargar tasa de cambio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Productos'),
            Tab(text: 'Compras'), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ProductsScreen(),
          const PurchasesScreen(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 