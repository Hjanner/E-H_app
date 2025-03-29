import 'package:flutter/material.dart';
import 'package:ehstore_app/models/category.dart';
import 'package:ehstore_app/services/category_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class CategoryDropdown extends StatefulWidget {
  final String? value;
  final Function(String?) onChanged;
  final bool showAllOption;
  final String allOptionText;
  final String labelText;

  const CategoryDropdown({
    Key? key,
    this.value,
    required this.onChanged,
    this.showAllOption = true,
    this.allOptionText = 'Todas',
    this.labelText = 'Categoría',
  }) : super(key: key);

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar categorías: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: widget.value,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primaryColor),
      ),
      items: [
        if (widget.showAllOption)
          const DropdownMenuItem<String>(
            value: 'all',
            child: Text('Todas'),
          ),
        ..._categories.map((category) => DropdownMenuItem<String>(
          value: category.id.toString(),
          child: Text(category.name),
        )).toList(),
      ],
      onChanged: widget.onChanged,
      dropdownColor: AppTheme.backgroundColor,
      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
    );
  }
} 