class Category {
  final String id;
  final String name;
  final String description;
  final String? iconName;
  final String? parentCategoryId;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    this.parentCategoryId,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String?,
      parentCategoryId: json['parentCategoryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'parentCategoryId': parentCategoryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 