import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class AlertSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;

  const AlertSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay elementos para mostrar',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 