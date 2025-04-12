import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/sale_item.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/database_service.dart';
import 'package:ehstore_app/services/product_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaleService {
  final DatabaseService _databaseService = DatabaseService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final Uuid _uuid = Uuid();

  // Obtener todas las ventas
  Future<List<Sale>> getAllSales() async {
    return await _databaseService.getAllSales();
  }

  // Obtener ventas por rango de fechas
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    return await _databaseService.getSalesByDateRange(start, end);
  }

  // Obtener ventas por cliente
  Future<List<Sale>> getSalesByCustomer(String customerId) async {
    return await _databaseService.getSalesByCustomer(customerId);
  }

  // Obtener una venta por ID
  Future<Sale?> getSaleById(String id) async {
    return await _databaseService.getSaleById(id);
  }

  // Obtener ventas a crédito
  Future<List<Sale>> getCreditSales() async {
    return await _databaseService.getCreditSales();
  }

  // Obtener la tasa del dólar actual
  Future<double> getCurrentDolarRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('dolar_rate') ?? 0.0;
  }

  // Crear una nueva venta
  Future<bool> createSale(Sale sale, List<SaleItem> items) async {
    try {
      // Validar que todos los productos existan y tengan stock suficiente
      for (var item in items) {
        final product = await _productService.getProductById(item.productId);
        if (product == null) {
          throw Exception('El producto ${item.productName} no existe');
        }
        if (product.currentStock < item.quantity) {
          throw Exception('Stock insuficiente para ${product.name}. Disponible: ${product.currentStock}');
        }
      }

      // Validar que exista el cliente si la venta no es para cliente no registrado
      if (sale.customerId != 'no_registered' && sale.customerId.isNotEmpty) {
        final customer = await _customerService.getCustomerById(sale.customerId);
        if (customer == null) {
          throw Exception('El cliente no existe');
        }
      }

      // Insertar la venta
      final result = await _databaseService.insertSale(sale, items);
      
      // Actualizar el stock de productos
      if (result > 0) {
        for (var item in items) {
          final product = await _productService.getProductById(item.productId);
          if (product != null) {
            await _productService.updateProductStock(
              item.productId, 
              product.currentStock - item.quantity
            );
          }
        }
      }
      
      return result > 0;
    } catch (e) {
      debugPrint('Error al crear venta: $e');
      return false;
    }
  }

  // Actualizar el estado de una venta
  Future<bool> updateSaleStatus(String id, SaleStatus status) async {
    try {
      final result = await _databaseService.updateSaleStatus(id, status);
      return result > 0;
    } catch (e) {
      debugPrint('Error al actualizar estado de venta: $e');
      return false;
    }
  }

  // Cancelar una venta
  Future<bool> cancelSale(String id) async {
    try {
      // Primero obtener la venta para verificar su estado
      final sale = await getSaleById(id);
      if (sale == null) {
        return false;
      }

      // Solo se pueden cancelar ventas pendientes, completadas o a crédito
      if (sale.status == SaleStatus.cancelled) {
        return false; // Ya está cancelada
      }

      // Actualizar su estado a cancelado
      final result = await updateSaleStatus(id, SaleStatus.cancelled);
      
      // Si la venta estaba completada o a crédito, hay que restaurar el stock
      if ((sale.status == SaleStatus.completed || sale.status == SaleStatus.credit) && result) {
        for (var item in sale.items) {
          await _productService.updateProductStock(
            item.productId, 
            (await _productService.getProductById(item.productId))!.currentStock + item.quantity
          );
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error al cancelar venta: $e');
      return false;
    }
  }

  // Eliminar una venta
  Future<bool> deleteSale(String id) async {
    try {
      final result = await _databaseService.deleteSale(id);
      return result > 0;
    } catch (e) {
      debugPrint('Error al eliminar venta: $e');
      return false;
    }
  }

  // Generar un ID único para una nueva venta
  String generateSaleId() {
    return _uuid.v4();
  }

  // Generar un ID único para un nuevo ítem de venta
  String generateSaleItemId() {
    return _uuid.v4();
  }

  // Generar un ID único para un nuevo detalle de pago
  String generatePaymentId() {
    return _uuid.v4();
  }

  // Calcular subtotal de una lista de ítems
  double calculateSubtotal(List<SaleItem> items) {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Calcular el total de una venta
  double calculateTotal(double subtotal, double discount) {
    return subtotal - discount;
  }

  // Convertir un monto en bolívares a dólares
  Future<double> convertBsToUsd(double amountInBs) async {
    final dolarRate = await getCurrentDolarRate();
    if (dolarRate <= 0) return 0.0;
    return amountInBs / dolarRate;
  }

  // Convertir un monto en dólares a bolívares
  Future<double> convertUsdToBs(double amountInUsd) async {
    final dolarRate = await getCurrentDolarRate();
    if (dolarRate <= 0) return 0.0;
    return amountInUsd * dolarRate;
  }

  // Añadir un pago a una venta existente
  Future<bool> addPaymentToSale(String saleId, PaymentDetail payment) async {
    try {
      final result = await _databaseService.addPaymentToSale(saleId, payment);
      
      // Actualizar el estado de la venta si es necesario
      if (result > 0) {
        final sale = await getSaleById(saleId);
        if (sale != null) {
          final balance = calculatePaymentBalance(sale);
          
          // Si el pago completa la deuda, cambiar el estado a completado
          if (balance['pendingAmount']! <= 0 && sale.status == SaleStatus.credit) {
            await updateSaleStatus(saleId, SaleStatus.completed);
          }
        }
      }
      
      return result > 0;
    } catch (e) {
      debugPrint('Error al añadir pago: $e');
      return false;
    }
  }

  // Obtener estadísticas de ventas
  Future<Map<String, dynamic>> getSalesMetrics(DateTime start, DateTime end) async {
    return await _databaseService.getSalesMetrics(start, end);
  }

  // Crear un nuevo ítem de venta
  SaleItem createSaleItem({
    required String saleId,
    required Product product,
    required int quantity,
    double discount = 0,
    String? notes,
  }) {
    final subtotal = product.price * quantity;
    
    return SaleItem(
      id: generateSaleItemId(),
      saleId: saleId,
      productId: product.id,
      productName: product.name,
      price: product.price,
      quantity: quantity,
      subtotal: subtotal - discount,
      discount: discount,
      notes: notes,
    );
  }

  // Crear un nuevo detalle de pago
  Future<PaymentDetail> createPaymentDetail({
    required String saleId,
    required PaymentMethod method,
    required double amount,
    required PaymentCurrency currency,
    String? reference,
    String? notes,
  }) async {
    // Obtener la tasa de cambio actual
    final dolarRate = await getCurrentDolarRate();
    
    // Calcular el monto en USD según la moneda
    double amountInUsd;
    if (currency == PaymentCurrency.usd) {
      amountInUsd = amount;
    } else {
      // Si es en bolívares, convertir a USD
      amountInUsd = await convertBsToUsd(amount);
    }
    
    return PaymentDetail(
      id: generatePaymentId(),
      method: method,
      amount: amount,
      currency: currency,
      exchangeRate: dolarRate,
      amountInUsd: amountInUsd,
      reference: reference,
      date: DateTime.now(),
      notes: notes,
    );
  }

  // Calcular el balance de pagos
  Map<String, double> calculatePaymentBalance(Sale sale) {
    double totalPaid = sale.payments.fold(0, (sum, payment) => sum + payment.amountInUsd);
    double pendingAmount = sale.totalInUsd - totalPaid;
    
    return {
      'totalPaid': totalPaid,
      'pendingAmount': pendingAmount
    };
  }

  // Crear una venta a crédito
  Future<bool> createCreditSale(Sale sale, List<SaleItem> items, List<PaymentDetail> initialPayments) async {
    try {
      // Calcular el total pagado inicialmente (en USD)
      double totalPaid = initialPayments.fold(0, (sum, payment) => sum + payment.amountInUsd);
      double pendingAmount = sale.totalInUsd - totalPaid;
      
      // Crear la venta con estado de crédito
      final saleWithCredit = Sale(
        id: sale.id,
        customerId: sale.customerId,
        customerName: sale.customerName,
        date: sale.date,
        items: sale.items,
        subtotal: sale.subtotal,
        discount: sale.discount,
        total: sale.total,
        totalInUsd: sale.totalInUsd,
        exchangeRate: sale.exchangeRate,
        payments: initialPayments,
        status: SaleStatus.credit,
        notes: sale.notes,
        createdAt: sale.createdAt,
        updatedAt: sale.updatedAt,
        paidAmount: totalPaid,
        pendingAmount: pendingAmount,
      );
      
      // Insertar la venta
      return await createSale(saleWithCredit, items);
    } catch (e) {
      debugPrint('Error al crear venta a crédito: $e');
      return false;
    }
  }

  // Método para completar una venta a crédito
  Future<bool> completeCreditSale(String saleId) async {
    try {
      // Obtener la venta
      final sale = await getSaleById(saleId);
      if (sale == null || sale.status != SaleStatus.credit) {
        return false;
      }
      
      // Si el monto pendiente es cero, marcar como completada
      if (sale.pendingAmount <= 0) {
        return await updateSaleStatus(saleId, SaleStatus.completed);
      }
      
      return false; // No se puede completar si hay monto pendiente
    } catch (e) {
      debugPrint('Error al completar venta a crédito: $e');
      return false;
    }
  }

  // Obtener deudas totales por cliente
  Future<Map<String, double>> getTotalDebtByCustomer(String customerId) async {
    try {
      final sales = await getSalesByCustomer(customerId);
      final creditSales = sales.where((sale) => 
        sale.status == SaleStatus.credit || 
        (sale.pendingAmount > 0 && sale.status != SaleStatus.cancelled)
      ).toList();
      
      double totalDebt = creditSales.fold(0, (sum, sale) => sum + sale.pendingAmount);
      
      return {
        'totalDebt': totalDebt,
        'salesCount': creditSales.length.toDouble(),
      };
    } catch (e) {
      debugPrint('Error al obtener deudas del cliente: $e');
      return {
        'totalDebt': 0.0,
        'salesCount': 0.0,
      };
    }
  }
} 