import 'dart:convert';

class Category {
  final int? id;
  final String name;
  final String description;
  final String icon;
  
  Category({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  // Constructor de copia con parámetros opcionales
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  // Convertir a Map para almacenar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }

  // Crear una categoría desde un Map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
    );
  }

  // Métodos para serialización/deserialización JSON
  String toJson() => json.encode(toMap());
  
  factory Category.fromJson(String source) => Category.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Category(id: $id, name: $name, description: $description, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ description.hashCode ^ icon.hashCode;
  }
} 