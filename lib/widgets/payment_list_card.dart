import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PaymentListCard extends StatelessWidget {
  final List<Payment> payments;
  final String title;
  final double totalAmount;
  final double totalPaid;
  final double pendingAmount;
  final bool hasPendingBalance;
  final VoidCallback? onRegisterPayment;

  const PaymentListCard({
    super.key, 
    required this.payments,
    this.title = 'Pagos',
    required this.totalAmount,
    required this.totalPaid,
    required this.pendingAmount,
    required this.hasPendingBalance,
    this.onRegisterPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
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
                _buildSectionTitle(title),
                Text(
                  '${payments.length} pagos',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (payments.isEmpty)
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
              for (var payment in payments) ...[
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
                        ],
                      ),
                    ],
                  ),
                ),
                if (payment != payments.last)
                  const SizedBox(height: 12),
              ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: totalPaid >= totalAmount
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pagado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${totalPaid.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: totalPaid >= totalAmount ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (hasPendingBalance)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saldo Pendiente',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${pendingAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (hasPendingBalance && onRegisterPayment != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRegisterPayment,
                  icon: const Icon(Icons.payment),
                  label: const Text('Registrar Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
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