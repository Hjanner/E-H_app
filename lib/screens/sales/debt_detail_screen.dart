import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DebtDetailScreen extends StatefulWidget {
  final String debtId;
  
  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  Debt? _debt;
  Sale? _sale;
  Customer? _customer;
  String? _errorMessage;
  
  // Para registrar nuevo pago
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashUSD;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadDebtDetails();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDebtDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener lista de todas las deudas
      final allDebts = await _saleService.getAllDebts();
      
      // Buscar la deuda por ID
      final debt = allDebts.firstWhere(
        (d) => d.id == widget.debtId,
        orElse: () => throw Exception('Deuda no encontrada'),
      );
      
      // Cargar la venta relacionada
      final sale = await _saleService.getSaleById(debt.saleId);
      
      if (sale == null) {
        throw Exception('Venta relacionada no encontrada');
      }
      
      // Cargar información del cliente
      final customer = await _customerService.getCustomerById(debt.customerId);
      
      if (mounted) {
        setState(() {
          _debt = debt;
          _sale = sale;
          _customer = customer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar detalles: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Registrar un pago para la deuda
  Future<void> _registerPayment() async {
    // Validar monto
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validar que el monto no sea mayor al saldo pendiente
    if (amount > _debt!.pendingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto no puede ser mayor al saldo pendiente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validar referencia para métodos que la requieren
    if ((_selectedPaymentMethod == PaymentMethod.bankTransfer || 
         _selectedPaymentMethod == PaymentMethod.mobilePayment) && 
        _referenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un número de referencia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessingPayment = true;
    });
    
    try {
      // Registrar el pago
      final success = await _saleService.registerDebtPayment(
        debtId: _debt!.id,
        method: _selectedPaymentMethod,
        amount: amount,
        referenceNumber: (_selectedPaymentMethod == PaymentMethod.bankTransfer || 
                          _selectedPaymentMethod == PaymentMethod.mobilePayment)
            ? _referenceController.text
            : null,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar campos
        _amountController.clear();
        _referenceController.clear();
        
        // Recargar datos
        _loadDebtDetails();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el pago'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessingPayment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        title: Text('Deuda #${widget.debtId.substring(0, 8)}'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDebtDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _debt == null
                  ? const Center(
                      child: Text('No se encontró la deuda'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDebtHeader(),
                          const SizedBox(height: 24),
                          _buildCustomerInfo(),
                          const SizedBox(height: 24),
                          _buildPaymentsList(),
                          const SizedBox(height: 24),
                          if (!_debt!.isPaid)
                            _buildNewPaymentForm(),
                        ],
                      ),
                    ),
    );
  }
  
  Widget _buildDebtHeader() {
    // Calcular días de atraso
    final now = DateTime.now();
    final daysLate = _debt!.isPaid ? 0 : now.difference(_debt!.dueDate).inDays;
    final isOverdue = daysLate > 0 && !_debt!.isPaid;
    
    return Card(
      color: _debt!.isPaid
          ? Colors.green.shade50
          : isOverdue
              ? Colors.red.shade50
              : AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deuda #${_debt!.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _debt!.isPaid
                        ? Colors.green.withOpacity(0.1)
                        : isOverdue
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _debt!.isPaid
                        ? 'Pagado'
                        : isOverdue
                            ? 'Atrasado'
                            : 'Pendiente',
                    style: TextStyle(
                      color: _debt!.isPaid
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Creada: ${DateFormat('dd/MM/yyyy').format(_debt!.createdAt)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'Vence: ${DateFormat('dd/MM/yyyy').format(_debt!.dueDate)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Atrasado por $daysLate días',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monto Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_debt!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pagado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_debt!.paidAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _debt!.paidAmount > 0 ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            if (!_debt!.isPaid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pendiente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_debt!.pendingAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_customer != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customer!.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${_customer!.documentType}: ${_customer!.documentId}'),
                  const SizedBox(height: 4),
                  Text('Teléfono: ${_customer!.phone}'),
                  const SizedBox(height: 4),
                  Text('Email: ${_customer!.email}'),
                ],
              )
            else
              Text(
                'Cliente ID: ${_debt!.customerId}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pagos Realizados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_debt!.payments.length} pagos',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_debt!.payments.isEmpty)
              const Text(
                'No hay pagos registrados',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              )
            else
              for (var payment in _debt!.payments) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPaymentMethodName(payment.method),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(payment.date)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty)
                          Text(
                            'Ref: ${payment.referenceNumber}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    Text(
                      '\$${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (payment != _debt!.payments.last)
                  const Divider(height: 16),
              ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildNewPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar Nuevo Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: PaymentMethod.cashUSD,
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, size: 18),
                      const SizedBox(width: 8),
                      const Text('Efectivo (USD)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.cashBs,
                  child: Row(
                    children: [
                      const Icon(Icons.money, size: 18),
                      const SizedBox(width: 8),
                      const Text('Efectivo (Bs)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.bankTransfer,
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance, size: 18),
                      const SizedBox(width: 8),
                      const Text('Transferencia Bancaria'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.mobilePayment,
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, size: 18),
                      const SizedBox(width: 8),
                      const Text('Pago Móvil'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monto (máx. \$${_debt!.pendingAmount.toStringAsFixed(2)})',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            if (_selectedPaymentMethod == PaymentMethod.bankTransfer || 
                _selectedPaymentMethod == PaymentMethod.mobilePayment)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Número de referencia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessingPayment ? null : _registerPayment,
                icon: _isProcessingPayment
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isProcessingPayment ? 'Procesando...' : 'Registrar Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashUSD:
        return 'Efectivo (USD)';
      case PaymentMethod.cashBs:
        return 'Efectivo (Bs)';
      case PaymentMethod.bankTransfer:
        return 'Transferencia Bancaria';
      case PaymentMethod.mobilePayment:
        return 'Pago Móvil';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.debt:
        return 'A Crédito';
    }
  }
} 