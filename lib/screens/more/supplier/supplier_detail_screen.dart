import 'package:flutter/material.dart';
import 'package:ehstore_app/models/supplier.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/supplier_service.dart';
import 'package:ehstore_app/widgets/product_card.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supplier_form_screen.dart';
import '../../inventory/product_detail_screen.dart';
import 'package:flutter/services.dart';


class SupplierDetailScreen extends StatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({
    super.key,
    required this.supplierId,
  });

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final _supplierService = SupplierService();
  Supplier? _supplier;
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadSupplier();
  }

  Future<void> _loadSupplier() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supplier = await _supplierService.getSupplierById(widget.supplierId);
      
      setState(() {
        _supplier = supplier;
        _isLoading = false;
      });
      
      if (supplier != null) {
        _loadProducts(supplier.id);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proveedor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProducts(String supplierId) async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _supplierService.getProductsBySupplier(supplierId);
      
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editSupplier() async {
    if (_supplier == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormScreen(supplier: _supplier),
      ),
    );
    
    if (result == true && mounted) {
      _loadSupplier();
    }
  }

  Future<void> _toggleSupplierStatus() async {
    if (_supplier == null) return;
    
    try {
      final success = await _supplierService.toggleSupplierStatus(_supplier!.id);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _supplier!.isActive
                  ? 'Proveedor desactivado correctamente'
                  : 'Proveedor activado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadSupplier();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado del proveedor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteSupplier() async {
    if (_supplier == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Estás seguro de que deseas eliminar el proveedor "${_supplier!.businessName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      _deleteSupplier();
    }
  }

  Future<void> _deleteSupplier() async {
    if (_supplier == null) return;
    
    try {
      final success = await _supplierService.deleteSupplier(_supplier!.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proveedor eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede eliminar este proveedor porque tiene productos asociados'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar proveedor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToProductDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedor'),
        backgroundColor: AppTheme.backgroundColor,
        //shadowColor: Colors.grey.shade500,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: _supplier != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editSupplier,
                  tooltip: 'Editar',
                  color: AppTheme.primaryColor,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _toggleSupplierStatus();
                    } else if (value == 'delete') {
                      _confirmDeleteSupplier();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(
                          _supplier!.isActive
                              ? Icons.toggle_off_outlined
                              : Icons.toggle_on_outlined,
                          color: _supplier!.isActive
                              ? Colors.red
                              : AppTheme.primaryColor,
                        ),
                        title: Text(
                          _supplier!.isActive
                              ? 'Desactivar'
                              : 'Activar',
                          style: const TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Eliminar',
                          style: TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _supplier == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Proveedor no encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre comercial (título)
                      Text(
                        _supplier!.businessName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Estado del proveedor
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _supplier!.isActive 
                              ? const Color(0xFFE6F7ED)
                              : const Color(0xFFFFE9EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _supplier!.isActive ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _supplier!.isActive
                                ? const Color(0xFF0D9145)
                                : const Color(0xFFD93644),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sección de información de empresa
                      _buildSectionTitle('Información de la empresa'),
                      const SizedBox(height: 16),
                      
                      // RIF/NIT
                      _buildInfoItem(
                        icon: Icons.credit_card_outlined,
                        title: 'RIF/NIT',
                        value: _supplier!.taxId,
                      ),
                      
                      // Dirección
                      _buildInfoItem(
                        icon: Icons.location_on_outlined,
                        title: 'Dirección',
                        value: _supplier!.address,
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de contacto
                      _buildSectionTitle('Información de contacto'),
                      const SizedBox(height: 16),
                      
                      // Persona de contacto
                      _buildInfoItem(
                        icon: Icons.person_outlined,
                        title: 'Persona de contacto',
                        value: _supplier!.contactPerson,
                      ),
                      
                      // Para teléfono:
                      _buildInfoItem(
                        icon: Icons.phone_outlined,
                        title: 'Teléfono',
                        value: _supplier!.phone,
                        isPhone: true,
                      ),

                      // Para email:
                      _buildInfoItem(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: _supplier!.email,
                        isEmail: true,
                      ),
                    
                      // Sección de redes sociales y sitio web
                      if (_supplier!.instagram.isNotEmpty || _supplier!.mercadoLibre.isNotEmpty || _supplier!.website.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Redes sociales y sitio web'),
                        const SizedBox(height: 16),
                        
                        // Instagram
                        if (_supplier!.instagram.isNotEmpty)
                          _buildLinkItem(
                            icon: Icons.photo_camera_outlined,
                            title: 'Instagram',
                            value: _supplier!.instagram,
                            onTap: () => _launchUrl('https://www.instagram.com/${_supplier!.instagram.replaceAll('@', '')}'),
                          ),
                        
                        // Mercado Libre
                        if (_supplier!.mercadoLibre.isNotEmpty)
                          _buildLinkItem(
                            icon: Icons.shopping_cart_outlined,
                            title: 'Mercado Libre',
                            value: _supplier!.mercadoLibre,
                            onTap: () => _launchUrl('https://www.mercadolibre.com.ve/perfil/${_supplier!.mercadoLibre}'),
                          ),
                        
                        // Página web
                        if (_supplier!.website.isNotEmpty)
                          _buildLinkItem(
                            icon: Icons.language_outlined,
                            title: 'Página web',
                            value: _supplier!.website,
                            onTap: () => _launchUrl(_supplier!.website),
                          ),
                      ],
                      
                      // Notas
                      if (_supplier!.notes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Notas'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Text(_supplier!.notes),
                        ),
                      ],
                      
                      // Productos del proveedor
                      const SizedBox(height: 24),
                      _buildSectionTitle('Productos suministrados'),
                      const SizedBox(height: 16),
                      
                      _isLoadingProducts
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              ),
                            )
                          : _products.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Este proveedor no tiene productos asociados',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _products.length,
                                  itemBuilder: (context, index) {
                                    return ProductCard(
                                      product: _products[index],
                                      onTap: () => _navigateToProductDetail(_products[index]),
                                    );
                                  },
                                ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

Widget _buildInfoItem({
  required IconData icon,
  required String title,
  required String value,
  bool isPhone = false,
  bool isEmail = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Añadir botón de copiar solo para teléfono y email
        if (isPhone || isEmail)
          IconButton(
            icon: const Icon(Icons.content_copy, size: 20, color: Colors.grey,),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isPhone 
                        ? 'Número copiado al portapapeles' 
                        : 'Email copiado al portapapeles',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            tooltip: 'Copiar al portapapeles',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    ),
  );
}

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.grey,),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede abrir el enlace'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 