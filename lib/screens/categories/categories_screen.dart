import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  late Future<List<Category>> _categoriesFuture;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  void _loadCategories() {
    _categoriesFuture = _categoryService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadCategories();
          });
        },
        child: FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar categorías: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay categorías disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCategoryForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear categoría'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, 
                          vertical: 12
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final category = snapshot.data![index];
                return _buildCategoryCard(context, category);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCategoryForm(context),
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCategoryForm(context, category: category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(
                    int.parse(category.icon),
                    fontFamily: 'MaterialIcons',
                  ),
                  size: 30,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<int>(
                      future: _categoryService.countProductsInCategory(category.id!),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text(
                          '$count producto${count != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppTheme.accentColor,
                onPressed: () => _navigateToCategoryForm(context, category: category),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.errorColor,
                onPressed: () => _confirmDeleteCategory(context, category),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryForm(BuildContext context, {Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(category: category),
      ),
    );

    if (result == true) {
      setState(() {
        _loadCategories();
      });
    }
  }

  void _confirmDeleteCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${category.name}"? '
          'Los productos asociados a esta categoría no serán eliminados, '
          'pero perderán la referencia a esta categoría.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _categoryService.deleteCategory(category.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Categoría "${category.name}" eliminada con éxito'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _loadCategories();
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar categoría: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
} 