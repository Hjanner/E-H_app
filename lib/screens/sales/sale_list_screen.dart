import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'sale_detail_screen.dart';
import 'new_sale_screen.dart';
import 'package:intl/intl.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  Map<String, Customer> _customersCache = {};
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sales = await _saleService.getAllSales();
      
      if (mounted) {
        setState(() {
          _sales = sales;
          _filteredSales = sales;
          _isLoading = false;
        });
        
        // Precargar información de clientes
        _preloadCustomers();
        
        // Aplicar filtros si hay alguno
        if (_searchQuery.isNotEmpty) {
          _filterSales();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ventas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  
  // Precarga información de clientes para mostrar nombres
  Future<void> _preloadCustomers() async {
    try {
      // Obtener IDs únicos de clientes
      final Set<String> customerIds = _sales.map((sale) => sale.customerId).toSet();
      
      // Cargar información de clientes
      for (String id in customerIds) {
        if (!_customersCache.containsKey(id)) {
          final customer = await _customerService.getCustomerById(id);
          if (customer != null && mounted) {
            setState(() {
              _customersCache[id] = customer;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _filterSales() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredSales = _sales;
      });
      return;
    }
    
    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredSales = _sales.where((sale) {
        // Verificar si el cliente está en caché
        final customer = _customersCache[sale.customerId];
        final String customerName = customer != null 
            ? '${customer.firstName} ${customer.lastName}'.toLowerCase() 
            : '';
        
        // Buscar por ID de venta, cliente, o fecha
        return sale.id.toLowerCase().contains(query) ||
               customerName.contains(query) ||
               DateFormat('dd/MM/yyyy').format(sale.createdAt).contains(query);
      }).toList();
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterSales();
  }
  
  Future<void> _refreshSales() async {
    await _loadSales();
  }
  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar ventas...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : _filteredSales.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron ventas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshSales,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = _filteredSales[index];
                          final customer = _customersCache[sale.customerId];
                          final customerName = customer != null 
                              ? '${customer.firstName} ${customer.lastName}'
                              : 'Cliente #${sale.customerId}';
                          
                          return Card(
                            color: AppTheme.cardBackground,
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: _buildStatusIcon(sale.status),
                              title: Text(
                                'Venta #${sale.id.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cliente: $customerName'),
                                  Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt)}'),
                                  if (sale.status == SaleStatus.credit)
                                    Text(
                                      'Deuda: \$${(sale.total - sale.totalPaid).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                '\$${sale.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SaleDetailScreen(saleId: sale.id),
                                  ),
                                ).then((_) => _refreshSales());
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
        ),

                // Botón flotante para agregar producto
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewSaleScreen(),
                ),
              ).then((result) {
                if (result == true) {
                  _refreshSales();
                }
              });
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIcon(SaleStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case SaleStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SaleStatus.credit:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case SaleStatus.canceled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case SaleStatus.refunded:
        icon = Icons.replay;
        color = Colors.purple;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
} 