import 'package:flutter/material.dart';

class Supplier {
  final String id;
  final String businessName;     // Nombre comercial
  final String legalName;        // Razón social
  final String taxId;            // RIF/NIT
  final String address;
  final String phone;
  final String email;
  final String contactPerson;
  final bool isActive;
  final String notes;
  final String instagram;        // Instagram
  final String mercadoLibre;     // Mercado Libre
  final String website;          // Página web
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.businessName,
    required this.legalName,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.email,
    required this.contactPerson,
    required this.isActive,
    required this.notes,
    required this.instagram,
    required this.mercadoLibre,
    required this.website,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      legalName: json['legalName'] as String,
      taxId: json['taxId'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      contactPerson: json['contactPerson'] as String,
      isActive: json['isActive'] as bool,
      notes: json['notes'] as String,
      instagram: json['instagram'] as String,
      mercadoLibre: json['mercadoLibre'] as String,
      website: json['website'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'legalName': legalName,
      'taxId': taxId,
      'address': address,
      'phone': phone,
      'email': email,
      'contactPerson': contactPerson,
      'isActive': isActive,
      'notes': notes,
      'instagram': instagram,
      'mercadoLibre': mercadoLibre,
      'website': website,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Método para actualizar propiedades específicas
  Supplier copyWith({
    String? businessName,
    String? legalName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    String? contactPerson,
    bool? isActive,
    String? notes,
    String? instagram,
    String? mercadoLibre,
    String? website,
  }) {
    return Supplier(
      id: this.id,
      businessName: businessName ?? this.businessName,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      instagram: instagram ?? this.instagram,
      mercadoLibre: mercadoLibre ?? this.mercadoLibre,
      website: website ?? this.website,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 