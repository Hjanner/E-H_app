import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/product.dart';

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
        updated_at TEXT NOT NULL
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