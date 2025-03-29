import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import 'icon_selector_dialog.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = false;
  String _selectedIcon = '0xe145'; // default icon (add)
  
  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;
      _selectedIcon = widget.category!.icon;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIconSelector(),
                      const SizedBox(height: 24),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(isEditing),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildIconSelector() {
    return Center(
      child: GestureDetector(
        onTap: _showIconSelector,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                IconData(
                  int.parse(_selectedIcon),
                  fontFamily: 'MaterialIcons',
                ),
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seleccionar icono',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nombre de la categoría',
        hintText: 'Ej: Electrónica, Ropa, Alimentos...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.category),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre es obligatorio';
        }
        if (value.length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Descripción',
        hintText: 'Describe brevemente esta categoría...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.description),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La descripción es obligatoria';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _saveCategory,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        isEditing ? 'Actualizar Categoría' : 'Crear Categoría',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  void _showIconSelector() async {
    final selectedIcon = await showDialog<String>(
      context: context,
      //builder: (context) => IconSelectorDialog(currentIcon: categoriaActual.icon),

      builder: (context) => IconSelectorDialog(currentIcon: _selectedIcon),
      // builder: (context) => AlertDialog(
      //   title: const Text('Seleccionar Icono'),
      //   content: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Icon(
      //         IconData(int.parse(_selectedIcon), fontFamily: 'MaterialIcons'),
      //         size: 48,
      //         color: AppTheme.primaryColor,
      //       ),
      //       const SizedBox(height: 16),
      //       const Text('Selector de iconos en desarrollo'),
      //     ],
      //   ),
      //   actions: [
      //     TextButton(
      //       onPressed: () => Navigator.pop(context),
      //       child: const Text('Cancelar'),
      //     ),
      //     TextButton(
      //       onPressed: () => Navigator.pop(context, _selectedIcon),
      //       child: const Text('Seleccionar'),
      //     ),
      //   ],
      // ),
    );
    
    if (selectedIcon != null) {
      setState(() {
        _selectedIcon = selectedIcon;
      });
    }
  }

  void _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final category = Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: _selectedIcon,
      );
      
      if (widget.category == null) {
        await _categoryService.insertCategory(category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría creada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _categoryService.updateCategory(category);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría actualizada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
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