import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar agregar producto
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // TODO: Implementar búsqueda
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 0, // TODO: Implementar lista de productos
              itemBuilder: (context, index) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.inventory_2),
                    title: Text('Nombre del Producto'),
                    subtitle: Text('Stock: 0'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 