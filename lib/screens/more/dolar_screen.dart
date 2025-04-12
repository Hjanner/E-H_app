import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DolarScreen extends StatefulWidget {
  const DolarScreen({Key? key}) : super(key: key);

  @override
  State<DolarScreen> createState() => _DolarScreenState();
}

class _DolarScreenState extends State<DolarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dolarController = TextEditingController();
  final _historyItems = <DolarHistoryItem>[];
  bool _isLoading = true;
  double _currentDolarRate = 0.0;
  static const String _dolarRateKey = 'dolar_rate';
  static const String _dolarHistoryKey = 'dolar_history';

  @override
  void initState() {
    super.initState();
    _loadDolarRate();
  }

  @override
  void dispose() {
    _dolarController.dispose();
    super.dispose();
  }

  Future<void> _loadDolarRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final rate = prefs.getDouble(_dolarRateKey) ?? 0.0;
      final historyJson = prefs.getStringList(_dolarHistoryKey) ?? [];
      
      final history = historyJson.map((json) => DolarHistoryItem.fromJson(json)).toList();
      
      setState(() {
        _currentDolarRate = rate;
        _dolarController.text = rate.toStringAsFixed(2);
        _historyItems.clear();
        _historyItems.addAll(history);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tasa del dólar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDolarRate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rate = double.parse(_dolarController.text);
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble(_dolarRateKey, rate);
      
      // Guardar en historial
      final historyItem = DolarHistoryItem(
        rate: rate,
        date: DateTime.now(),
        notes: 'Actualización manual',
      );
      
      _historyItems.insert(0, historyItem);
      
      // Limitar historial a los últimos 20 registros
      if (_historyItems.length > 20) {
        _historyItems.removeRange(20, _historyItems.length);
      }
      
      // Guardar historial en preferences
      final historyJson = _historyItems.map((item) => item.toJson()).toList();
      await prefs.setStringList(_dolarHistoryKey, historyJson);
      
      setState(() {
        _currentDolarRate = rate;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasa del dólar actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar tasa del dólar: $e'),
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
        title: const Text('Tasa del Dólar'),
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
              padding: const EdgeInsets.all(16),
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
                                Icons.attach_money,
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
                            '${_currentDolarRate.toStringAsFixed(2)} Bs.',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (_historyItems.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Última actualización: ${DateFormat('dd/MM/yyyy – HH:mm').format(_historyItems.first.date)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Formulario para actualizar la tasa
                  const Text(
                    'Actualizar tasa del dólar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                              controller: _dolarController,
                              decoration: const InputDecoration(
                                labelText: 'Valor en Bs.',
                                hintText: 'Ej: 40.50',
                                prefixIcon: Icon(Icons.monetization_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese un valor para la tasa del dólar';
                                }
                                
                                try {
                                  final rate = double.parse(value);
                                  if (rate <= 0) {
                                    return 'La tasa debe ser mayor a 0';
                                  }
                                } catch (e) {
                                  return 'Ingrese un valor numérico válido';
                                }
                                
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveDolarRate,
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
                  const SizedBox(height: 24),
                  
                  // Historial de tasas
                  if (_historyItems.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historial de tasas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_historyItems.length} registros',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: AppTheme.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _historyItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _historyItems[index];
                          return ListTile(
                            title: Text(
                              '${item.rate.toStringAsFixed(2)} Bs.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy – HH:mm').format(item.date)}\n${item.notes}',
                            ),
                            isThreeLine: true,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE3F2FD),
                              child: Icon(
                                Icons.history,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class DolarHistoryItem {
  final double rate;
  final DateTime date;
  final String notes;
  
  DolarHistoryItem({
    required this.rate,
    required this.date,
    required this.notes,
  });
  
  factory DolarHistoryItem.fromJson(String json) {
    final map = Map<String, dynamic>.from(
      Map<String, dynamic>.from(jsonDecode(json))
    );
    
    return DolarHistoryItem(
      rate: map['rate'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String,
    );
  }
  
  String toJson() {
    return jsonEncode({
      'rate': rate,
      'date': date.toIso8601String(),
      'notes': notes,
    });
  }
}

// Método para decodificar JSON
Map<String, dynamic> jsonDecode(String source) {
  return Map<String, dynamic>.from(
    // Usamos jsonDecode de Dart
    jsonDecodeDart(source),
  );
}

// Método para codificar JSON
String jsonEncode(Map<String, dynamic> data) {
  // Usamos jsonEncode de Dart
  return jsonEncodeDart(data);
}

// Implementaciones simplificadas solo para este ejemplo
dynamic jsonDecodeDart(String source) {
  // Esta es una implementación simplificada solo para este ejemplo
  // En una app real, usaríamos dart:convert
  final parts = source.split('|');
  if (parts.length != 3) return {};
  
  return {
    'rate': double.parse(parts[0]),
    'date': parts[1],
    'notes': parts[2],
  };
}

String jsonEncodeDart(Map<String, dynamic> data) {
  // Esta es una implementación simplificada solo para este ejemplo
  // En una app real, usaríamos dart:convert
  return '${data['rate']}|${data['date']}|${data['notes']}';
} 