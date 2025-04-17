import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/screens/more/customers/customer_detail_screen.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
  
  // Controlador para el monto equivalente en la otra moneda
  final TextEditingController _equivalentAmountController = TextEditingController();
  
  // Flag para saber si el usuario está ingresando en bolívares
  bool _isAmountInBs = false;
  
  @override
  void initState() {
    super.initState();
    _loadDebtDetails();
    
    // Escuchar cambios en el campo de monto para actualizar el equivalente
    _amountController.addListener(_updateEquivalentAmount);
    
    // Inicializar el método de pago como USD por defecto
    _isAmountInBs = false;
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _equivalentAmountController.dispose();
    super.dispose();
  }
  
  // Actualiza el monto equivalente basado en el monto ingresado y el método de pago
  void _updateEquivalentAmount() {
    if (_amountController.text.isEmpty) {
      _equivalentAmountController.text = '';
      return;
    }
    
    try {
      final amount = double.parse(_amountController.text);
      
      if (_isAmountInBs) {
        // Convertir de Bs a USD
        final amountInUsd = amount / Product.exchangeRate;
        _equivalentAmountController.text = amountInUsd.toStringAsFixed(2);
      } else {
        // Convertir de USD a Bs
        final amountInBs = amount * Product.exchangeRate;
        _equivalentAmountController.text = amountInBs.toStringAsFixed(2);
      }
    } catch (e) {
      _equivalentAmountController.text = '';
    }
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
  
  // Actualiza el flag de moneda según el método de pago seleccionado
  void _updateCurrencyFlag(PaymentMethod method) {
    setState(() {
      // Para métodos electrónicos y efectivo en bolivares, el monto se ingresa en Bs
      _isAmountInBs = method == PaymentMethod.cashBs || 
                     method == PaymentMethod.bankTransfer || 
                     method == PaymentMethod.mobilePayment;
      
      // Limpiar los campos para evitar confusiones
      _amountController.clear();
      _equivalentAmountController.clear();
    });
  }
  
  Future<void> _copyToClipboard(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _callCustomer() async {
    if (_customer == null) return;
    
    final url = 'tel:${_customer!.phone}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo realizar la llamada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendWhatsAppMessage() async {
    if (_customer == null) return;
    
    // Limpiar el número de teléfono
    String cleanPhone = _customer!.phone.replaceAll(RegExp(r'\s+|\(|\)|\-'), '');
    
    // Si no comienza con +, agregamos el código de país (asumiendo Venezuela +58)
    if (!cleanPhone.startsWith('+')) {
      // Si comienza con 0, lo reemplazamos por +58
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+58${cleanPhone.substring(1)}';
      } else {
        cleanPhone = '+58$cleanPhone';
      }
    }
    
    final url = 'https://wa.me/$cleanPhone';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCustomerDetails() {
    if (_customer == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customerId: _customer!.id),
      ),
    );
  }
  
  // Registrar un pago para la deuda
  Future<void> _registerPayment() async {
    // Validar monto
    final amountText = _amountController.text;
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un monto válido mayor a cero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Calcular el monto en USD para validación (independientemente de cómo se ingresó)
    double amountInUsd;
    if (_isAmountInBs) {
      // El monto se ingresó en Bs, convertir a USD
      amountInUsd = amount / Product.exchangeRate;
    } else {
      // El monto ya está en USD
      amountInUsd = amount;
    }
    
    // Validar que el monto no sea mayor al saldo pendiente
    if (amountInUsd > _debt!.pendingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El monto no puede ser mayor al saldo pendiente (USD ${_debt!.pendingAmount.toStringAsFixed(2)})'),
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
      // Calcular el monto a registrar según la moneda seleccionada
      final amountToRegister = _isAmountInBs ? amount : amount;
      
      // Registrar el pago
      final success = await _saleService.registerDebtPayment(
        debtId: _debt!.id,
        method: _selectedPaymentMethod,
        amount: amountToRegister,
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
        _equivalentAmountController.clear();
        
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
      elevation: 0,
      color: _debt!.isPaid
          ? Colors.green.shade50
          : isOverdue
              ? Colors.red.shade50
              : AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Deuda #${_debt!.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
          
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Creada: ${DateFormat('dd/MM/yyyy').format(_debt!.createdAt)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Vence: ${DateFormat('dd/MM/yyyy').format(_debt!.dueDate)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Atrasado por $daysLate días',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 24),
            _buildAmountRow('Monto Total', _debt!.totalAmount),
            const SizedBox(height: 8),
            _buildAmountRow(
              'Pagado', 
              _debt!.paidAmount, 
              color: _debt!.paidAmount > 0 ? Colors.green : Colors.grey
            ),
            if (!_debt!.isPaid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildAmountRow(
                  'Pendiente', 
                  _debt!.pendingAmount, 
                  color: Colors.red,
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmountRow(String label, double amount, {Color? color, double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? 16,
                color: color,
              ),
            ),
            Text(
              'Bs. ${(amount * Product.exchangeRate).toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCustomerInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _customer != null ? _navigateToCustomerDetails : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información del Cliente'),
              const SizedBox(height: 16),
              if (_customer != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _customer!.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${_customer!.documentType}: ${_customer!.documentId}'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _customer!.isActive 
                                    ? const Color(0xFFE6F7ED)
                                    : const Color(0xFFFFE9EC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _customer!.isActive ? 'ACTIVO' : 'INACTIVO',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _customer!.isActive
                                      ? const Color(0xFF0D9145)
                                      : const Color(0xFFD93644),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.phone_outlined,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teléfono',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _customer!.phone,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            _customer!.phone, 
                            'Teléfono copiado al portapapeles'
                          ),
                          icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                          tooltip: 'Copiar teléfono',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _callCustomer,
                          icon: const Icon(Icons.phone),
                          label: const Text('Llamar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _sendWhatsAppMessage,
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }
  
  Widget _buildPaymentsList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Pagos Realizados'),
                Text(
                  '${_debt!.payments.length} pagos',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_debt!.payments.isEmpty)
              Container(
                width: double.infinity, 
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Text(
                    'No hay pagos registrados',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              for (var payment in _debt!.payments) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPaymentIcon(payment.method),
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPaymentMethodName(payment.method),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(payment.date)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty)
                              Text(
                                'Ref: ${payment.referenceNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Mostramos el monto en la moneda original del pago
                          if (payment.method == PaymentMethod.cashBs || 
                              payment.method == PaymentMethod.bankTransfer || 
                              payment.method == PaymentMethod.mobilePayment)
                            Text(
                              'Bs. ${payment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          else
                            Text(
                              '\$${payment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          
                          // Mostramos el equivalente en la otra moneda
                          if (payment.method == PaymentMethod.cashBs || 
                              payment.method == PaymentMethod.bankTransfer || 
                              payment.method == PaymentMethod.mobilePayment)
                            Text(
                              '\$${(payment.amount / Product.exchangeRate).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            )
                          else
                            Text(
                              'Bs. ${(payment.amount * Product.exchangeRate).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (payment != _debt!.payments.last)
                  const SizedBox(height: 12),
              ],
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
  
  Widget _buildNewPaymentForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Registrar Nuevo Pago'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                            const Icon(Icons.attach_money, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Efectivo (USD)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.cashBs,
                        child: Row(
                          children: [
                            const Icon(Icons.money, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text('Efectivo (Bs)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.bankTransfer,
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            const Text('Transferencia Bancaria (Bs)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.mobilePayment,
                        child: Row(
                          children: [
                            const Icon(Icons.phone_android, size: 18, color: Colors.purple),
                            const SizedBox(width: 8),
                            const Text('Pago Móvil (Bs)'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                          _updateCurrencyFlag(value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: _isAmountInBs 
                          ? 'Monto en Bs.' 
                          : 'Monto en USD',
                      helperText: _isAmountInBs
                          ? 'Máximo: Bs. ${(_debt!.pendingAmount * Product.exchangeRate).toStringAsFixed(2)}'
                          : 'Máximo: \$${_debt!.pendingAmount.toStringAsFixed(2)}',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        _isAmountInBs ? Icons.money : Icons.attach_money,
                        color: _isAmountInBs ? Colors.blue : Colors.green,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _equivalentAmountController,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: _isAmountInBs 
                          ? 'Equivalente en USD' 
                          : 'Equivalente en Bs.',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(
                        _isAmountInBs ? Icons.attach_money : Icons.money,
                        color: Colors.grey,
                      ),
                    ),
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
                          prefixIcon: Icon(Icons.numbers, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                ],
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
  
  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashUSD:
      case PaymentMethod.cashBs:
        return Icons.payments_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.mobilePayment:
        return Icons.phone_android_outlined;
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card_outlined;
      case PaymentMethod.debt:
        return Icons.access_time;
    }
  }
} 