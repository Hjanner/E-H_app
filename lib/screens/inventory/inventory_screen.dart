import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'products_screen.dart';
import 'category_list_screen.dart';
import 'supplier_list_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Categorías'), 
            Tab(text: 'Proveedores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ProductsScreen(),
          const CategoryListScreen(),
          const SupplierListScreen(),
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