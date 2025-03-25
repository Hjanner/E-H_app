import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int currentStock;
  final int minimumStock;
  final String categoryId;
  final String supplierId;
  final List<String> imageUrls;
  final Map<String, dynamic> specifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currentStock,
    required this.minimumStock,
    required this.categoryId,
    required this.supplierId,
    required this.imageUrls,
    required this.specifications,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => currentStock <= minimumStock;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currentStock: json['currentStock'] as int,
      minimumStock: json['minimumStock'] as int,
      categoryId: json['categoryId'] as String,
      supplierId: json['supplierId'] as String,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      specifications: json['specifications'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'imageUrls': imageUrls,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 