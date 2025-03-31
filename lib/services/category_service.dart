import 'package:flutter/material.dart';
import '../models/category.dart';
import 'database_service.dart';
import 'package:uuid/uuid.dart';

class CategoryService {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = Uuid();

  // Obtener todas las categorías
  Future<List<Category>> getAllCategories() async {
    return await _databaseService.getAllCategories();
  }

  // Obtener una categoría por su ID
  Future<Category?> getCategoryById(String id) async {
    return await _databaseService.getCategoryById(id);
  }

  // Crear una nueva categoría
  Future<bool> createCategory({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    try {
      final now = DateTime.now();
      final category = Category(
        id: _generateCategoryId(name),
        name: name,
        description: description,
        icon: icon,
        color: color,
        createdAt: now,
        updatedAt: now,
      );

      final result = await _databaseService.insertCategory(category);
      return result > 0;
    } catch (e) {
      print('Error al crear categoría: $e');
      return false;
    }
  }

  // Actualizar una categoría existente
  Future<bool> updateCategory({
    required String id,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    try {
      // Obtener la categoría actual
      final currentCategory = await _databaseService.getCategoryById(id);
      if (currentCategory == null) {
        return false;
      }

      // Crear la categoría actualizada
      final updatedCategory = Category(
        id: id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        createdAt: currentCategory.createdAt,
        updatedAt: DateTime.now(),
      );

      final result = await _databaseService.updateCategory(updatedCategory);
      return result > 0;
    } catch (e) {
      print('Error al actualizar categoría: $e');
      return false;
    }
  }

  // Eliminar una categoría
  Future<bool> deleteCategory(String id) async {
    try {
      final result = await _databaseService.deleteCategory(id);
      // Si el resultado es 0, significa que hay productos asociados y no se puede eliminar
      return result > 0;
    } catch (e) {
      print('Error al eliminar categoría: $e');
      return false;
    }
  }

  // Generar un ID para la categoría basado en su nombre
  String _generateCategoryId(String name) {
    // Convertir el nombre a minúsculas y reemplazar espacios con guiones bajos
    String baseId = name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
    
    // Eliminar caracteres especiales y acentos
    baseId = baseId.replaceAll(RegExp(r'[^\w\s]'), '');
    
    // Si el ID resultante es muy corto, añadir un identificador único
    if (baseId.length < 3) {
      baseId = '${baseId}_${_uuid.v4().substring(0, 8)}';
    }
    
    return baseId;
  }

  // Obtener un mapa de categorías (id -> nombre) para mostrar en dropdowns
  Future<Map<String, String>> getCategoryMap() async {
    final categories = await getAllCategories();
    final Map<String, String> categoryMap = {};
    
    for (var category in categories) {
      categoryMap[category.id] = category.name;
    }
    
    return categoryMap;
  }

  // Obtener productos por categoría
  Future<List<dynamic>> getProductsByCategory(String categoryId) async {
    return await _databaseService.getProductsByCategory(categoryId);
  }
} 