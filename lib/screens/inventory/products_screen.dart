import 'package:flutter/material.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/product_service.dart';
import 'package:ehstore_app/widgets/product_card.dart';
import 'package:ehstore_app/widgets/category_dropdown.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getAllProducts();
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _filterProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.filterProducts(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategory != 'all' ? _selectedCategory : null,
        lowStockOnly: _showLowStockOnly,
      );
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al filtrar productos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshProducts() async {
    if (_searchQuery.isNotEmpty || _selectedCategory != 'all' || _showLowStockOnly) {
      await _filterProducts();
    } else {
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Barra de búsqueda y filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  //const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterProducts();
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Categorías
                      Expanded(
                        child: CategoryDropdown(
                          //labelText: Colors.grey,
                          value: _selectedCategory,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                              _filterProducts();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stock bajo
                      FilterChip(
                        label: const Text('Stock bajo'),
                        selected: _showLowStockOnly,
                        onSelected: (selected) {
                          setState(() {
                            _showLowStockOnly = selected;
                          });
                          _filterProducts();
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.cardBackground,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de productos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay productos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Agrega nuevos productos usando el botón +',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _refreshProducts,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshProducts,
                          color: AppTheme.primaryColor,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return ProductCard(
                                product: product,
                                onTap: () => _openProductDetail(product),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        
        // Botón flotante para agregar producto
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              ).then((result) {
                if (result == true) {
                  _refreshProducts();
                }
              });
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: product.id),
      ),
    ).then((result) {
      if (result == true) {
        _refreshProducts();
      }
    });
  }
} 