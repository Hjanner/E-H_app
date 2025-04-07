import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/sale_item.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({
    Key? key,
    required this.saleId,
  }) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  
  Sale? _sale;
  String? _customerPhone;
  bool _isLoading = true;

  final currencyFormat = NumberFormat.currency(
    locale: 'es_VE',
    symbol: 'Bs. ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sale = await _saleService.getSaleById(widget.saleId);
      
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
      
      // Cargar información adicional del cliente
      if (sale != null) {
        _loadCustomerInfo(sale.customerId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomerInfo(String customerId) async {
    try {
      final customer = await _customerService.getCustomerById(customerId);
      if (customer != null && mounted) {
        setState(() {
          _customerPhone = customer.phone;
        });
      }
    } catch (e) {
      // Manejar el error silenciosamente, no es crítico
      debugPrint('Error al cargar información del cliente: $e');
    }
  }

  Future<void> _confirmCancelSale() async {
    if (_sale == null) return;
    
    // No permitir cancelar una venta ya cancelada
    if (_sale!.status == SaleStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta venta ya está cancelada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cancelación'),
        content: const Text('¿Estás seguro de cancelar esta venta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final success = await _saleService.cancelSale(_sale!.id);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta cancelada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSale(); // Recargar venta
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cancelar la venta'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cancelar venta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmCompleteSale() async {
    if (_sale == null) return;
    
    // Solo se pueden completar ventas pendientes
    if (_sale!.status != SaleStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden completar ventas pendientes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar venta'),
        content: const Text('¿Estás seguro de marcar esta venta como completada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Sí, completar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final success = await _saleService.updateSaleStatus(_sale!.id, SaleStatus.completed);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta completada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSale(); // Recargar venta
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo completar la venta'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al completar venta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Copiar número de referencia
  Future<void> _copyReference() async {
    if (_sale == null || _sale!.reference == null || _sale!.reference!.isEmpty) return;
    
    await Clipboard.setData(ClipboardData(text: _sale!.reference!));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referencia copiada al portapapeles'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Enviar mensaje de WhatsApp con detalles de la venta
  Future<void> _sendSaleDetailsWhatsApp() async {
    if (_sale == null || _customerPhone == null) return;
    
    // Limpiar el número de teléfono
    String cleanPhone = _customerPhone!.replaceAll(RegExp(r'\s+|\(|\)|\-'), '');
    
    // Si no comienza con +, agregamos el código de país
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+58${cleanPhone.substring(1)}';
      } else {
        cleanPhone = '+58$cleanPhone';
      }
    }
    
    // Preparar mensaje con detalles de la venta
    String message = 'Hola, te comparto el detalle de tu compra: \n\n';
    message += 'Fecha: ${DateFormat('dd/MM/yyyy – HH:mm').format(_sale!.date)}\n';
    message += 'Total: ${currencyFormat.format(_sale!.total)}\n\n';
    message += 'Productos:\n';
    
    for (var item in _sale!.items) {
      message += '- ${item.quantity} x ${item.productName}: ${currencyFormat.format(item.subtotal)}\n';
    }
    
    if (_sale!.discount > 0) {
      message += '\nDescuento: ${currencyFormat.format(_sale!.discount)}\n';
    }
    
    if (_sale!.reference != null && _sale!.reference!.isNotEmpty) {
      message += '\nReferencia: ${_sale!.reference}\n';
    }
    
    message += '\n¡Gracias por tu compra!';
    
    // Codificar mensaje para URL
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$cleanPhone?text=$encodedMessage';
    
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

  // Compartir recibo por otras apps
  Future<void> _shareSaleDetails() async {
    if (_sale == null) return;
    
    // No implementado - aquí se implementaría la funcionalidad para compartir
    // usando el paquete share_plus u otros métodos
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función no implementada'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // Solo mostrar botón de cancelar si la venta no está cancelada
          if (_sale != null && _sale!.status != SaleStatus.cancelled)
            IconButton(
              onPressed: _confirmCancelSale,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar Venta',
            ),
            
          // Botón de compartir
          IconButton(
            onPressed: _sale != null ? _shareSaleDetails : null,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _sale == null
              ? const Center(
                  child: Text(
                    'Venta no encontrada',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de información principal
                      Card(
                        elevation: 0,
                        color: AppTheme.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado con fecha y estado
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Fecha
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fecha y hora',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy – HH:mm').format(_sale!.date),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Estado
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Sale.getStatusColor(_sale!.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      Sale.statusToString(_sale!.status),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Sale.getStatusColor(_sale!.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Cliente
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Cliente',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _sale!.customerName ?? 'Cliente',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Botón de WhatsApp si hay teléfono
                                  if (_customerPhone != null)
                                    IconButton(
                                      onPressed: _sendSaleDetailsWhatsApp,
                                      icon: const Icon(
                                        Icons.messenger_sharp,
                                        color: Color(0xFF25D366),
                                      ),
                                      tooltip: 'Enviar por WhatsApp',
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Método de pago
                              Row(
                                children: [
                                  Icon(
                                    Sale.getPaymentMethodIcon(_sale!.paymentMethod),
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Método de pago',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        Sale.paymentMethodToString(_sale!.paymentMethod),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Referencia (si existe)
                              if (_sale!.reference != null && _sale!.reference!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Referencia',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _sale!.reference!,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 18),
                                                onPressed: _copyReference,
                                                tooltip: 'Copiar',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de productos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_sale!.items.length} ${_sale!.items.length == 1 ? 'artículo' : 'artículos'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Lista de productos
                      Card(
                        elevation: 0,
                        color: AppTheme.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Encabezado de la lista
                              const Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      'Producto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Cant.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Precio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              
                              // Lista de productos
                              ...(_sale!.items.map((item) => _buildSaleItemRow(item))),
                              
                              const Divider(),
                              
                              // Subtotal
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text(currencyFormat.format(_sale!.subtotal)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // IVA o impuestos
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('IVA (16%)'),
                                  Text(currencyFormat.format(_sale!.tax)),
                                ],
                              ),
                              
                              // Descuento (si existe)
                              if (_sale!.discount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Descuento'),
                                    Text(
                                      '- ${currencyFormat.format(_sale!.discount)}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(_sale!.total),
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
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Notas (si existen)
                      if (_sale!.notes != null && _sale!.notes!.isNotEmpty) ...[
                        const Text(
                          'Notas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: AppTheme.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_sale!.notes!),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Información del registro
                      const Text(
                        'Información del registro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: AppTheme.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Fecha de registro
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fecha de registro',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy – HH:mm').format(_sale!.createdAt),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Última actualización
                              Row(
                                children: [
                                  const Icon(
                                    Icons.update_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Última actualización',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy – HH:mm').format(_sale!.updatedAt),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Botones de acción
                      if (_sale!.status == SaleStatus.pending)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _confirmCompleteSale,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Completar Venta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSaleItemRow(SaleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 14),
                ),
                if (item.discount > 0)
                  Text(
                    'Descuento: ${currencyFormat.format(item.discount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          
          // Cantidad
          Expanded(
            flex: 2,
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Precio
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(item.price),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  currencyFormat.format(item.subtotal),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 