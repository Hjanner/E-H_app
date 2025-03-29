import 'package:flutter/material.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/product_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'product_form_screen.dart';
import 'dart:io';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  late Future<Product?> _productFuture;
  int _selectedImageIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() {
    _productFuture = _productService.getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          FutureBuilder<Product?>(
            future: _productFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }

              if (snapshot.hasData) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: AppTheme.primaryColor,
                      onPressed: () => _editProduct(snapshot.data!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _confirmDelete(snapshot.data!.id),
                    ),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ],
      ),
      body: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar el producto',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadProduct();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data;
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Producto no encontrado',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carrusel de imágenes
                if (product.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Imagen principal
                        PageView.builder(
                          itemCount: product.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imageUrl = product.imageUrls[index];
                            if (imageUrl.startsWith('file://')) {
                              final file = File(imageUrl.replaceFirst('file://', ''));
                              return Image.file(
                                file,
                                fit: BoxFit.scaleDown,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                        
                        // Indicadores de página
                        Positioned(
                          bottom: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.imageUrls.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedImageIndex == index
                                      ? AppTheme.primaryColor
                                      : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                
                // Información del producto
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto y precio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Categoría
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _getCategoryName(product.categoryId ?? ''),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Proveedor
                      Row(
                        children: [
                          const Icon(Icons.business_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _getSupplierName(product.supplierId),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 32),
                      
                      // Stock
                      Row(
                        children: [
                          const Text(
                            'Stock Disponible:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: product.isLowStock
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  product.isLowStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline,
                                  size: 16,
                                  color: product.isLowStock
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.current_stock} unidades',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: product.isLowStock
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Stock mínimo
                      Row(
                        children: [
                          const Text(
                            'Stock Mínimo:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${product.minimumStock} unidades',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 32),
                      
                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      
                      if (product.specifications.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Especificaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...product.specifications.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatSpecName(entry.key)}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 0);
          }

          final product = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _showStockDialog(product, true),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading 
                        ? null 
                        : product.current_stock <= 0 
                            ? null 
                            : () => _showStockDialog(product, false),
                    icon: const Icon(Icons.remove),
                    label: const Text('Reducir Stock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return "Sin categoría";
    }
    
    final Map<String, String> categories = {
      'electrónica': 'Electrónica',
      'hogar': 'Hogar',
      'ropa': 'Ropa',
    };
    return categories[categoryId] ?? categoryId;
  }

  String _getSupplierName(String supplierId) {
    final Map<String, String> suppliers = {
      'samsung': 'Samsung Electronics',
      'hp': 'HP Inc.',
      'lg': 'LG Electronics',
      'muebles_inc': 'Muebles Inc.',
      'fashion_inc': 'Fashion Inc.',
    };
    return suppliers[supplierId] ?? supplierId;
  }

  String _formatSpecName(String name) {
    if (name.isEmpty) return name;
    
    // Convertir 'processor' a 'Procesador' o similar
    final Map<String, String> translations = {
      'processor': 'Procesador',
      'ram': 'RAM',
      'storage': 'Almacenamiento',
      'screen': 'Pantalla',
      'material': 'Material',
      'color': 'Color',
      'peso_max': 'Peso máximo',
      'tallas': 'Tallas',
      'colores': 'Colores',
      'pantalla': 'Pantalla',
      'conectividad': 'Conectividad',
      'smart_tv': 'Smart TV',
    };
    
    return translations[name.toLowerCase()] ?? 
           name.split('_')
               .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
               .join(' ');
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );

    if (result == true) {
      setState(() {
        _loadProduct();
      });
    }
  }

  Future<void> _confirmDelete(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Está seguro que desea eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.primaryColor),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _productService.deleteProduct(productId);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto eliminado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Volver y notificar cambios
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo eliminar el producto'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showStockDialog(Product product, bool isAddingStock) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isAddingStock ? 'Agregar Stock' : 'Reducir Stock'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: isAddingStock 
                  ? 'Cantidad a agregar' 
                  : 'Cantidad a reducir',
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isAddingStock ? AppTheme.primaryColor : Colors.red,
                  width: 2.0,
                ),
              ),
              prefixIcon: Icon(
                isAddingStock ? Icons.add : Icons.remove,
                color: isAddingStock ? AppTheme.primaryColor : Colors.red,
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese una cantidad';
              }
              
              final quantity = int.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'Ingrese un número válido mayor a 0';
              }
              
              if (!isAddingStock && quantity > product.current_stock) {
                return 'No puede reducir más de ${product.current_stock} unidades';
              }
              
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final quantity = int.parse(controller.text);
                Navigator.pop(context, quantity);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAddingStock ? AppTheme.primaryColor : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isAddingStock ? 'Agregar' : 'Reducir'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (isAddingStock) {
          await _productService.addStock(product.id, result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Se agregaron $result unidades al stock'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await _productService.removeStock(product.id, result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Se redujeron $result unidades del stock'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        setState(() {
          _loadProduct();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
} 