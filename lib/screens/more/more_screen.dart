import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/screens/more/category/category_list_screen.dart';
import 'package:ehstore_app/screens/more/supplier/supplier_list_screen.dart';
import 'package:ehstore_app/screens/more/customers/customers_screen.dart';
import 'package:ehstore_app/screens/reports/reports_screen.dart';
import 'package:ehstore_app/screens/settings/settings_screen.dart';
import 'package:ehstore_app/screens/more/exchange_rate/exchange_rate_screen.dart';
import 'package:ehstore_app/models/product.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más opciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuOption(
              context,
              title: 'Clientes',
              icon: Icons.people,
              color: Colors.blue.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomersScreen(),
                ),
              ),
            ),
            _buildMenuOption(
              context,
              title: 'Categorías',
              icon: Icons.category,
              color: Colors.purple.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryListScreen(),
                ),
              ),
            ),
            _buildMenuOption(
              context,
              title: 'Proveedores',
              icon: Icons.business,
              color: Colors.red.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupplierListScreen(),
                ),
              ),
            ),
            _buildMenuOption(
              context,
              title: 'Tasa de Cambio',
              icon: Icons.currency_exchange,
              color: Colors.yellow.shade700,
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExchangeRateScreen(),
                  ),
                );
              },
            ),
            _buildMenuOption(
              context,
              title: 'Reportes',
              icon: Icons.bar_chart,
              color: Colors.indigo.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(),
                ),
              ),
            ),
            _buildMenuOption(
              context,
              title: 'Configuración',
              icon: Icons.settings,
              color: Colors.grey.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 