import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale_item.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SaleStatus {
  pending,
  completed,
  cancelled,
  credit
}

enum PaymentMethod {
  cash,
  bankTransfer,
  creditCard,
  debitCard,
  mobilePay,
  other,
  foreignCash
}

enum PaymentCurrency {
  bsf,
  usd
}

class PaymentDetail {
  final String id;
  final PaymentMethod method;
  final double amount;
  final PaymentCurrency currency;
  final double exchangeRate; // Tasa de cambio al momento del pago
  final double amountInUsd; // Monto convertido a USD para referencia
  final String? reference;
  final DateTime date;
  final String? notes;

  PaymentDetail({
    required this.id,
    required this.method,
    required this.amount,
    required this.currency,
    required this.exchangeRate,
    required this.amountInUsd,
    this.reference,
    required this.date,
    this.notes,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      id: json['id'] as String,
      method: Sale.stringToPaymentMethod(json['method'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: Sale.stringToPaymentCurrency(json['currency'] as String? ?? 'bsf'),
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      amountInUsd: (json['amountInUsd'] as num?)?.toDouble() ?? (json['amount'] as num).toDouble(),
      reference: json['reference'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': Sale.paymentMethodToString(method),
      'amount': amount,
      'currency': Sale.paymentCurrencyToString(currency),
      'exchangeRate': exchangeRate,
      'amountInUsd': amountInUsd,
      'reference': reference,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}

class Sale {
  final String id;
  final String customerId;
  final String? customerName;
  final DateTime date;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final double totalInUsd; // Total en dólares (referencia)
  final double exchangeRate; // Tasa de cambio al momento de la venta
  final List<PaymentDetail> payments;
  final SaleStatus status;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double paidAmount;
  final double pendingAmount;

  // Propiedades calculadas
  PaymentMethod get paymentMethod {
    if (payments.isEmpty) return PaymentMethod.cash;
    return payments.first.method; // Retorna el método del primer pago
  }

  double get tax => 0.0; // IVA eliminado según requerimientos

  bool get isLowStock => items.any((item) {
    final product = Product(
      id: item.productId,
      name: item.productName,
      description: '',
      price: item.price,
      currentStock: 0,
      minimumStock: 0,
      categoryId: '',
      supplierId: '',
      imageUrls: [],
      specifications: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return product.isLowStock;
  });

  Sale({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.totalInUsd,
    required this.exchangeRate,
    required this.payments,
    required this.status,
    this.reference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.paidAmount,
    required this.pendingAmount,
  });

  // Métodos para calcular totales
  double calculateSubtotal() {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double calculateTotal() {
    return calculateSubtotal() - discount;
  }

  // Métodos para convertir monedas
  static Future<double> convertUsdToBs(double amountInUsd) async {
    final dolarRate = await Product.getDolarRate();
    if (dolarRate <= 0) return 0.0;
    return amountInUsd * dolarRate;
  }

  static Future<double> convertBsToUsd(double amountInBs) async {
    final dolarRate = await Product.getDolarRate();
    if (dolarRate <= 0) return 0.0;
    return amountInBs / dolarRate;
  }

  // Método para convertir de enum a string
  static String paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo Bs';
      case PaymentMethod.foreignCash:
        return 'Efectivo USD';
      case PaymentMethod.bankTransfer:
        return 'Transferencia Bancaria';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.mobilePay:
        return 'Pago Móvil';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  // Método para convertir de string a enum
  static PaymentMethod stringToPaymentMethod(String method) {
    switch (method) {
      case 'Efectivo Bs':
        return PaymentMethod.cash;
      case 'Efectivo USD':
        return PaymentMethod.foreignCash;
      case 'Transferencia Bancaria':
        return PaymentMethod.bankTransfer;
      case 'Tarjeta de Crédito':
        return PaymentMethod.creditCard;
      case 'Tarjeta de Débito':
        return PaymentMethod.debitCard;
      case 'Pago Móvil':
        return PaymentMethod.mobilePay;
      default:
        return PaymentMethod.other;
    }
  }

  // Método para convertir moneda de enum a string
  static String paymentCurrencyToString(PaymentCurrency currency) {
    switch (currency) {
      case PaymentCurrency.bsf:
        return 'bsf';
      case PaymentCurrency.usd:
        return 'usd';
    }
  }

  // Método para convertir de string a enum de moneda
  static PaymentCurrency stringToPaymentCurrency(String currency) {
    switch (currency.toLowerCase()) {
      case 'usd':
        return PaymentCurrency.usd;
      default:
        return PaymentCurrency.bsf;
    }
  }

  // Método para convertir de enum a string
  static String statusToString(SaleStatus status) {
    switch (status) {
      case SaleStatus.pending:
        return 'Pendiente';
      case SaleStatus.completed:
        return 'Completada';
      case SaleStatus.cancelled:
        return 'Cancelada';
      case SaleStatus.credit:
        return 'Crédito';
    }
  }

  // Método para convertir de string a enum
  static SaleStatus stringToStatus(String status) {
    switch (status) {
      case 'Pendiente':
        return SaleStatus.pending;
      case 'Completada':
        return SaleStatus.completed;
      case 'Cancelada':
        return SaleStatus.cancelled;
      case 'Crédito':
        return SaleStatus.credit;
      default:
        return SaleStatus.pending;
    }
  }

  // Color según el estado
  static Color getStatusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.pending:
        return const Color(0xFFFFB74D); // Naranja
      case SaleStatus.completed:
        return const Color(0xFF4CAF50); // Verde
      case SaleStatus.cancelled:
        return const Color(0xFFE57373); // Rojo
      case SaleStatus.credit:
        return const Color(0xFF9C27B0); // Violeta
    }
  }

  // Icono según el método de pago
  static IconData getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.monetization_on_outlined;
      case PaymentMethod.foreignCash:
        return Icons.attach_money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.creditCard:
        return Icons.credit_card_outlined;
      case PaymentMethod.debitCard:
        return Icons.payment_outlined;
      case PaymentMethod.mobilePay:
        return Icons.phone_android_outlined;
      case PaymentMethod.other:
        return Icons.payments_outlined;
    }
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String?,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List).map((item) => SaleItem.fromJson(item as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      totalInUsd: (json['totalInUsd'] as num?)?.toDouble() ?? (json['total'] as num).toDouble(),
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      payments: (json['payments'] as List? ?? []).map((payment) => PaymentDetail.fromJson(payment as Map<String, dynamic>)).toList(),
      status: stringToStatus(json['status'] as String),
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'totalInUsd': totalInUsd,
      'exchangeRate': exchangeRate,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'status': statusToString(status),
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
    };
  }

  // Método para actualizar propiedades específicas
  Sale copyWith({
    String? customerId,
    String? customerName,
    DateTime? date,
    List<SaleItem>? items,
    double? subtotal,
    double? discount,
    double? total,
    double? totalInUsd,
    double? exchangeRate,
    List<PaymentDetail>? payments,
    SaleStatus? status,
    String? reference,
    String? notes,
    double? paidAmount,
    double? pendingAmount,
  }) {
    return Sale(
      id: this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      totalInUsd: totalInUsd ?? this.totalInUsd,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
    );
  }
} 