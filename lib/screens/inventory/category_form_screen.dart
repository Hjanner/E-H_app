import 'package:flutter/material.dart';
import 'package:ehstore_app/models/category.dart';
import 'package:ehstore_app/services/category_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';

// Pantalla para crear o editar categorías
class CategoryFormScreen extends StatefulWidget {
  final Category? category; // Categoría existente para editar (opcional)

  const CategoryFormScreen({
    super.key,
    this.category,
  });

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  // Clave para el formulario
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Variables para los atributos visuales de la categoría
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = AppTheme.primaryColor;
  
  // Estados de la pantalla
  bool _isLoading = false; // Indica si se está procesando una operación
  bool _isEditing = false; // Indica si estamos editando una categoría existente

  // Servicio para manejar operaciones con categorías
  final CategoryService _categoryService = CategoryService();

  // Lista de iconos disponibles para seleccionar
  final List<IconData> _availableIcons = [
    Icons.devices,
    Icons.smartphone,
    Icons.laptop,
    Icons.desktop_windows,
    Icons.headphones,
    Icons.camera_alt,
    Icons.tv,
    Icons.watch,
    Icons.home,
    Icons.chair,
    Icons.kitchen,
    Icons.bed,
    Icons.light,
    Icons.dining,
    Icons.checkroom,
    Icons.face,
    Icons.shopping_bag,
    Icons.accessibility,
    Icons.local_grocery_store,
    Icons.sports_basketball,
    Icons.pets,
    Icons.toys,
    Icons.restaurant,
    Icons.local_pharmacy,
    Icons.construction,
    Icons.book,
    Icons.watch_later,
    Icons.sports_esports,
    Icons.directions_car,
    Icons.music_note,
    Icons.movie,
    Icons.computer,
    Icons.speaker,
    Icons.fastfood,
    Icons.fitness_center,
    Icons.category,
  ];

  // Lista de colores disponibles para seleccionar
  final List<Color> _availableColors = [
   AppTheme.primaryColor,
    Colors.purple,
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.lime,
    Colors.lightGreen,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.lightBlue,
    Colors.blue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    // Verificamos si estamos editando una categoría existente
    _isEditing = widget.category != null;
    
    // Si estamos editando, cargamos los datos existentes
    if (_isEditing) {
      final category = widget.category!;
      _nameController.text = category.name;
      _descriptionController.text = category.description;
      _selectedIcon = category.icon;
      _selectedColor = category.color;
    }
  }

  @override
  void dispose() {
    // Limpiamos los controladores cuando el widget se destruye
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de información básica
                    const Text(
                      'Información básica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo para el nombre de la categoría
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo para la descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sección de personalización
                    const Text(
                      'Personalización',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de icono y color
                    Row(
                      children: [
                        // Vista previa del icono y color seleccionados
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedIcon,
                                size: 40,
                                color: _selectedColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vista previa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Botones para seleccionar icono y color
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showIconPickerDialog,
                                icon: const Icon(Icons.emoji_symbols),
                                label: const Text('Seleccionar icono'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showColorPickerDialog,
                                icon: const Icon(Icons.color_lens),
                                label: const Text('Seleccionar color'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      // Barra inferior con botones de acción
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Construye la barra inferior con botones de cancelar y guardar
  Widget _buildBottomBar() {
    if (_isLoading) {
      return const SizedBox(height: 0);
    }

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
          // Botón de cancelar
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey)
              ),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ),
          const SizedBox(width: 16),
          // Botón de guardar/actualizar
          Expanded(
            child: ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  // Muestra un diálogo para seleccionar un icono
  void _showIconPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar icono'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              final isSelected = icon == _selectedIcon;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? _selectedColor : Colors.grey.shade600,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red),),
          ),
        ],
      ),
    );
  }

  // Muestra un diálogo para seleccionar un color
  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar color'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _availableColors.length,
            itemBuilder: (context, index) {
              final color = _availableColors[index];
              final isSelected = color.value == _selectedColor.value;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red),),
          ),
        ],
      ),
    );
  }

  // Guarda o actualiza la categoría
  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        bool result;
        
        if (_isEditing) {
          // Actualizar categoría existente
          result = await _categoryService.updateCategory(
            id: widget.category!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            icon: _selectedIcon,
            color: _selectedColor,
          );
        } else {
          // Crear nueva categoría
          result = await _categoryService.createCategory(
            name: _nameController.text,
            description: _descriptionController.text,
            icon: _selectedIcon,
            color: _selectedColor,
          );
        }

        if (mounted) {
          if (result) {
            // Mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditing 
                    ? 'Categoría actualizada exitosamente' 
                    : 'Categoría creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar('Error al guardar la categoría');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('Error: ${e.toString()}');
        }
      }
    }
  }

  // Muestra un mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}