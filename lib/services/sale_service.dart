import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/sale_item.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/database_service.dart';
import 'package:ehstore_app/services/product_service.dart';

class SaleService {
  final DatabaseService _databaseService = DatabaseService();
  final ProductService _productService = ProductService();
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

      // Insertar la venta
      final result = await _databaseService.insertSale(sale, items);
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

      // Solo se pueden cancelar ventas pendientes o completadas
      if (sale.status == SaleStatus.cancelled) {
        return false; // Ya está cancelada
      }

      // Actualizar su estado a cancelado
      final result = await updateSaleStatus(id, SaleStatus.cancelled);
      
      // Si la venta estaba completada, hay que restaurar el stock
      if (sale.status == SaleStatus.completed && result) {
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

  // Calcular subtotal de una lista de ítems
  double calculateSubtotal(List<SaleItem> items) {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Calcular el impuesto (por ejemplo, 16% de IVA)
  double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }

  // Calcular el total de una venta
  double calculateTotal(double subtotal, double tax, double discount) {
    return subtotal + tax - discount;
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
} 