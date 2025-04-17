import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/screens/more/customers/customer_detail_screen.dart';
import 'package:ehstore_app/screens/inventory/product_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:ehstore_app/widgets/customer_info_card.dart';
import 'package:ehstore_app/widgets/payment_list_card.dart';
import 'package:ehstore_app/widgets/product_list_card.dart';
import 'package:ehstore_app/widgets/section_title.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;
  
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  
  bool _isLoading = true;
  Sale? _sale;
  Customer? _customer;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }
  
  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Cargar detalles de la venta
      final sale = await _saleService.getSaleById(widget.saleId);
      
      if (sale == null) {
        setState(() {
          _errorMessage = 'No se encontró la venta';
          _isLoading = false;
        });
        return;
      }
      
      // Cargar información del cliente
      final customer = await _customerService.getCustomerById(sale.customerId);
      
      if (mounted) {
        setState(() {
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

  void _navigateToProductDetails(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  void _handleRegisterPayment() {
    // TODO: Implementar pantalla para registrar pago de deuda
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de registrar pago no implementada aún'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venta #${widget.saleId.substring(0, 8)}'),
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
                        onPressed: _loadSaleDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _sale == null
                  ? const Center(
                      child: Text('No se encontró la venta'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSaleHeader(),
                          const SizedBox(height: 24),
                          CustomerInfoCard(
                            customer: _customer,
                            customerId: _sale!.customerId,
                            showContactButtons: false,
                          ),
                          const SizedBox(height: 24),
                          ProductListCard(
                            items: _sale!.items,
                            total: _sale!.total,
                            onProductTap: _navigateToProductDetails,
                          ),
                          const SizedBox(height: 24),
                          PaymentListCard(
                            payments: _sale!.payments,
                            totalAmount: _sale!.total,
                            totalPaid: _sale!.totalPaid,
                            pendingAmount: _sale!.pendingBalance,
                            hasPendingBalance: _sale!.hasPendingBalance,
                            onRegisterPayment: _sale!.status == SaleStatus.credit ? _handleRegisterPayment : null,
                          ),
                          if (_sale!.status == SaleStatus.credit)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: _buildCreditInfo(),
                            ),
                          const SizedBox(height: 16),
                          if (_sale!.notes.isNotEmpty)
                            _buildNotes(),
                        ],
                      ),
                    ),
    );
  }
  
  Widget _buildSaleHeader() {
    String statusText;
    Color statusColor;
    
    switch (_sale!.status) {
      case SaleStatus.completed:
        statusText = 'Completada';
        statusColor = Colors.green;
        break;
      case SaleStatus.credit:
        statusText = 'A Crédito';
        statusColor = Colors.orange;
        break;
      case SaleStatus.canceled:
        statusText = 'Cancelada';
        statusColor = Colors.red;
        break;
      case SaleStatus.refunded:
        statusText = 'Reembolsada';
        statusColor = Colors.purple;
        break;
    }
    
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
                Text(
                  'Venta #${_sale!.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
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
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(_sale!.createdAt)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_sale!.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCreditInfo() {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Información de Crédito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saldo Pendiente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '\$${_sale!.pendingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleRegisterPayment,
                icon: const Icon(Icons.payment),
                label: const Text('Registrar Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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
  
  Widget _buildNotes() {
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
            const SectionTitle(title: 'Notas'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              width: double.infinity,
              child: Text(_sale!.notes),
            ),
          ],
        ),
      ),
    );
  }
} 