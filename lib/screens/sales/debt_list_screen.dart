import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'debt_detail_screen.dart';
import 'package:intl/intl.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Debt> _debts = [];
  List<Debt> _filteredDebts = [];
  Map<String, Customer> _customersCache = {};
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadDebts();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final debts = await _saleService.getAllDebts();
      
      if (mounted) {
        setState(() {
          _debts = debts;
          _filteredDebts = debts;
          _isLoading = false;
        });
        
        // Precargar información de clientes
        _preloadCustomers();
        
        // Aplicar filtros si hay alguno
        if (_searchQuery.isNotEmpty) {
          _filterDebts();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar deudas: $e'),
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
      final Set<String> customerIds = _debts.map((debt) => debt.customerId).toSet();
      
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
  
  void _filterDebts() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredDebts = _debts;
      });
      return;
    }
    
    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredDebts = _debts.where((debt) {
        // Verificar si el cliente está en caché
        final customer = _customersCache[debt.customerId];
        final String customerName = customer != null 
            ? '${customer.firstName} ${customer.lastName}'.toLowerCase() 
            : '';
        
        // Buscar por ID de deuda, cliente, o fecha de vencimiento
        return debt.id.toLowerCase().contains(query) ||
               customerName.contains(query) ||
               DateFormat('dd/MM/yyyy').format(debt.dueDate).contains(query);
      }).toList();
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterDebts();
  }
  
  Future<void> _refreshDebts() async {
    await _loadDebts();
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
              hintText: 'Buscar deudas...',
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
              : _filteredDebts.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron deudas pendientes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshDebts,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDebts.length,
                        itemBuilder: (context, index) {
                          final debt = _filteredDebts[index];
                          final customer = _customersCache[debt.customerId];
                          final customerName = customer != null 
                              ? '${customer.firstName} ${customer.lastName}'
                              : 'Cliente #${debt.customerId}';
                          
                          // Calcular días de atraso
                          final now = DateTime.now();
                          final daysLate = debt.isPaid ? 0 : now.difference(debt.dueDate).inDays;
                          final isOverdue = daysLate > 0 && !debt.isPaid;
                          
                          return Card(
                            color: AppTheme.cardBackground,
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: _buildPaymentStatusIcon(debt.isPaid, isOverdue),
                              title: Text(
                                'Deuda #${debt.id.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cliente: $customerName'),
                                  Text('Vence: ${DateFormat('dd/MM/yyyy').format(debt.dueDate)}'),
                                  if (isOverdue)
                                    Text(
                                      'Atrasado: $daysLate días',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  Text(
                                    'Estado: ${debt.isPaid ? "Pagado" : "Pendiente"}',
                                    style: TextStyle(
                                      color: debt.isPaid ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${debt.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!debt.isPaid)
                                    Text(
                                      'Pendiente: \$${debt.pendingAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DebtDetailScreen(debtId: debt.id),
                                  ),
                                ).then((_) => _refreshDebts());
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
      ],
    );
  }
  
  Widget _buildPaymentStatusIcon(bool isPaid, bool isOverdue) {
    IconData icon;
    Color color;
    
    if (isPaid) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (isOverdue) {
      icon = Icons.warning;
      color = Colors.red;
    } else {
      icon = Icons.schedule;
      color = Colors.orange;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
} 