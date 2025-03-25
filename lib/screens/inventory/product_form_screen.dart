import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/product_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _imageController = TextEditingController();
  
  String _selectedCategory = 'electrónica';
  String _selectedSupplier = 'samsung';
  final Map<String, dynamic> _specifications = {};
  final List<String> _imageUrls = [];
  
  bool _isLoading = false;
  bool _isEditing = false;

  final _productService = ProductService();

  // Mapeo de categorías para mostrar al usuario
  final Map<String, String> _categoryMap = {
    'electrónica': 'Electrónica',
    'hogar': 'Hogar',
    'ropa': 'Ropa',
  };

  // Mapeo de proveedores para mostrar al usuario
  final Map<String, String> _supplierMap = {
    'samsung': 'Samsung Electronics',
    'hp': 'HP Inc.',
    'lg': 'LG Electronics',
    'muebles_inc': 'Muebles Inc.',
    'fashion_inc': 'Fashion Inc.',
  };

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;
    
    if (_isEditing) {
      final product = widget.product!;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _currentStockController.text = product.currentStock.toString();
      _minStockController.text = product.minimumStock.toString();
      
      _selectedCategory = product.categoryId;
      _selectedSupplier = product.supplierId;
      _specifications.addAll(product.specifications);
      _imageUrls.addAll(product.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
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
                    // Información básica
                    const Text(
                      'Información básica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción
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
                    const SizedBox(height: 16),

                    // Categoría
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categoryMap.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Proveedor
                    DropdownButtonFormField<String>(
                      value: _selectedSupplier,
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: _supplierMap.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSupplier = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Precio y Stock
                    const Text(
                      'Precio y Stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Precio
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (MXN)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un precio';
                        }
                        
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Ingrese un precio válido mayor a 0';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Stock Inicial / Actual
                    TextFormField(
                      controller: _currentStockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock actual',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el stock';
                        }
                        
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Ingrese un número válido (0 o mayor)';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Stock Mínimo
                    TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock mínimo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el stock mínimo';
                        }
                        
                        final minStock = int.tryParse(value);
                        if (minStock == null || minStock < 0) {
                          return 'Ingrese un número válido (0 o mayor)';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Imágenes
                    const Text(
                      'Imágenes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de imágenes
                    if (_imageUrls.isNotEmpty)
                      Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    // Añadir imagen
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageController,
                            decoration: const InputDecoration(
                              labelText: 'URL de imagen',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.image_outlined),
                              hintText: 'https://example.com/image.jpg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final url = _imageController.text.trim();
                            if (url.isNotEmpty) {
                              setState(() {
                                if (!_imageUrls.contains(url)) {
                                  _imageUrls.add(url);
                                }
                                _imageController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          child: const Text('Añadir'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Especificaciones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Especificaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddSpecificationDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lista de especificaciones
                    if (_specifications.isEmpty)
                      const Center(
                        child: Text(
                          'No hay especificaciones',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _specifications.length,
                        itemBuilder: (context, index) {
                          final entry = _specifications.entries.elementAt(index);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              title: Text(
                                _formatSpecName(entry.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(entry.value.toString()),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _specifications.remove(entry.key);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

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
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveProduct,
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

  Future<void> _showAddSpecificationDialog() async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Especificación'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Característica',
                  hintText: 'Ej: Procesador, RAM, Material',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la característica';
                  }
                  
                  if (_specifications.containsKey(value)) {
                    return 'Esta característica ya existe';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Ej: Intel Core i5, 8GB, Madera',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el valor';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _specifications[keyController.text] = valueController.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
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
    };
    
    return translations[name.toLowerCase()] ?? 
           name.split('_')
               .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
               .join(' ');
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, agregue al menos una imagen'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        if (_isEditing) {
          await _productService.updateProduct(
            id: widget.product!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            price: double.parse(_priceController.text),
            categoryId: _selectedCategory,
            supplierId: _selectedSupplier,
            currentStock: int.parse(_currentStockController.text),
            minimumStock: int.parse(_minStockController.text),
            imageUrls: _imageUrls,
            specifications: _specifications,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Crear nuevo producto
          await _productService.createProduct(
            name: _nameController.text,
            description: _descriptionController.text,
            price: double.parse(_priceController.text),
            categoryId: _selectedCategory,
            supplierId: _selectedSupplier,
            currentStock: int.parse(_currentStockController.text),
            minimumStock: int.parse(_minStockController.text),
            imageUrls: _imageUrls,
            specifications: _specifications,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto agregado exitosamente'),
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
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
} 