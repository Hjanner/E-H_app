import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_service.dart';

class CategoryService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Category>> getCategories() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<Category> getCategoryById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      throw Exception('Categoría con ID $id no encontrada');
    }
    
    return Category.fromMap(maps.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await _databaseService.database;
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(Category category) async {
    final db = await _databaseService.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _databaseService.database;
    
    // Primero, actualizar los productos que tengan esta categoría
    await db.update(
      'products',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    
    // Luego, eliminar la categoría
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Método para obtener los productos de una categoría específica
  Future<List<Map<String, dynamic>>> getProductsByCategory(int categoryId) async {
    final db = await _databaseService.database;
    return await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // Método para contar productos por categoría
  Future<int> countProductsInCategory(int categoryId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
} 