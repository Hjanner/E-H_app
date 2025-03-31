import 'package:flutter/material.dart';
import 'package:ehstore_app/models/category.dart';
import 'package:ehstore_app/services/category_service.dart';
import 'package:ehstore_app/widgets/category_card.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'category_form_screen.dart';
import 'products_by_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  Map<String, int> _productCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar categorías
      final categories = await _categoryService.getAllCategories();
      
      // Obtener el conteo de productos para cada categoría
      Map<String, int> productCounts = {};
      for (var category in categories) {
        final products = await _categoryService.getProductsByCategory(category.id);
        productCounts[category.id] = products.length;
      }

      setState(() {
        _categories = categories;
        _productCounts = productCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar categorías: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    // Verificar si la categoría tiene productos asociados
    if (_productCounts[category.id] != null && _productCounts[category.id]! > 0) {
      _showErrorSnackBar(
        'No se puede eliminar esta categoría porque tiene productos asociados'
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldDelete || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _categoryService.deleteCategory(category.id);
      
      if (result) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('No se pudo eliminar la categoría');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al eliminar la categoría: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay categorías',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Las categorías te permiten organizar tus productos',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToFormScreen(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar categoría'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final productCount = _productCounts[category.id] ?? 0;
                            
                            return CategoryCard(
                              category: category,
                              productCount: productCount,
                              onTap: () => _navigateToProductsByCategory(category),
                              onEdit: () => _navigateToFormScreen(category: category),
                              onDelete: () => _deleteCategory(category),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _navigateToFormScreen(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white,),
            )
          : null,
    );
  }

  void _navigateToFormScreen({Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  void _navigateToProductsByCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsByCategoryScreen(category: category),
      ),
    );
  }
} 