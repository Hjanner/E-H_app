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

  Future<void> _confirmDeleteCustomer() async {
    if (_customer == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Estás seguro de que deseas eliminar el cliente "${_customer!.fullName}"?'),
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
    
    if (result == true && mounted) {
      _deleteCustomer();
    }
  }

  Future<void> _deleteCustomer() async {
    if (_customer == null) return;
    
    try {
      final success = await _customerService.deleteCustomer(_customer!.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede eliminar este cliente porque tiene ventas asociadas'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _toggleCustomerStatus() async {
    if (_customer == null) return;
    
    try {
      final success = await _customerService.toggleCustomerStatus(_customer!.id);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _customer!.isActive
                  ? 'Cliente desactivado correctamente'
                  : 'Cliente activado correctamente',
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
            content: Text('Error al cambiar estado del cliente: $e'),
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
    if (_customer == null || _customer!.email.isEmpty) return;
    
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
        title: const Text('Cliente'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: _customer != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editCustomer,
                  tooltip: 'Editar',
                  color: AppTheme.primaryColor,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _toggleCustomerStatus();
                    } else if (value == 'delete') {
                      _confirmDeleteCustomer();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(
                          _customer!.isActive
                              ? Icons.toggle_off_outlined
                              : Icons.toggle_on_outlined,
                          color: _customer!.isActive
                              ? Colors.red
                              : AppTheme.primaryColor,
                        ),
                        title: Text(
                          _customer!.isActive
                              ? 'Desactivar'
                              : 'Activar',
                          style: const TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Eliminar',
                          style: TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _customer == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cliente no encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [         

                      Row(
                        children: [
                          // Nombre completo (título)
                          Expanded(
                            child:  Text(
                              _customer!.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),                          
                          ),

                          //const SizedBox(height: 12),  
                          //                        
                          // Estado del cliente
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
                        ]

                      ),

                      const SizedBox(height: 16),
                      
                      // Botones de acción rápida
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          
                          // Botón para enviar correo si hay email
                          // if (_customer!.email.isNotEmpty)
                          //   ElevatedButton.icon(
                          //     onPressed: _sendEmail,
                          //     icon: const Icon(Icons.email_outlined),
                          //     label: const Text('Email'),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.orange,
                          //       foregroundColor: Colors.white,
                          //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          //     ),
                          //   ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de información personal
                      _buildSectionTitle('Información personal'),
                      const SizedBox(height: 16),
                      
                      // Documento de identidad
                      _buildInfoItem(
                        icon: Icons.badge_outlined,
                        title: 'Documento de identidad',
                        value: '${_customer!.documentType}: ${_customer!.documentId}',
                      ),
                      
                      // Dirección
                      _buildInfoItem(
                        icon: Icons.location_on_outlined,
                        title: 'Dirección',
                        value: _customer!.address,
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de información de contacto
                      _buildSectionTitle('Información de contacto'),
                      const SizedBox(height: 16),
                      
                      // Teléfono
                      _buildInfoItem(
                        icon: Icons.phone_outlined,
                        title: 'Teléfono',
                        value: _customer!.phone,
                        isPhone: true,
                      ),
                      
                      // Email (si existe)
                      if (_customer!.email.isNotEmpty)
                        _buildInfoItem(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          value: _customer!.email,
                          isEmail: true,
                        ),
                      
                      // Notas (si existen)
                      if (_customer!.notes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('Notas'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Text(_customer!.notes),
                        ),
                      ],
                      
                      // Sección de información del registro
                      const SizedBox(height: 24),
                      _buildSectionTitle('Información del registro'),
                      const SizedBox(height: 16),
                      
                      // Fecha de registro
                      _buildInfoItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Fecha de registro',
                        value: _formatDate(_customer!.createdAt),
                      ),
                      
                      // Última actualización
                      _buildInfoItem(
                        icon: Icons.update_outlined,
                        title: 'Última actualización',
                        value: _formatDate(_customer!.updatedAt),
                      ),
                      
                      const SizedBox(height: 24),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    bool isPhone = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Añadir botón de copiar solo para teléfono y email
          if (isPhone || isEmail)
            IconButton(
              icon: const Icon(Icons.content_copy, size: 20, color: Colors.grey),
              onPressed: () => _copyToClipboard(
                value,
                isPhone 
                  ? 'Número copiado al portapapeles' 
                  : 'Email copiado al portapapeles',
              ),
              tooltip: 'Copiar al portapapeles',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}