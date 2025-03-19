import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Información de la Tienda'),
                  subtitle: const Text('Configurar datos de la empresa'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implementar configuración de tienda
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Configurar alertas y notificaciones'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implementar configuración de notificaciones
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Respaldo de Datos'),
                  subtitle: const Text('Realizar copia de seguridad'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implementar respaldo de datos
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restaurar Datos'),
                  subtitle: const Text('Recuperar datos de respaldo'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implementar restauración de datos
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Seguridad'),
                  subtitle: const Text('Configurar contraseña y acceso'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implementar configuración de seguridad
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Ayuda y Soporte'),
                  subtitle: const Text('Documentación y contacto'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implementar ayuda y soporte
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 