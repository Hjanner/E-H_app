import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Reporte de Ventas'),
              subtitle: const Text('Análisis de ventas por período'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implementar vista de reporte de ventas
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Reporte de Inventario'),
              subtitle: const Text('Estado actual del inventario'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implementar vista de reporte de inventario
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Reporte de Clientes'),
              subtitle: const Text('Análisis de clientes y compras'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implementar vista de reporte de clientes
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reporte de Productos'),
              subtitle: const Text('Productos más vendidos y rentables'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implementar vista de reporte de productos
              },
            ),
          ),
        ],
      ),
    );
  }
} 