import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/screens/more/customers/customer_detail_screen.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerInfoCard extends StatelessWidget {
  final Customer? customer;
  final String? customerId;
  final bool showContactButtons;

  const CustomerInfoCard({
    super.key,
    required this.customer,
    this.customerId,
    this.showContactButtons = true,
  });

  Future<void> _copyToClipboard(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
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
  
  Future<void> _callCustomer(BuildContext context) async {
    if (customer == null) return;
    
    final url = 'tel:${customer!.phone}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
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

  Future<void> _sendWhatsAppMessage(BuildContext context) async {
    if (customer == null) return;
    
    // Limpiar el número de teléfono
    String cleanPhone = customer!.phone.replaceAll(RegExp(r'\s+|\(|\)|\-'), '');
    
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

  void _navigateToCustomerDetails(BuildContext context) {
    if (customer == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customerId: customer!.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: customer != null ? () => _navigateToCustomerDetails(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información del Cliente'),
              const SizedBox(height: 16),
              if (customer != null)
                Column(
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
                                customer!.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${customer!.documentType}: ${customer!.documentId}'),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: customer!.isActive 
                                ? const Color(0xFFE6F7ED)
                                : const Color(0xFFFFE9EC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            customer!.isActive ? 'ACTIVO' : 'INACTIVO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: customer!.isActive
                                  ? const Color(0xFF0D9145)
                                  : const Color(0xFFD93644),
                            ),
                          ),
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
                                customer!.phone,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            context,
                            customer!.phone, 
                            'Teléfono copiado al portapapeles'
                          ),
                          icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                          tooltip: 'Copiar teléfono',
                        ),
                      ],
                    ),
                    if (showContactButtons) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _callCustomer(context),
                            icon: const Icon(Icons.phone),
                            label: const Text('Llamar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _sendWhatsAppMessage(context),
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
                  ],
                )
              else
                Text(
                  'Cliente ID: ${customerId ?? "No disponible"}',
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
} 