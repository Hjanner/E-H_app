import 'package:flutter/material.dart';
import 'dart:io';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showPrice;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showPrice = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  double _bsPrice = 0.0;
  double _dolarRate = 0.0;
  final _currencyFormatBs = NumberFormat.currency(
    locale: 'es_VE',
    symbol: 'Bs. ',
    decimalDigits: 2,
  );
  final _currencyFormatUsd = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadBsPrice();
  }

  Future<void> _loadBsPrice() async {
    try {
      final dolarRate = await Product.getDolarRate();
      final bsPrice = widget.product.price * dolarRate;
      
      if (mounted) {
        setState(() {
          _bsPrice = bsPrice;
          _dolarRate = dolarRate;
        });
      }
    } catch (e) {
      // Si hay error, no mostramos el precio en Bs
      if (mounted) {
        setState(() {
          _bsPrice = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: widget.showPrice ? 100 : 80,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: widget.product.imageUrls.isNotEmpty
                      ? _buildProductImage(widget.product.imageUrls.first)
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Nombre del producto
              SizedBox(
                height: widget.showPrice ? 40 : 40,
                child: Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: widget.showPrice ? 15 : 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Precio (opcional)
              if (widget.showPrice) ...[
                // Precio en USD
                Text(
                  _currencyFormatUsd.format(widget.product.price),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                // Precio en Bs
                if (_dolarRate > 0) ...[
                  Text(
                    _currencyFormatBs.format(_bsPrice),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const SizedBox(height: 6),
              ],
              
              // Stock
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: widget.product.isLowStock ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock: ${widget.product.currentStock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.product.isLowStock ? Colors.red : Colors.grey[600],
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

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('file://')) {
      final file = File(imageUrl.replaceFirst('file://', ''));
      return Image.file(
        file,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      return Image.network(
        imageUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }
} 