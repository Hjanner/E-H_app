import 'package:flutter/material.dart';
import 'package:ehstore_app/models/supplier.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.onTap,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: supplier.isActive ? Colors.transparent : Colors.red.shade200,
          width: supplier.isActive ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con nombre y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nombre del proveedor
                  Expanded(
                    child: Text(
                      supplier.businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Estado (activo/inactivo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: supplier.isActive 
                          ? const Color(0xFFE6F7ED)
                          : const Color(0xFFFFE9EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      supplier.isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: supplier.isActive
                            ? const Color(0xFF0D9145)
                            : const Color(0xFFD93644),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Razón social
              Row(
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      supplier.legalName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Teléfono
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                Text(
                    supplier.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),                          
              
              // Persona de contacto
              // Row(
              //   children: [
              //     const Icon(
              //       Icons.person_outline,
              //       size: 16,
              //       color: Colors.grey,
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: Text(
              //         supplier.contactPerson,
              //         style: const TextStyle(
              //           fontSize: 14,
              //           color: Colors.black87,
              //         ),
              //         maxLines: 1,
              //         overflow: TextOverflow.ellipsis,
              //       ),
              //     ),
              //   ],
              // ),
                                        
              // Botones de acción
              if (onToggleStatus != null || onDelete != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botón para cambiar estado
                    if (onToggleStatus != null)
                      TextButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          supplier.isActive
                              ? Icons.toggle_off_outlined
                              : Icons.toggle_on_outlined,
                          color: supplier.isActive
                              ? Colors.red
                              : AppTheme.primaryColor,
                          size: 20,
                        ),
                        label: Text(
                          supplier.isActive
                              ? 'Desactivar'
                              : 'Activar',
                          style: TextStyle(
                            color: supplier.isActive
                                ? Colors.red
                                : AppTheme.primaryColor,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    
                    // Botón para eliminar
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          '',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 