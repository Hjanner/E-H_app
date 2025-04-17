import 'package:flutter/material.dart';
import 'package:ehstore_app/screens/more/customers/customer_list_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirigir automáticamente a la pantalla de listado de clientes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerListScreen(),
        ),
      );
    });

    // Este widget nunca se muestra realmente, solo sirve como puente
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 