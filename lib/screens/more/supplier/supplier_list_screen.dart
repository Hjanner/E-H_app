import 'package:flutter/material.dart';
import 'package:ehstore_app/models/supplier.dart';
import 'package:ehstore_app/services/supplier_service.dart';
import 'package:ehstore_app/widgets/supplier_card.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'supplier_form_screen.dart';
import 'supplier_detail_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _supplierService = SupplierService();
  final _searchController = TextEditingController();
  
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  bool _showOnlyActive = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suppliers = await _supplierService.getAllSuppliers();
      setState(() {
        _suppliers = suppliers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proveedores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Supplier> filtered = _suppliers;
    
    // Filtrar por estado activo/inactivo
    if (_showOnlyActive) {
      filtered = filtered.where((supplier) => supplier.isActive).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((supplier) {
        return supplier.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.legalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.taxId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               supplier.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    setState(() {
      _filteredSuppliers = filtered;
    });
  }

  Future<void> _confirmDeleteSupplier(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Estás seguro de que deseas eliminar el proveedor "${supplier.businessName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.primaryColor),),
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
      _deleteSupplier(supplier);
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    try {
      final success = await _supplierService.deleteSupplier(supplier.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proveedor eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSuppliers();
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

  Future<void> _toggleSupplierStatus(Supplier supplier) async {
    try {
      final success = await _supplierService.toggleSupplierStatus(supplier.id);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              supplier.isActive
                  ? 'Proveedor desactivado correctamente'
                  : 'Proveedor activado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadSuppliers();
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

  Future<void> _navigateToSupplierForm({Supplier? supplier}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierFormScreen(supplier: supplier),
      ),
    );
    
    if (result == true && mounted) {
      _loadSuppliers();
    }
  }

  Future<void> _navigateToSupplierDetail(Supplier supplier) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDetailScreen(supplierId: supplier.id),
      ),
    );
    
    if (result == true && mounted) {
      _loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          
          // Lista de proveedores
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredSuppliers.isEmpty
                    ? _buildEmptyState()
                    : _buildSuppliersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToSupplierForm(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Campo de búsqueda con estilo mejorado
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar proveedores',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: 8),
          
          // Filtro de estado con mejor estilo
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: CheckboxListTile(
              title: const Text(
                'Mostrar solo proveedores activos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              value: _showOnlyActive,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _showOnlyActive = value;
                    _applyFilters();
                  });
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              dense: true,
              activeColor: AppTheme.primaryColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 70,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty && !_showOnlyActive
                ? 'No hay proveedores registrados'
                : _searchQuery.isNotEmpty
                    ? 'No se encontraron proveedores para "$_searchQuery"'
                    : 'No hay proveedores activos',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (_searchQuery.isEmpty && !_showOnlyActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Agrega tu primer proveedor para comenzar a gestionar tu inventario',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty && !_showOnlyActive)
            ElevatedButton.icon(
              onPressed: () => _navigateToSupplierForm(),
              icon: const Icon(Icons.add),
              label: const Text('Añadir proveedor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuppliersList() {
    return Container(
      //color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_filteredSuppliers.length} proveedores',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showOnlyActive ? Icons.check_circle : Icons.filter_alt,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showOnlyActive ? 'Activos' : 'Todos',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                              fontSize: 13,
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSuppliers,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredSuppliers.length,
                itemBuilder: (context, index) {
                  final supplier = _filteredSuppliers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SupplierCard(
                      supplier: supplier,
                      onTap: () => _navigateToSupplierDetail(supplier),
                      onToggleStatus: () => _toggleSupplierStatus(supplier),
                      onDelete: () => _confirmDeleteSupplier(supplier),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 