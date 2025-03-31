import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/category.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ehstore.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insertar categorías por defecto
    await _insertDefaultCategories(db);
    
    // Tabla de productos
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        current_stock INTEGER NOT NULL,
        minimum_stock INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Tabla para las URL de imágenes de productos
    await db.execute('''
      CREATE TABLE product_images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        image_url TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // Tabla para las especificaciones de productos
    await db.execute('''
      CREATE TABLE product_specifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        specification_key TEXT NOT NULL,
        specification_value TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Si la versión anterior es menor que 2, crear la tabla de categorías
      await db.execute('''
        CREATE TABLE categories(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Insertar categorías por defecto
      await _insertDefaultCategories(db);

      // Actualizar la tabla de productos para añadir la referencia a categorías
      // Primero, obtener los productos existentes
      final List<Map<String, dynamic>> existingProducts = await db.query('products');

      // Crear una tabla temporal para los productos
      await db.execute('''
        CREATE TABLE temp_products(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          price REAL NOT NULL,
          current_stock INTEGER NOT NULL,
          minimum_stock INTEGER NOT NULL,
          category_id TEXT NOT NULL,
          supplier_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      // Insertar los productos existentes en la tabla temporal,
      // asignándoles la categoría por defecto (electrónica)
      for (var product in existingProducts) {
        await db.insert(
          'temp_products',
          {
            'id': product['id'],
            'name': product['name'],
            'description': product['description'],
            'price': product['price'],
            'current_stock': product['current_stock'],
            'minimum_stock': product['minimum_stock'],
            'category_id': product['category_id'], // Mantener la categoría existente
            'supplier_id': product['supplier_id'],
            'created_at': product['created_at'],
            'updated_at': product['updated_at'],
          },
        );
      }

      // Eliminar la tabla original de productos
      await db.execute('DROP TABLE products');

      // Renombrar la tabla temporal como la tabla principal
      await db.execute('ALTER TABLE temp_products RENAME TO products');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final uuid = Uuid();

    // Categoría Electrónica
    await db.insert('categories', {
      'id': 'electrónica',
      'name': 'Electrónica',
      'description': 'Productos electrónicos como smartphones, laptops y accesorios',
      'icon': Category.iconToString(Icons.devices),
      'color': Category.colorToString(const Color(0xFF2196F3)), // Azul
      'created_at': now,
      'updated_at': now,
    });

    // Categoría Hogar
    await db.insert('categories', {
      'id': 'hogar',
      'name': 'Hogar',
      'description': 'Artículos para el hogar como muebles, decoración y electrodomésticos',
      'icon': Category.iconToString(Icons.home),
      'color': Category.colorToString(const Color(0xFF4CAF50)), // Verde
      'created_at': now,
      'updated_at': now,
    });

    // Categoría Ropa
    await db.insert('categories', {
      'id': 'ropa',
      'name': 'Ropa',
      'description': 'Prendas de vestir para hombres, mujeres y niños',
      'icon': Category.iconToString(Icons.checkroom),
      'color': Category.colorToString(const Color(0xFFF44336)), // Rojo
      'created_at': now,
      'updated_at': now,
    });
  }

  // MÉTODOS PARA CATEGORÍAS

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> categoryMaps = await db.query('categories');
    
    if (categoryMaps.isEmpty) {
      return [];
    }

    return categoryMaps.map((categoryMap) => Category(
      id: categoryMap['id'],
      name: categoryMap['name'],
      description: categoryMap['description'],
      icon: Category.stringToIcon(categoryMap['icon']),
      color: Category.stringToColor(categoryMap['color']),
      createdAt: DateTime.parse(categoryMap['created_at']),
      updatedAt: DateTime.parse(categoryMap['updated_at']),
    )).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> categoryMaps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (categoryMaps.isEmpty) {
      return null;
    }

    return Category(
      id: categoryMaps.first['id'],
      name: categoryMaps.first['name'],
      description: categoryMaps.first['description'],
      icon: Category.stringToIcon(categoryMaps.first['icon']),
      color: Category.stringToColor(categoryMaps.first['color']),
      createdAt: DateTime.parse(categoryMaps.first['created_at']),
      updatedAt: DateTime.parse(categoryMaps.first['updated_at']),
    );
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'description': category.description,
        'icon': Category.iconToString(category.icon),
        'color': Category.colorToString(category.color),
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      {
        'name': category.name,
        'description': category.description,
        'icon': Category.iconToString(category.icon),
        'color': Category.colorToString(category.color),
        'updated_at': category.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    
    // Verificar si hay productos asociados a esta categoría
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    
    if (productMaps.isNotEmpty) {
      // Si hay productos asociados, no permitir la eliminación
      return 0;
    }
    
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para obtener los productos de una categoría específica
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    
    if (productMaps.isEmpty) {
      return [];
    }

    List<Product> products = [];
    for (var productMap in productMaps) {
      // Obtener las URLs de imágenes para este producto
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      List<String> imageUrls = imageMaps.map((img) => img['image_url'] as String).toList();

      // Obtener las especificaciones para este producto
      final List<Map<String, dynamic>> specMaps = await db.query(
        'product_specifications',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      Map<String, dynamic> specifications = {};
      for (var spec in specMaps) {
        specifications[spec['specification_key']] = spec['specification_value'];
      }

      // Crear el objeto Product
      products.add(Product(
        id: productMap['id'],
        name: productMap['name'],
        description: productMap['description'],
        price: productMap['price'],
        currentStock: productMap['current_stock'],
        minimumStock: productMap['minimum_stock'],
        categoryId: productMap['category_id'],
        supplierId: productMap['supplier_id'],
        imageUrls: imageUrls,
        specifications: specifications,
        createdAt: DateTime.parse(productMap['created_at']),
        updatedAt: DateTime.parse(productMap['updated_at']),
      ));
    }

    return products;
  }

  // MÉTODOS PARA PRODUCTOS

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> productMaps = await db.query('products');
    
    if (productMaps.isEmpty) {
      return [];
    }

    List<Product> products = [];
    for (var productMap in productMaps) {
      // Obtener las URLs de imágenes para este producto
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      List<String> imageUrls = imageMaps.map((img) => img['image_url'] as String).toList();

      // Obtener las especificaciones para este producto
      final List<Map<String, dynamic>> specMaps = await db.query(
        'product_specifications',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      Map<String, dynamic> specifications = {};
      for (var spec in specMaps) {
        specifications[spec['specification_key']] = spec['specification_value'];
      }

      // Crear el objeto Product
      products.add(Product(
        id: productMap['id'],
        name: productMap['name'],
        description: productMap['description'],
        price: productMap['price'],
        currentStock: productMap['current_stock'],
        minimumStock: productMap['minimum_stock'],
        categoryId: productMap['category_id'],
        supplierId: productMap['supplier_id'],
        imageUrls: imageUrls,
        specifications: specifications,
        createdAt: DateTime.parse(productMap['created_at']),
        updatedAt: DateTime.parse(productMap['updated_at']),
      ));
    }

    return products;
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (productMaps.isEmpty) {
      return null;
    }

    // Obtener las URLs de imágenes para este producto
    final List<Map<String, dynamic>> imageMaps = await db.query(
      'product_images',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    List<String> imageUrls = imageMaps.map((img) => img['image_url'] as String).toList();

    // Obtener las especificaciones para este producto
    final List<Map<String, dynamic>> specMaps = await db.query(
      'product_specifications',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    Map<String, dynamic> specifications = {};
    for (var spec in specMaps) {
      specifications[spec['specification_key']] = spec['specification_value'];
    }

    return Product(
      id: productMaps.first['id'],
      name: productMaps.first['name'],
      description: productMaps.first['description'],
      price: productMaps.first['price'],
      currentStock: productMaps.first['current_stock'],
      minimumStock: productMaps.first['minimum_stock'],
      categoryId: productMaps.first['category_id'],
      supplierId: productMaps.first['supplier_id'],
      imageUrls: imageUrls,
      specifications: specifications,
      createdAt: DateTime.parse(productMaps.first['created_at']),
      updatedAt: DateTime.parse(productMaps.first['updated_at']),
    );
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    
    // Iniciar una transacción
    return await db.transaction((txn) async {
      // Insertar el producto principal
      final productId = await txn.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'current_stock': product.currentStock,
          'minimum_stock': product.minimumStock,
          'category_id': product.categoryId,
          'supplier_id': product.supplierId,
          'created_at': product.createdAt.toIso8601String(),
          'updated_at': product.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insertar URLs de imágenes
      for (String imageUrl in product.imageUrls) {
        await txn.insert(
          'product_images',
          {
            'product_id': product.id,
            'image_url': imageUrl,
          },
        );
      }

      // Insertar especificaciones
      for (var entry in product.specifications.entries) {
        await txn.insert(
          'product_specifications',
          {
            'product_id': product.id,
            'specification_key': entry.key,
            'specification_value': entry.value.toString(),
          },
        );
      }

      return productId;
    });
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    
    // Iniciar una transacción
    return await db.transaction((txn) async {
      // Actualizar el producto principal
      await txn.update(
        'products',
        {
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'current_stock': product.currentStock,
          'minimum_stock': product.minimumStock,
          'category_id': product.categoryId,
          'supplier_id': product.supplierId,
          'updated_at': product.updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );

      // Eliminar las URLs de imágenes actuales
      await txn.delete(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [product.id],
      );

      // Insertar las nuevas URLs de imágenes
      for (String imageUrl in product.imageUrls) {
        await txn.insert(
          'product_images',
          {
            'product_id': product.id,
            'image_url': imageUrl,
          },
        );
      }

      // Eliminar las especificaciones actuales
      await txn.delete(
        'product_specifications',
        where: 'product_id = ?',
        whereArgs: [product.id],
      );

      // Insertar las nuevas especificaciones
      for (var entry in product.specifications.entries) {
        await txn.insert(
          'product_specifications',
          {
            'product_id': product.id,
            'specification_key': entry.key,
            'specification_value': entry.value.toString(),
          },
        );
      }

      return 1; // Éxito
    });
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      // Eliminar las imágenes del producto
      await txn.delete(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      // Eliminar las especificaciones del producto
      await txn.delete(
        'product_specifications',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      // Eliminar el producto
      return await txn.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<int> updateProductStock(String id, int newStock) async {
    final db = await database;
    
    return await db.update(
      'products',
      {
        'current_stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para buscar productos por texto
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    
    if (productMaps.isEmpty) {
      return [];
    }

    List<Product> products = [];
    for (var productMap in productMaps) {
      // Obtener las URLs de imágenes para este producto
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      List<String> imageUrls = imageMaps.map((img) => img['image_url'] as String).toList();

      // Obtener las especificaciones para este producto
      final List<Map<String, dynamic>> specMaps = await db.query(
        'product_specifications',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      Map<String, dynamic> specifications = {};
      for (var spec in specMaps) {
        specifications[spec['specification_key']] = spec['specification_value'];
      }

      // Crear el objeto Product
      products.add(Product(
        id: productMap['id'],
        name: productMap['name'],
        description: productMap['description'],
        price: productMap['price'],
        currentStock: productMap['current_stock'],
        minimumStock: productMap['minimum_stock'],
        categoryId: productMap['category_id'],
        supplierId: productMap['supplier_id'],
        imageUrls: imageUrls,
        specifications: specifications,
        createdAt: DateTime.parse(productMap['created_at']),
        updatedAt: DateTime.parse(productMap['updated_at']),
      ));
    }

    return products;
  }

  // Obtener productos con stock bajo
  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    
    final List<Map<String, dynamic>> productMaps = await db.rawQuery('''
      SELECT * FROM products 
      WHERE current_stock <= minimum_stock
    ''');
    
    if (productMaps.isEmpty) {
      return [];
    }

    List<Product> products = [];
    for (var productMap in productMaps) {
      // Obtener las URLs de imágenes para este producto
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      List<String> imageUrls = imageMaps.map((img) => img['image_url'] as String).toList();

      // Obtener las especificaciones para este producto
      final List<Map<String, dynamic>> specMaps = await db.query(
        'product_specifications',
        where: 'product_id = ?',
        whereArgs: [productMap['id']],
      );
      Map<String, dynamic> specifications = {};
      for (var spec in specMaps) {
        specifications[spec['specification_key']] = spec['specification_value'];
      }

      // Crear el objeto Product
      products.add(Product(
        id: productMap['id'],
        name: productMap['name'],
        description: productMap['description'],
        price: productMap['price'],
        currentStock: productMap['current_stock'],
        minimumStock: productMap['minimum_stock'],
        categoryId: productMap['category_id'],
        supplierId: productMap['supplier_id'],
        imageUrls: imageUrls,
        specifications: specifications,
        createdAt: DateTime.parse(productMap['created_at']),
        updatedAt: DateTime.parse(productMap['updated_at']),
      ));
    }

    return products;
  }
} 