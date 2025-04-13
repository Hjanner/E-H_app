import 'package:flutter/material.dart';

enum SaleStatus {
  completed, // Venta completada normalmente
  credit, // Venta a crédito (con deuda pendiente)
  canceled, // Venta cancelada
  refunded, // Venta con devolución
}

class Sale {
  final String id;
  final String customerId;
  final List<SaleItem> items;
  final List<Payment> payments;
  final double total;
  final double totalPaid;
  final SaleStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.customerId,
    required this.items,
    required this.payments,
    required this.total,
    required this.totalPaid,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calcular el balance pendiente
  double get pendingBalance => total - totalPaid;
  
  // Verificar si hay un balance pendiente
  bool get hasPendingBalance => pendingBalance > 0;

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      items: (json['items'] as List)
          .map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List)
          .map((payment) => Payment.fromJson(payment as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      status: SaleStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'total': total,
      'totalPaid': totalPaid,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final double price;
  final double priceInBs;
  final int quantity;
  final double subtotal;
  final double subtotalInBs;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.priceInBs,
    required this.quantity,
    required this.subtotal,
    required this.subtotalInBs,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      priceInBs: (json['priceInBs'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      subtotalInBs: (json['subtotalInBs'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'priceInBs': priceInBs,
      'quantity': quantity,
      'subtotal': subtotal,
      'subtotalInBs': subtotalInBs,
    };
  }
}

enum PaymentMethod {
  cashUSD, // Efectivo en dólares
  cashBs, // Efectivo en bolívares
  bankTransfer, // Transferencia bancaria
  mobilePayment, // Pago móvil
  creditCard, // Tarjeta de crédito
  debitCard, // Tarjeta de débito
  debt, // Deuda (crédito)
}

class Payment {
  final String id;
  final PaymentMethod method;
  final double amount;
  final String? referenceNumber;
  final DateTime date;

  Payment({
    required this.id,
    required this.method,
    required this.amount,
    this.referenceNumber,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      method: PaymentMethod.values.byName(json['method'] as String),
      amount: (json['amount'] as num).toDouble(),
      referenceNumber: json['referenceNumber'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.name,
      'amount': amount,
      'referenceNumber': referenceNumber,
      'date': date.toIso8601String(),
    };
  }
}

class Debt {
  final String id;
  final String saleId;
  final String customerId;
  final double totalAmount;
  final double paidAmount;
  final List<Payment> payments;
  final bool isPaid;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Debt({
    required this.id,
    required this.saleId,
    required this.customerId,
    required this.totalAmount,
    required this.paidAmount,
    required this.payments,
    required this.isPaid,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calcular el saldo pendiente
  double get pendingAmount => totalAmount - paidAmount;

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      customerId: json['customerId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      payments: (json['payments'] as List)
          .map((payment) => Payment.fromJson(payment as Map<String, dynamic>))
          .toList(),
      isPaid: json['isPaid'] as bool,
      dueDate: DateTime.parse(json['dueDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'isPaid': isPaid,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 