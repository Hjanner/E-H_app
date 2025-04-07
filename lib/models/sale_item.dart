import 'package:flutter/material.dart';

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final double discount;
  final String? notes;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.discount,
    this.notes,
  });

  // Método para calcular el subtotal (precio * cantidad - descuento)
  double calculateSubtotal() {
    return (price * quantity) - discount;
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      saleId: json['saleId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'discount': discount,
      'notes': notes,
    };
  }

  // Método para actualizar propiedades específicas
  SaleItem copyWith({
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    double? subtotal,
    double? discount,
    String? notes,
  }) {
    return SaleItem(
      id: this.id,
      saleId: this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
    );
  }
} 