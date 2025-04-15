import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  bool _isLoading = false;
  double _currentRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExchangeRate();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final rate = prefs.getDouble('exchange_rate') ?? 0.0;
      setState(() {
        _currentRate = rate;
        _rateController.text = rate.toStringAsFixed(2);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la tasa de cambio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveExchangeRate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newRate = double.parse(_rateController.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('exchange_rate', newRate);
      Product.exchangeRate = newRate;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasa de cambio actualizada exitosamente'),
            backgroundColor: Colors.green,            
          ),
        );
        //Navigator.pop(context, true);
        // Actualiza el estado para mostrar la nueva tasa
        setState(() {
          _currentRate = newRate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la tasa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasa de Cambio'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta principal con el valor actual
                  Card(
                    elevation: 0,
                    color: AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.currency_exchange,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tasa actual',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_currentRate.toStringAsFixed(2)} Bs',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formulario para actualizar la tasa
                  const Center(
                    child: Text(
                      'Actualizar tasa de cambio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,                    
                      ),
                    ),
                  ),          
                  const SizedBox(height: 12),

                  Form(
                    key: _formKey,
                    child: Card(
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
                            TextFormField(
                              controller: _rateController,
                              decoration: const InputDecoration(
                                labelText: 'Tasa de Cambio (Bs/\$)',
                                hintText: 'Ejemplo: 36.50',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese la tasa de cambio';
                                }
                                final rate = double.tryParse(value);
                                if (rate == null || rate <= 0) {
                                  return 'Ingrese un valor válido mayor a 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveExchangeRate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Actualizar Tasa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}