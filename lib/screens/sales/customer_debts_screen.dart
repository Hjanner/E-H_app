import 'package:flutter/material.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CustomerDebtsScreen extends StatefulWidget {
  const CustomerDebtsScreen({Key? key}) : super(key: key);

  @override
  State<CustomerDebtsScreen> createState() => _CustomerDebtsScreenState();
}

class _CustomerDebtsScreenState extends State<CustomerDebtsScreen> {
  final CustomerService _customerService = CustomerService();
  final SaleService _saleService = SaleService();

  bool _isLoading = true;
  List<Customer> _customers = [];
  Map<String, Map<String, dynamic>> _customerDebts = {};
  String _searchQuery = '';

  // Formato de moneda
  final currencyFormat = NumberFormat.currency(
    locale: 'es_VE',
    symbol: 'Bs. ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadCustomersWithDebts();
  }

  Future<void> _loadCustomersWithDebts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todos los clientes activos
      final customers = await _customerService.getActiveCustomers();
      
      // Filtrar solo clientes con deudas y obtener montos
      Map<String, Map<String, dynamic>> customerDebts = {};
      
      for (var customer in customers) {
        final debtInfo = await _saleService.getTotalDebtByCustomer(customer.id);
        
        if (debtInfo['totalDebt']! > 0) {
          customerDebts[customer.id] = {
            'customer': customer,
            'totalDebt': debtInfo['totalDebt'],
            'salesCount': debtInfo['salesCount']?.toInt() ?? 0,
          };
        }
      }
      
      setState(() {
        _customers = customers;
        _customerDebts = customerDebts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filtrar clientes por búsqueda
  List<String> get _filteredCustomerIds {
    if (_searchQuery.isEmpty) {
      return _customerDebts.keys.toList();
    }
    
    final query = _searchQuery.toLowerCase();
    return _customerDebts.keys.where((customerId) {
      final customerInfo = _customerDebts[customerId];
      final customer = customerInfo?['customer'] as Customer;
      
      return customer.fullName.toLowerCase().contains(query) ||
             customer.documentId.toLowerCase().contains(query) ||
             customer.phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Deudas'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_customerDebts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay clientes con deudas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todas las deudas han sido pagadas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar cliente',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // Resumen de deudas totales
        _buildDebtsSummary(),
        
        // Lista de clientes con deudas
        Expanded(
          child: _filteredCustomerIds.isEmpty
              ? Center(
                  child: Text(
                    'No se encontraron resultados para "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredCustomerIds.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final customerId = _filteredCustomerIds[index];
                    final customerInfo = _customerDebts[customerId]!;
                    final customer = customerInfo['customer'] as Customer;
                    final totalDebt = customerInfo['totalDebt'] as double;
                    final salesCount = customerInfo['salesCount'] as int;
                    
                    return _buildCustomerDebtCard(customer, totalDebt, salesCount);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDebtsSummary() {
    double totalDebts = 0;
    int totalDebtors = _customerDebts.length;
    
    _customerDebts.forEach((_, info) {
      totalDebts += info['totalDebt'] as double;
    });
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total deudas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(totalDebts),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Clientes con deudas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalDebtors',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDebtCard(Customer customer, double totalDebt, int salesCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _navigateToCustomerDebts(customer),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${customer.documentId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$salesCount ${salesCount == 1 ? 'venta' : 'ventas'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Teléfono: ${customer.phone}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    currencyFormat.format(totalDebt),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showCustomerDebtDetails(customer),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _registerPayment(customer, totalDebt),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Registrar Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCustomerDebts(Customer customer) async {
    // Navegar a las ventas a crédito filtradas por cliente
    await Navigator.pushNamed(
      context,
      '/sales/credit',
      arguments: {'customerId': customer.id},
    );
    _loadCustomersWithDebts();
  }

  Future<void> _showCustomerDebtDetails(Customer customer) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sales = await _saleService.getSalesByCustomer(customer.id);
      final creditSales = sales.where((sale) => 
        sale.status == SaleStatus.credit || 
        (sale.pendingAmount > 0 && sale.status != SaleStatus.cancelled)
      ).toList();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Mostrar diálogo con los detalles
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Deudas de ${customer.fullName}'),
          content: creditSales.isEmpty 
              ? const Text('No hay deudas pendientes')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: creditSales.length,
                    itemBuilder: (context, index) {
                      final sale = creditSales[index];
                      final dateFormat = DateFormat('dd/MM/yyyy');
                      
                      return ListTile(
                        title: Text('Venta #${sale.id.substring(0, 8)}'),
                        subtitle: Text('Fecha: ${dateFormat.format(sale.date)}'),
                        trailing: Text(
                          currencyFormat.format(sale.pendingAmount),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/sales/detail',
                            arguments: {'saleId': sale.id},
                          ).then((_) => _loadCustomersWithDebts());
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerPayment(Customer customer, double totalDebt) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sales = await _saleService.getSalesByCustomer(customer.id);
      final creditSales = sales.where((sale) => 
        sale.status == SaleStatus.credit || 
        (sale.pendingAmount > 0 && sale.status != SaleStatus.cancelled)
      ).toList();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (creditSales.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay deudas pendientes para este cliente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Navegar a los detalles de la venta para registrar el pago
      // En caso de múltiples ventas, mostrar lista para seleccionar
      if (creditSales.length == 1) {
        Navigator.pushNamed(
          context,
          '/sales/detail',
          arguments: {'saleId': creditSales.first.id},
        ).then((_) => _loadCustomersWithDebts());
      } else {
        // Mostrar diálogo para seleccionar la venta
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Seleccionar Venta para Pago'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: creditSales.length,
                itemBuilder: (context, index) {
                  final sale = creditSales[index];
                  final dateFormat = DateFormat('dd/MM/yyyy');
                  
                  return ListTile(
                    title: Text('Venta #${sale.id.substring(0, 8)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${dateFormat.format(sale.date)}'),
                        Text(
                          'Pendiente: ${currencyFormat.format(sale.pendingAmount)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/sales/detail',
                        arguments: {'saleId': sale.id},
                      ).then((_) => _loadCustomersWithDebts());
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 