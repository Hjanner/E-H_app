import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/widgets/section_title.dart';

class PaymentForm extends StatefulWidget {
  final double pendingAmount;
  final Function(PaymentMethod method, double amount, String? reference) onSubmit;
  final String title;
  final bool isProcessing;

  const PaymentForm({
    Key? key,
    required this.pendingAmount,
    required this.onSubmit,
    this.title = 'Registrar Nuevo Pago',
    this.isProcessing = false,
  }) : super(key: key);

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
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
    // Escuchar cambios en el campo de monto para actualizar el equivalente
    _amountController.addListener(_updateEquivalentAmount);
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

  // Validar y registrar un pago
  void _registerPayment() {
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
    if (amountInUsd > widget.pendingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El monto no puede ser mayor al saldo pendiente (USD ${widget.pendingAmount.toStringAsFixed(2)})'),
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

    String? reference = null;
    if (_selectedPaymentMethod == PaymentMethod.bankTransfer || 
        _selectedPaymentMethod == PaymentMethod.mobilePayment) {
      reference = _referenceController.text;
    }
    
    // Llamar al callback con los datos necesarios
    widget.onSubmit(
      _selectedPaymentMethod, 
      _isAmountInBs ? amount : amount, 
      reference
    );

    // Limpiar los campos
    _amountController.clear();
    _referenceController.clear();
    _equivalentAmountController.clear();
  }

  @override
  Widget build(BuildContext context) {
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
            SectionTitle(title: widget.title),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          ? 'Máximo: Bs. ${(widget.pendingAmount * Product.exchangeRate).toStringAsFixed(2)}'
                          : 'Máximo: \$${widget.pendingAmount.toStringAsFixed(2)}',
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
                onPressed: widget.isProcessing ? null : _registerPayment,
                icon: widget.isProcessing
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
                label: Text(widget.isProcessing ? 'Procesando...' : 'Registrar Pago'),
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
} 