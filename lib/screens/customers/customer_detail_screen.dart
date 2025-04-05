import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final CustomerService _customerService = CustomerService();
  
  Customer? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customer = await _customerService.getCustomerById(widget.customerId);
      setState(() {
        _customer = customer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (_customer == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar al cliente ${_customer!.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _customerService.deleteCustomer(_customer!.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo eliminar el cliente. Podría tener ventas asociadas.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar cliente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleCustomerStatus() async {
    if (_customer == null) return;
    
    try {
      final success = await _customerService.toggleCustomerStatus(_customer!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _customer!.isActive
                  ? 'Cliente desactivado'
                  : 'Cliente activado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadCustomer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editCustomer() {
    if (_customer == null) return;

    Navigator.pushNamed(
      context,
      '/customer_form',
      arguments: _customer,
    ).then((result) {
      if (result == true) {
        _loadCustomer();
      }
    });
  }

  // Copiar número de teléfono al portapapeles
  Future<void> _copyPhoneNumber() async {
    if (_customer == null) return;
    
    await Clipboard.setData(ClipboardData(text: _customer!.phone));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número de teléfono copiado al portapapeles'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Realizar llamada telefónica
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

  // Enviar mensaje de WhatsApp
  Future<void> _sendWhatsAppMessage() async {
    if (_customer == null) return;
    
    // Limpiar el número de teléfono (eliminar espacios, paréntesis, etc.)
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

  Future<void> _sendEmail() async {
    if (_customer == null) return;
    
    final url = 'mailto:${_customer!.email}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el correo electrónico'),
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
        title: const Text('Detalle del Cliente'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // Botón para editar
          IconButton(
            onPressed: _isLoading ? null : _editCustomer,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
          // Botón para eliminar
          IconButton(
            onPressed: _isLoading ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outlined),
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _customer == null
              ? const Center(
                  child: Text(
                    'Cliente no encontrado',
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
                              // Encabezado con nombre y estado
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Nombre completo
                                  Expanded(
                                    child: Text(
                                      _customer!.fullName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  
                                  // Estado (activo/inactivo)
                                  // GestureDetector(
                                  //   onTap: _toggleCustomerStatus,
                                  //   child: Container(
                                  //     padding: const EdgeInsets.symmetric(
                                  //       horizontal: 12,
                                  //       vertical: 6,
                                  //     ),
                                  //     decoration: BoxDecoration(
                                  //       color: _customer!.isActive 
                                  //           ? const Color(0xFFE6F7ED)
                                  //           : const Color(0xFFFFE9EC),
                                  //       borderRadius: BorderRadius.circular(12),
                                  //     ),
                                  //     child: Text(
                                  //       _customer!.isActive ? 'Activo' : 'Inactivo',
                                  //       style: TextStyle(
                                  //         fontSize: 14,
                                  //         fontWeight: FontWeight.w500,
                                  //         color: _customer!.isActive
                                  //             ? const Color(0xFF0D9145)
                                  //             : const Color(0xFFD93644),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Documento
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_customer!.documentType}: ${_customer!.documentId}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Teléfono con opciones de copiar
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _customer!.phone,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Botón para copiar teléfono
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18),
                                      onPressed: _copyPhoneNumber,
                                      tooltip: 'Copiar teléfono',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Botones de acción
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Botón para llamar
                                  ElevatedButton.icon(
                                    onPressed: _callCustomer,
                                    icon: const Icon(Icons.phone),
                                    label: const Text('Llamar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  
                                  // Botón para WhatsApp
                                  ElevatedButton.icon(
                                    onPressed: _sendWhatsAppMessage,
                                    icon: const Icon(Icons.chat_outlined),
                                    label: const Text('WhatsApp'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366), // Color verde de WhatsApp
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  
                                  // Botón para enviar correo
                                  // ElevatedButton.icon(
                                  //   onPressed: _sendEmail,
                                  //   icon: const Icon(Icons.email),
                                  //   label: const Text('Email'),
                                  //   style: ElevatedButton.styleFrom(
                                  //     backgroundColor: Colors.orange,
                                  //     foregroundColor: Colors.white,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de información de contacto
                      const Text(
                        'Información de contacto',
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
                              // Teléfono
                              ListTile(
                                leading: const Icon(
                                  Icons.phone_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                title: const Text('Teléfono'),
                                subtitle: Text(_customer!.phone),
                                contentPadding: EdgeInsets.zero,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón para copiar
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: _copyPhoneNumber,
                                      tooltip: 'Copiar',
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              
                              // Correo electrónico
                              ListTile(
                                leading: const Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                title: const Text('Correo electrónico'),
                                subtitle: Text(_customer!.email),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Divider(),
                              
                              // Dirección
                              ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                title: const Text('Dirección'),
                                subtitle: Text(_customer!.address),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de notas
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
                          child: Text(
                            _customer!.notes.isEmpty 
                                ? 'No hay notas disponibles' 
                                : _customer!.notes,
                            style: TextStyle(
                              fontStyle: _customer!.notes.isEmpty 
                                  ? FontStyle.italic 
                                  : FontStyle.normal,
                              color: _customer!.notes.isEmpty 
                                  ? Colors.grey 
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Aquí se podría agregar una sección de historial de compras en el futuro
                      
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
                              ListTile(
                                leading: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                title: const Text('Fecha de registro'),
                                subtitle: Text(
                                  '${_formatDate(_customer!.createdAt)}',
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Divider(),
                              
                              // Última actualización
                              ListTile(
                                leading: const Icon(
                                  Icons.update_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                title: const Text('Última actualización'),
                                subtitle: Text(
                                  '${_formatDate(_customer!.updatedAt)}',
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 