import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Asegura que tome todo el ancho disponible
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            Color.fromARGB(255, 46, 35, 255),
            //AppTheme.,
            // Color(0xFF4B3FFF), // Color principal
            // Color(0xFF6C63FF), // Color secundario
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Quicksand',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Sección de Ingresos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresos',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ],
                ),
              ),
              // Línea vertical divisoria
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              // Sección de Egresos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        'Egresos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        '\$0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 