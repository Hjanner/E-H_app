import 'package:flutter/material.dart';
import 'package:ehstore_app/models/supplier.dart';
import 'package:ehstore_app/services/supplier_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({
    super.key,
    this.supplier,
  });

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _notesController = TextEditingController();
  final _instagramController = TextEditingController();
  final _mercadoLibreController = TextEditingController();
  final _websiteController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEditing = false;

  final _supplierService = SupplierService();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.supplier != null;
    
    if (_isEditing) {
      final supplier = widget.supplier!;
      _businessNameController.text = supplier.businessName;
      _legalNameController.text = supplier.legalName;
      _taxIdController.text = supplier.taxId;
      _addressController.text = supplier.address;
      _phoneController.text = supplier.phone;
      _emailController.text = supplier.email;
      _contactPersonController.text = supplier.contactPerson;
      _notesController.text = supplier.notes;
      _instagramController.text = supplier.instagram;
      _mercadoLibreController.text = supplier.mercadoLibre;
      _websiteController.text = supplier.website;
      _isActive = supplier.isActive;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _notesController.dispose();
    _instagramController.dispose();
    _mercadoLibreController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Actualizar proveedor existente
        final success = await _supplierService.updateSupplier(
          id: widget.supplier!.id,
          businessName: _businessNameController.text,
          legalName: _legalNameController.text,
          taxId: _taxIdController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          contactPerson: _contactPersonController.text,
          isActive: _isActive,
          notes: _notesController.text,
          instagram: _instagramController.text,
          mercadoLibre: _mercadoLibreController.text,
          website: _websiteController.text,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proveedor actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al actualizar proveedor'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Crear nuevo proveedor
        await _supplierService.createSupplier(
          businessName: _businessNameController.text,
          legalName: _legalNameController.text,
          taxId: _taxIdController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          contactPerson: _contactPersonController.text,
          isActive: _isActive,
          notes: _notesController.text,
          instagram: _instagramController.text,
          mercadoLibre: _mercadoLibreController.text,
          website: _websiteController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proveedor creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
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
                    // Información de la empresa
                    const Text(
                      'Información de la empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nombre comercial
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre comercial',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre comercial';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Razón social
                    TextFormField(
                      controller: _legalNameController,
                      decoration: const InputDecoration(
                        labelText: 'Razón social',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_center_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la razón social';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // RIF/NIT
                    TextFormField(
                      controller: _taxIdController,
                      decoration: const InputDecoration(
                        labelText: 'RIF/NIT',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el RIF/NIT';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Dirección
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la dirección';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    
                    // Información de contacto
                    const Text(
                      'Información de contacto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Teléfono
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un número de teléfono';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un correo electrónico';
                        }
                        
                        // Validación simple de formato de email
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Por favor ingrese un correo electrónico válido';
                        }
                        
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Persona de contacto
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Persona de contacto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre de la persona de contacto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Redes sociales y sitio web
                    const Text(
                      'Redes sociales y sitio web',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Instagram
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.photo_camera_outlined),
                        hintText: '@usuario',
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    
                    // Mercado Libre
                    TextFormField(
                      controller: _mercadoLibreController,
                      decoration: const InputDecoration(
                        labelText: 'Mercado Libre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_cart_outlined),
                        hintText: 'tienda_oficial',
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    
                    // Página web
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Página web',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language_outlined),
                        hintText: 'https://www.ejemplo.com',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    
                    // Información adicional
                    const Text(
                      'Información adicional',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Estado (activo/inactivo)
                    SwitchListTile(
                      title: const Text('Estado del proveedor'),
                      subtitle: Text(
                        _isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: _isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Notas
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
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
              onPressed: _saveSupplier,
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
} 