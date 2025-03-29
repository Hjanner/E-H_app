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
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ehstore.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla de productos
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        current_stock INTEGER NOT NULL,
        minimum_stock INTEGER DEFAULT 0,
        imageUrl TEXT,
        category_id INTEGER,
        supplier_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT NOT NULL
      )
    ''');

    // Tabla para imágenes de productos
    await db.execute('''
      CREATE TABLE product_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Tabla para especificaciones de productos
    await db.execute('''
      CREATE TABLE product_specifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        specification_key TEXT NOT NULL,
        specification_value TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

  //aca 
    var tableInfo = await db.rawQuery("PRAGMA table_info(products)");
    print("Estructura de tabla products: $tableInfo");
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Crear tabla de categorías si no existe
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT NOT NULL
        )
      ''');

      // Agregar campo category_id a la tabla de productos si no existe
      var info = await db.rawQuery('PRAGMA table_info(products)');
      bool categoryExists = info.any((column) => column['name'] == 'category_id');
      
      if (!categoryExists) {
        await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER');
      }

      // Verificar y añadir minimum_stock si no existe
      bool minimumStockExists = info.any((column) => column['name'] == 'minimum_stock');
      if (!minimumStockExists) {
        await db.execute('ALTER TABLE products ADD COLUMN minimum_stock INTEGER DEFAULT 0');
      }

      // Verificar y añadir supplier_id si no existe
      bool supplierIdExists = info.any((column) => column['name'] == 'supplier_id');
      if (!supplierIdExists) {
        await db.execute('ALTER TABLE products ADD COLUMN supplier_id TEXT');
      }

      // Verificar y añadir created_at si no existe
      bool createdAtExists = info.any((column) => column['name'] == 'created_at');
      if (!createdAtExists) {
        await db.execute('ALTER TABLE products ADD COLUMN created_at TEXT DEFAULT \'' + DateTime.now().toIso8601String() + '\'');
      }

      // Verificar y añadir updated_at si no existe
      bool updatedAtExists = info.any((column) => column['name'] == 'updated_at');
      if (!updatedAtExists) {
        await db.execute('ALTER TABLE products ADD COLUMN updated_at TEXT DEFAULT \'' + DateTime.now().toIso8601String() + '\'');
      }

      // Crear tablas para imágenes y especificaciones si no existen
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          image_url TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_specifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          specification_key TEXT NOT NULL,
          specification_value TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
    }
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
        id: productMap['id'].toString(),
        name: productMap['name'] as String,
        description: productMap['description'] as String,
        price: (productMap['price'] as num).toDouble(),
        current_stock: productMap['current_stock'] as int,
        minimumStock: productMap['minimum_stock'] != null ? productMap['minimum_stock'] as int : 0,
        categoryId: productMap['category_id']?.toString(),
        supplierId: productMap['supplier_id'] as String? ?? '',
        imageUrls: imageUrls,
        specifications: specifications,
        createdAt: DateTime.parse(productMap['created_at'] as String),
        updatedAt: DateTime.parse(productMap['updated_at'] as String),
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
      id: productMaps.first['id'].toString(),
      name: productMaps.first['name'] as String,
      description: productMaps.first['description'] as String,
      price: (productMaps.first['price'] as num).toDouble(),
      current_stock: productMaps.first['current_stock'] as int,
      minimumStock: productMaps.first['minimum_stock'] != null ? productMaps.first['minimum_stock'] as int : 0,
      categoryId: productMaps.first['category_id']?.toString(),
      supplierId: productMaps.first['supplier_id'] as String? ?? '',
      imageUrls: imageUrls,
      specifications: specifications,
      createdAt: DateTime.parse(productMaps.first['created_at'] as String),
      updatedAt: DateTime.parse(productMaps.first['updated_at'] as String),
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
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'current_stock': product.current_stock,
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
            'product_id': productId,
            'image_url': imageUrl,
          },
        );
      }

      // Insertar especificaciones
      for (var entry in product.specifications.entries) {
        await txn.insert(
          'product_specifications',
          {
            'product_id': productId,
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
          'current_stock': product.current_stock,
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
        current_stock: productMap['current_stock'],
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
        id: productMap['id'].toString(),
        name: productMap['name'] as String,
        description: productMap['description'] as String,
        price: (productMap['price'] as num).toDouble(),
        current_stock: productMap['current_stock'] as int,
        minimumStock: productMap['minimum_stock'] != null ? productMap['minimum_stock'] as int : 0,
        categoryId: productMap['category_id']?.toString(),
        supplierId: productMap['supplier_id'] as String? ?? '',
        imageUrls: imageUrls,
        specifications: specifications,
        createdAt: DateTime.parse(productMap['created_at'] as String),
        updatedAt: DateTime.parse(productMap['updated_at'] as String),
      ));
    }

    return products;
  }
} 