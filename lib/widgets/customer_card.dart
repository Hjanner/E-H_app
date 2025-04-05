import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback? onToggleStatus;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    this.onToggleStatus,
  });

  // Copiar número de teléfono al portapapeles
  Future<void> _copyPhoneNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: customer.phone));
    
    // Mostrar un mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Número de teléfono copiado al portapapeles'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Realizar llamada telefónica
  Future<void> _callCustomer(BuildContext context) async {
    final url = 'tel:${customer.phone}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Mostrar error si no se puede realizar la llamada
      if (context.mounted) {
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
  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    // Limpiar el número de teléfono (eliminar espacios, paréntesis, etc.)
    String cleanPhone = customer.phone.replaceAll(RegExp(r'\s+|\(|\)|\-'), '');
    
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
      // Mostrar error si no se puede abrir WhatsApp
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: customer.isActive ? Colors.transparent : Colors.red.shade200,
          width: customer.isActive ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sección izquierda: Avatar e información
              Expanded(
                child: Row(
                  children: [                    
                    // Información del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del cliente
                          Text(
                            customer.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Teléfono
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sección derecha: Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón para copiar teléfono
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyPhoneNumber(context),
                    tooltip: 'Copiar teléfono',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Botón para llamar
                  IconButton(
                    icon: Icon(
                      Icons.phone,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => _callCustomer(context),
                    tooltip: 'Llamar',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Botón para WhatsApp
                  IconButton(
                    icon: const Icon(
                      Icons.chat_outlined,
                      size: 20,
                      color: Color(0xFF25D366), // Color verde de WhatsApp
                    ),
                    onPressed: () => _sendWhatsAppMessage(context),
                    tooltip: 'WhatsApp',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Obtener las iniciales del nombre para el avatar
  String _getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    
    if (names.isNotEmpty) {
      initials += names[0][0];
      
      if (names.length > 1) {
        initials += names[1][0];
      }
    }
    
    return initials.toUpperCase();
  }
} 