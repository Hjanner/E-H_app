import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/widgets/section_title.dart';

class ProductListCard extends StatelessWidget {
  final List<SaleItem> items;
  final double total;
  final Function(String) onProductTap;

  const ProductListCard({
    super.key,
    required this.items,
    required this.total,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle(title: 'Productos'),
                Text(
                  '${items.length} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var item in items) ...[
              InkWell(
                onTap: () => onProductTap(item.productId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Ver producto',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (item != items.last)
                const SizedBox(height: 12),
            ],
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 