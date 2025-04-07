import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale_item.dart';
import 'package:ehstore_app/models/customer.dart';

enum SaleStatus {
  pending,
  completed,
  cancelled
}

enum PaymentMethod {
  cash,
  bankTransfer,
  creditCard,
  debitCard,
  mobilePay,
  other
}

class Sale {
  final String id;
  final String customerId;
  final String? customerName;
  final DateTime date;
  final List<SaleItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.reference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Métodos para calcular totales
  double calculateSubtotal() {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double calculateTotal() {
    return calculateSubtotal() + tax - discount;
  }

  // Método para convertir de enum a string
  static String paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
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
      case 'Efectivo':
        return PaymentMethod.cash;
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

  // Método para convertir de enum a string
  static String statusToString(SaleStatus status) {
    switch (status) {
      case SaleStatus.pending:
        return 'Pendiente';
      case SaleStatus.completed:
        return 'Completada';
      case SaleStatus.cancelled:
        return 'Cancelada';
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
    }
  }

  // Icono según el método de pago
  static IconData getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.monetization_on_outlined;
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
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: stringToPaymentMethod(json['paymentMethod'] as String),
      status: stringToStatus(json['status'] as String),
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethodToString(paymentMethod),
      'status': statusToString(status),
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Método para actualizar propiedades específicas
  Sale copyWith({
    String? customerId,
    String? customerName,
    DateTime? date,
    List<SaleItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
    String? reference,
    String? notes,
  }) {
    return Sale(
      id: this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 