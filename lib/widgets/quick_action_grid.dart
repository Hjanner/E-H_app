import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _QuickActionCard(
          title: 'Añadir Venta',
          icon: Icons.add_shopping_cart,
          onTap: () {},
        ),
        _QuickActionCard(
          title: 'Deudas',
          icon: Icons.account_balance_wallet,
          onTap: () {},
        ),
        _QuickActionCard(
          title: 'Inventario',
          icon: Icons.inventory_2,
          onTap: () {},
        ),
        _QuickActionCard(
          title: 'Ventas',
          icon: Icons.shopping_cart,
          onTap: () {},
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 