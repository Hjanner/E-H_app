import 'package:flutter/material.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/widgets/customer_card.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  bool _showInactive = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await _customerService.getAllCustomers();
      
      if (mounted) {
        setState(() {
          _customers = customers;
          _filteredCustomers = customers; // Inicializar con todos los clientes
          _isLoading = false;
        });
        
        // Si hay filtros aplicados, actualizarlos
        if (_searchQuery.isNotEmpty || _showInactive) {
          _applyFilters();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredCustomers = []; // En caso de error, mostrar lista vacía
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyFilters() async {
    try {
      final filteredList = await _customerService.filterCustomers(
        searchQuery: _searchQuery,
        showInactive: _showInactive,
      );
      
      if (mounted) {
        setState(() {
          _filteredCustomers = filteredList;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al filtrar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters(); // Ya no necesita ser await aquí porque _applyFilters maneja internamente el async
  }

  void _toggleShowInactive() {
    setState(() {
      _showInactive = !_showInactive;
    });
    _applyFilters(); // Ya no necesita ser await aquí porque _applyFilters maneja internamente el async
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar al cliente ${customer.fullName}?'),
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

    if (confirm == true) {
      try {
        final success = await _customerService.deleteCustomer(customer.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCustomers();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar el cliente. Podría tener ventas asociadas.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar cliente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleCustomerStatus(Customer customer) async {
    try {
      final success = await _customerService.toggleCustomerStatus(customer.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              customer.isActive
                  ? 'Cliente desactivado'
                  : 'Cliente activado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadCustomers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.pushNamed(
      context,
      '/customer_detail',
      arguments: customer.id,
    ).then((_) {
      _loadCustomers();
    });
  }

  void _navigateToCustomerForm({Customer? customer}) {
    Navigator.pushNamed(
      context,
      '/customer_form',
      arguments: customer,
    ).then((result) {
      if (result == true) {
        _loadCustomers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // Botón para recargar la lista
          IconButton(
            onPressed: _loadCustomers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar lista',
          ),
          const SizedBox(width: 5)
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, documento, etc.',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          Container(   
            padding: const EdgeInsets.only(left: 20),
            alignment: Alignment.centerLeft,      
            child:                       
              Text(
              '${_filteredCustomers.length} clientes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Lista de clientes
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron clientes',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToCustomerForm(),
                              icon: const Icon(Icons.add, color: Colors.white,),
                              label: const Text('Agregar cliente'),
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
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CustomerCard(
                                customer: customer,
                                onTap: () => _navigateToCustomerDetail(customer),
                                onToggleStatus: () => _toggleCustomerStatus(customer),
                                //onDelete: () => _confirmDelete(customer),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCustomerForm(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
} 