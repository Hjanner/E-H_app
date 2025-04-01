import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        elevation: 0,
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analiza tu negocio',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisa el desempeño de tu negocio con estos reportes detallados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildReportCard(
                    icon: Icons.trending_up,
                    title: 'Reporte de Ventas',
                    subtitle: 'Análisis de ventas por período',
                    color: Colors.blue.shade700,
                    onTap: () {
                      // TODO: Implementar vista de reporte de ventas
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    icon: Icons.inventory_2,
                    title: 'Reporte de Inventario',
                    subtitle: 'Estado actual del inventario',
                    color: Colors.green.shade700,
                    onTap: () {
                      // TODO: Implementar vista de reporte de inventario
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    icon: Icons.people,
                    title: 'Reporte de Clientes',
                    subtitle: 'Análisis de clientes y compras',
                    color: Colors.orange.shade700,
                    onTap: () {
                      // TODO: Implementar vista de reporte de clientes
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    icon: Icons.analytics,
                    title: 'Reporte de Productos',
                    subtitle: 'Productos más vendidos y rentables',
                    color: Colors.purple.shade700,
                    onTap: () {
                      // TODO: Implementar vista de reporte de productos
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
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
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 