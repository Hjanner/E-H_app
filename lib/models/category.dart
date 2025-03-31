import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  // Método para convertir iconData a String (código entero)
  static String iconToString(IconData icon) {
    return icon.codePoint.toString();
  }

  // Método para convertir String (código entero) a IconData
  static IconData stringToIcon(String iconCode) {
    return IconData(
      int.parse(iconCode),
      fontFamily: 'MaterialIcons',
    );
  }

  // Método para convertir Color a String (valor entero)
  static String colorToString(Color color) {
    return color.value.toString();
  }

  // Método para convertir String (valor entero) a Color
  static Color stringToColor(String colorValue) {
    return Color(int.parse(colorValue));
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: stringToIcon(json['icon']),
      color: stringToColor(json['color']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': iconToString(icon),
      'color': colorToString(color),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Crear un método para actualizar propiedades específicas
  Category copyWith({
    String? name,
    String? description,
    IconData? icon,
    Color? color,
  }) {
    return Category(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 