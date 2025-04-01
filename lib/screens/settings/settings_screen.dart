import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Configuración de negocio'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  icon: Icons.store,
                  iconColor: Colors.blue.shade700,
                  title: 'Información de la Tienda',
                  subtitle: 'Configurar datos de la empresa',
                  onTap: () {
                    // TODO: Implementar configuración de tienda
                  },
                ),
                const Divider(height: 1, indent: 60),
                _buildSettingsItem(
                  icon: Icons.notifications,
                  iconColor: Colors.orange.shade700,
                  title: 'Notificaciones',
                  subtitle: 'Configurar alertas y notificaciones',
                  onTap: () {
                    // TODO: Implementar configuración de notificaciones
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Datos y backup'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  icon: Icons.backup,
                  iconColor: Colors.green.shade700,
                  title: 'Respaldo de Datos',
                  subtitle: 'Realizar copia de seguridad',
                  onTap: () {
                    // TODO: Implementar respaldo de datos
                  },
                ),
                const Divider(height: 1, indent: 60),
                _buildSettingsItem(
                  icon: Icons.restore,
                  iconColor: Colors.purple.shade700,
                  title: 'Restaurar Datos',
                  subtitle: 'Recuperar datos de respaldo',
                  onTap: () {
                    // TODO: Implementar restauración de datos
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Seguridad y soporte'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  icon: Icons.security,
                  iconColor: Colors.red.shade700,
                  title: 'Seguridad',
                  subtitle: 'Configurar contraseña y acceso',
                  onTap: () {
                    // TODO: Implementar configuración de seguridad
                  },
                ),
                const Divider(height: 1, indent: 60),
                _buildSettingsItem(
                  icon: Icons.help,
                  iconColor: Colors.cyan.shade700,
                  title: 'Ayuda y Soporte',
                  subtitle: 'Documentación y contacto',
                  onTap: () {
                    // TODO: Implementar ayuda y soporte
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  iconColor: Colors.grey.shade700,
                  title: 'Acerca de',
                  subtitle: 'Versión 1.0.0',
                  onTap: () {},
                  showChevron: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ),
      trailing: showChevron ? Icon(Icons.chevron_right, color: Colors.grey.shade400) : null,
      onTap: onTap,
    );
  }
} 