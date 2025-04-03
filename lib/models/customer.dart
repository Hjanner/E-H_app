import 'package:flutter/material.dart';

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String notes;
  final String documentId;
  final String documentType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.notes,
    required this.documentId,
    required this.documentType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Nombre completo del cliente
  String get fullName => '$firstName $lastName';

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      notes: json['notes'] as String,
      documentId: json['documentId'] as String,
      documentType: json['documentType'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'documentId': documentId,
      'documentType': documentType,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Método para actualizar propiedades específicas
  Customer copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? notes,
    String? documentId,
    String? documentType,
    bool? isActive,
  }) {
    return Customer(
      id: this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      documentId: documentId ?? this.documentId,
      documentType: documentType ?? this.documentType,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 