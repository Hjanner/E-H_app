class Supplier {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? website;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.website,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 