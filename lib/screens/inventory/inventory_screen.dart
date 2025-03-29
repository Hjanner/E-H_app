import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'products_screen.dart';
import 'package:ehstore_app/screens/categories/categories_screen.dart';
//import 'categories_screen.dart';

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
          const CategoriesScreen(),
          _buildPlaceholder('Proveedores'),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title == 'Categorías' 
                ? Icons.category_outlined 
                : Icons.business_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sección de $title en desarrollo',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente podrás gestionar $title',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
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