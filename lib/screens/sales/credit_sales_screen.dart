import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CreditSalesScreen extends StatefulWidget {
  const CreditSalesScreen({Key? key}) : super(key: key);

  @override
  State<CreditSalesScreen> createState() => _CreditSalesScreenState();
}

class _CreditSalesScreenState extends State<CreditSalesScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  
  bool _isLoading = true;
  List<Sale> _creditSales = [];
  String _searchQuery = '';
  
  // Formato de moneda
  final currencyFormat = NumberFormat.currency(
    locale: 'es_VE',
    symbol: 'Bs. ',
    decimalDigits: 2,
  );
  
  // Formato de fecha
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadCreditSales();
  }

  Future<void> _loadCreditSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final creditSales = await _saleService.getCreditSales();
      setState(() {
        _creditSales = creditSales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ventas a crédito: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filtrar ventas a crédito por búsqueda
  List<Sale> get _filteredSales {
    if (_searchQuery.isEmpty) {
      return _creditSales;
    }
    
    final query = _searchQuery.toLowerCase();
    return _creditSales.where((sale) {
      final customerNameMatch = sale.customerName?.toLowerCase().contains(query) ?? false;
      final idMatch = sale.id.toLowerCase().contains(query);
      
      return customerNameMatch || idMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas a Crédito'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/sales/new').then((_) => _loadCreditSales());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_creditSales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay ventas a crédito',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las ventas a crédito aparecerán aquí',
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
              hintText: 'Buscar por cliente o ID',
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
        
        // Resumen de deudas
        _buildDebtSummary(),
        
        // Lista de ventas a crédito
        Expanded(
          child: _filteredSales.isEmpty
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
                  itemCount: _filteredSales.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return _buildCreditSaleCard(_filteredSales[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDebtSummary() {
    double totalDebt = _creditSales.fold(
      0, 
      (sum, sale) => sum + sale.pendingAmount
    );
    
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
                currencyFormat.format(totalDebt),
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
                'Ventas a crédito',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_creditSales.length}',
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

  Widget _buildCreditSaleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _navigateToSaleDetail(sale),
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
                          sale.customerName ?? 'Cliente no registrado',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${sale.id.substring(0, 8)}',
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Sale.getStatusColor(sale.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      Sale.statusToString(sale.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Sale.getStatusColor(sale.status),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(sale.date),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(sale.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progreso de pago
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pagado: ${currencyFormat.format(sale.paidAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Pendiente: ${currencyFormat.format(sale.pendingAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: sale.total > 0 ? sale.paidAmount / sale.total : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (sale.pendingAmount > 0)
                    ElevatedButton.icon(
                      onPressed: () => _registerPayment(sale),
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Registrar Pago'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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

  void _navigateToSaleDetail(Sale sale) async {
    await Navigator.pushNamed(
      context,
      '/sales/detail',
      arguments: {'saleId': sale.id},
    );
    _loadCreditSales();
  }

  void _registerPayment(Sale sale) async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${sale.customerName ?? "Cliente no registrado"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pendiente: ${currencyFormat.format(sale.pendingAmount)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Método de pago
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem<PaymentMethod>(
                      value: method,
                      child: Row(
                        children: [
                          Icon(Sale.getPaymentMethodIcon(method), size: 18),
                          const SizedBox(width: 8),
                          Text(Sale.paymentMethodToString(method)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Monto
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto a pagar',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // Referencia (para transferencias, etc.)
                if (selectedMethod != PaymentMethod.cash)
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Referencia',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validar que el monto sea válido
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe ingresar un monto'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                try {
                  final amount = double.parse(amountController.text);
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El monto debe ser mayor a cero'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  if (amount > sale.pendingAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El monto no puede ser mayor al pendiente'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monto inválido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true && mounted) {
      try {
        // Crear el detalle de pago
        final payment = await _saleService.createPaymentDetail(
          saleId: sale.id,
          method: selectedMethod,
          amount: double.parse(amountController.text),
          currency: selectedMethod == PaymentMethod.foreignCash ? PaymentCurrency.usd : PaymentCurrency.bsf,
          reference: referenceController.text.isEmpty ? null : referenceController.text,
        );
        
        // Registrar el pago
        final success = await _saleService.addPaymentToSale(sale.id, payment);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pago registrado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCreditSales();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al registrar el pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 