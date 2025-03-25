import 'package:flutter/material.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              if (product.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrls.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              
              // Nombre del producto
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Precio
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Stock
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: product.isLowStock ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock: ${product.currentStock}',
                    style: TextStyle(
                      fontSize: 14,
                      color: product.isLowStock ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 