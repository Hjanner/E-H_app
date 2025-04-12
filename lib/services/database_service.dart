import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/customer.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

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
      version: 8, // Incrementamos la versión para la nueva migración
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
    
    // Tabla de proveedores
    await db.execute('''
      CREATE TABLE suppliers(
        id TEXT PRIMARY KEY,
        business_name TEXT NOT NULL,
        legal_name TEXT NOT NULL,
        tax_id TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        contact_person TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        notes TEXT NOT NULL,
        instagram TEXT NOT NULL,
        mercado_libre TEXT NOT NULL,
        website TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Insertar proveedores por defecto
    await _insertDefaultSuppliers(db);
    
    // Tabla de clientes
    await db.execute('''
      CREATE TABLE customers(
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        notes TEXT NOT NULL,
        document_id TEXT NOT NULL,
        document_type TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Insertar clientes por defecto
    await _insertDefaultCustomers(db);
    
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
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT
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

    // Tabla para las ventas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        customer_name TEXT,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,
        total_in_usd REAL NOT NULL,
        exchange_rate REAL NOT NULL,
        status TEXT NOT NULL,
        reference TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        pending_amount REAL NOT NULL
      )
    ''');

    // Tabla para los items de la venta
    await db.execute('''
      CREATE TABLE sale_items(
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      )
    ''');
    
    // Tabla para los detalles de pago
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_details (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'bsf',
        exchange_rate REAL NOT NULL DEFAULT 1.0,
        amount_in_usd REAL NOT NULL DEFAULT 0.0,
        reference TEXT,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
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
    
    if (oldVersion < 3) {
      // Si la versión anterior es menor que 3, crear la tabla de proveedores
      await db.execute('''
        CREATE TABLE suppliers(
          id TEXT PRIMARY KEY,
          business_name TEXT NOT NULL,
          legal_name TEXT NOT NULL,
          tax_id TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT NOT NULL,
          contact_person TEXT NOT NULL,
          is_active INTEGER NOT NULL,
          notes TEXT NOT NULL,
          instagram TEXT NOT NULL,
          mercado_libre TEXT NOT NULL,
          website TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Insertar proveedores por defecto
      await _insertDefaultSuppliers(db);
      
      // Verificar si los productos tienen una relación con proveedores
      final tableInfo = await db.rawQuery("PRAGMA table_info(products)");
      
      final hasSupplierIdColumn = tableInfo.any((column) => column['name'] == 'supplier_id');
      
      if (!hasSupplierIdColumn) {
        // Si no existe la columna supplier_id, crear una tabla temporal para añadirla
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
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
            FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT
          )
        ''');
        
        // Obtener los productos existentes
        final List<Map<String, dynamic>> existingProducts = await db.query('products');
        
        // Insertar los productos en la tabla temporal, asignando un proveedor por defecto
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
              'category_id': product['category_id'],
              'supplier_id': 'samsung', // Proveedor por defecto
              'created_at': product['created_at'],
              'updated_at': product['updated_at'],
            },
          );
        }
        
        // Eliminar la tabla original
        await db.execute('DROP TABLE products');
        
        // Renombrar la tabla temporal
        await db.execute('ALTER TABLE temp_products RENAME TO products');
      }
      
      // Actualizar la restricción de clave foránea de supplier_id si no existe
      await db.execute('PRAGMA foreign_keys = ON');
    }
    
    // Añadir migración para los nuevos campos
    if (oldVersion < 4) {
      // Verificar si existen las columnas de redes sociales y sitio web
      final tableInfo = await db.rawQuery("PRAGMA table_info(suppliers)");
      
      final hasInstagramColumn = tableInfo.any((column) => column['name'] == 'instagram');
      final hasMercadoLibreColumn = tableInfo.any((column) => column['name'] == 'mercado_libre');
      final hasWebsiteColumn = tableInfo.any((column) => column['name'] == 'website');
      
      if (!hasInstagramColumn || !hasMercadoLibreColumn || !hasWebsiteColumn) {
        // Si no existen las columnas, crear una tabla temporal con todos los campos
        await db.execute('''
          CREATE TABLE temp_suppliers(
            id TEXT PRIMARY KEY,
            business_name TEXT NOT NULL,
            legal_name TEXT NOT NULL,
            tax_id TEXT NOT NULL,
            address TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            contact_person TEXT NOT NULL,
            is_active INTEGER NOT NULL,
            notes TEXT NOT NULL,
            instagram TEXT NOT NULL,
            mercado_libre TEXT NOT NULL,
            website TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        
        // Obtener los proveedores existentes
        final List<Map<String, dynamic>> existingSuppliers = await db.query('suppliers');
        
        // Insertar los proveedores en la tabla temporal con valores por defecto para los nuevos campos
        for (var supplier in existingSuppliers) {
          await db.insert(
            'temp_suppliers',
            {
              'id': supplier['id'],
              'business_name': supplier['business_name'],
              'legal_name': supplier['legal_name'],
              'tax_id': supplier['tax_id'],
              'address': supplier['address'],
              'phone': supplier['phone'],
              'email': supplier['email'],
              'contact_person': supplier['contact_person'],
              'is_active': supplier['is_active'],
              'notes': supplier['notes'],
              'instagram': '', // Valor por defecto vacío
              'mercado_libre': '', // Valor por defecto vacío
              'website': '', // Valor por defecto vacío
              'created_at': supplier['created_at'],
              'updated_at': supplier['updated_at'],
            },
          );
        }
        
        // Eliminar la tabla original
        await db.execute('DROP TABLE suppliers');
        
        // Renombrar la tabla temporal
        await db.execute('ALTER TABLE temp_suppliers RENAME TO suppliers');
      }
    }
    
    // Migración para añadir la tabla de clientes
    if (oldVersion < 5) {
      // Tabla de clientes
      await db.execute('''
        CREATE TABLE customers(
          id TEXT PRIMARY KEY,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          email TEXT NOT NULL,
          phone TEXT NOT NULL,
          address TEXT NOT NULL,
          notes TEXT NOT NULL,
          document_id TEXT NOT NULL,
          document_type TEXT NOT NULL,
          is_active INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Insertar clientes por defecto
      await _insertDefaultCustomers(db);
    }

    // Migración para añadir las tablas de ventas
    if (oldVersion < 6) {
      // Tabla para las ventas
      await db.execute('''
        CREATE TABLE sales(
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          customer_name TEXT,
          date TEXT NOT NULL,
          subtotal REAL NOT NULL,
          tax REAL NOT NULL,
          discount REAL NOT NULL,
          total REAL NOT NULL,
          payment_method TEXT NOT NULL,
          status TEXT NOT NULL,
          reference TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
        )
      ''');

      // Tabla para los items de la venta
      await db.execute('''
        CREATE TABLE sale_items(
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          subtotal REAL NOT NULL,
          discount REAL NOT NULL,
          notes TEXT,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
        )
      ''');
    }

    // Migración para actualizar las ventas a la nueva estructura
    if (oldVersion < 7) {
      // Crear la tabla de detalles de pago
      await db.execute('''
        CREATE TABLE payment_details(
          id TEXT PRIMARY KEY,
          sale_id TEXT NOT NULL,
          method TEXT NOT NULL,
          amount REAL NOT NULL,
          currency TEXT NOT NULL,
          exchange_rate REAL NOT NULL,
          amount_in_usd REAL NOT NULL,
          reference TEXT,
          date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
        )
      ''');
      
      // Añadir nuevas columnas a la tabla de ventas
      await db.execute('ALTER TABLE sales ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE sales ADD COLUMN pending_amount REAL NOT NULL DEFAULT 0');
      
      // Obtener todas las ventas existentes
      final List<Map<String, dynamic>> existingSales = await db.query('sales');
      
      // Actualizar cada venta existente
      for (var sale in existingSales) {
        final saleId = sale['id'];
        final total = sale['total'] as double;
        final method = sale['payment_method'] as String;
        final reference = sale['reference'] as String?;
        final date = sale['date'] as String;
        final status = sale['status'] as String;
        
        // Crear un registro de pago para esta venta
        final paymentId = Uuid().v4();
        
        // Si el estado es 'Completada', añadir un pago por el total
        if (status == 'Completada') {
          await db.insert(
            'payment_details',
            {
              'id': paymentId,
              'sale_id': saleId,
              'method': method,
              'amount': total,
              'currency': 'bsf',
              'exchange_rate': 1.0,
              'amount_in_usd': total,
              'reference': reference,
              'date': date,
              'notes': null,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
          
          // Actualizar la venta con el monto pagado
          await db.update(
            'sales',
            {
              'paid_amount': total,
              'pending_amount': 0.0,
            },
            where: 'id = ?',
            whereArgs: [saleId],
          );
        } else {
          // Para otras ventas, establecer todo como pendiente
          await db.update(
            'sales',
            {
              'paid_amount': 0.0,
              'pending_amount': total,
            },
            where: 'id = ?',
            whereArgs: [saleId],
          );
        }
      }
      
      // Eliminar las columnas obsoletas (en SQLite no se pueden eliminar columnas directamente)
      // Hay que crear una tabla temporal, copiar los datos, y luego renombrarla
      
      // Agregar las columnas faltantes para compatibilidad con el modelo Sale
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN total_in_usd REAL NOT NULL DEFAULT 0.0');
        await db.execute('ALTER TABLE sales ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0');
      } catch (e) {
        print('Error al agregar columnas: $e');
        // Las columnas pueden ya existir, continuar con la migración
      }
      
      // Primero crear una tabla temporal con la nueva estructura
      await db.execute('''
        CREATE TABLE sales_temp(
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          customer_name TEXT,
          date TEXT NOT NULL,
          subtotal REAL NOT NULL,
          discount REAL NOT NULL,
          total REAL NOT NULL,
          total_in_usd REAL NOT NULL,
          exchange_rate REAL NOT NULL,
          status TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          paid_amount REAL NOT NULL,
          pending_amount REAL NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
        )
      ''');
      
      // Copiar los datos
      await db.execute('''
        INSERT INTO sales_temp 
        SELECT 
          id, 
          customer_id, 
          customer_name, 
          date, 
          subtotal, 
          discount, 
          total, 
          COALESCE(total_in_usd, total) as total_in_usd,
          COALESCE(exchange_rate, 1.0) as exchange_rate,
          status, 
          notes, 
          created_at, 
          updated_at,
          paid_amount,
          pending_amount
        FROM sales
      ''');
      
      // Eliminar la tabla original
      await db.execute('DROP TABLE sales');
      
      // Renombrar la tabla temporal
      await db.execute('ALTER TABLE sales_temp RENAME TO sales');
    }
    
    if (oldVersion < 8) {
      // Verificar y añadir columnas que pueden faltar en sales
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info(sales)");
        
        final hasTotalInUsdColumn = tableInfo.any((column) => column['name'] == 'total_in_usd');
        final hasExchangeRateColumn = tableInfo.any((column) => column['name'] == 'exchange_rate');
        
        if (!hasTotalInUsdColumn) {
          await db.execute('ALTER TABLE sales ADD COLUMN total_in_usd REAL NOT NULL DEFAULT 0.0');
        }
        
        if (!hasExchangeRateColumn) {
          await db.execute('ALTER TABLE sales ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0');
        }
        
        // Actualizar registros existentes para que tengan valores válidos
        await db.execute('''
          UPDATE sales 
          SET total_in_usd = total, exchange_rate = 1.0 
          WHERE total_in_usd IS NULL OR total_in_usd = 0
        ''');
        
      } catch (e) {
        print('Error al verificar/añadir columnas: $e');
      }
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

  Future<void> _insertDefaultSuppliers(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Samsung Electronics
    await db.insert('suppliers', {
      'id': 'samsung',
      'business_name': 'Samsung Electronics',
      'legal_name': 'Samsung Electronics Co., Ltd.',
      'tax_id': 'J-123456789',
      'address': 'Suwon, Corea del Sur',
      'phone': '+82 31 200 3000',
      'email': 'contacto@samsung.com',
      'contact_person': 'John Smith',
      'is_active': 1,
      'notes': 'Proveedor principal de electrónica',
      'instagram': '@samsunglatam',
      'mercado_libre': 'samsung_official',
      'website': 'https://www.samsung.com',
      'created_at': now,
      'updated_at': now,
    });

    // HP Inc.
    await db.insert('suppliers', {
      'id': 'hp',
      'business_name': 'HP Inc.',
      'legal_name': 'HP Inc.',
      'tax_id': 'J-987654321',
      'address': 'Palo Alto, California, USA',
      'phone': '+1 650 857 1501',
      'email': 'contacto@hp.com',
      'contact_person': 'Maria Rodriguez',
      'is_active': 1,
      'notes': 'Proveedor de computadoras e impresoras',
      'instagram': '@hp',
      'mercado_libre': 'hp_store',
      'website': 'https://www.hp.com',
      'created_at': now,
      'updated_at': now,
    });

    // LG Electronics
    await db.insert('suppliers', {
      'id': 'lg',
      'business_name': 'LG Electronics',
      'legal_name': 'LG Electronics Inc.',
      'tax_id': 'J-567890123',
      'address': 'Seúl, Corea del Sur',
      'phone': '+82 2 3777 1114',
      'email': 'contacto@lg.com',
      'contact_person': 'Carlos Lee',
      'is_active': 1,
      'notes': 'Proveedor de electrodomésticos y electrónica',
      'instagram': '@lg',
      'mercado_libre': 'lg_oficial',
      'website': 'https://www.lg.com',
      'created_at': now,
      'updated_at': now,
    });

    // Muebles Inc.
    await db.insert('suppliers', {
      'id': 'muebles_inc',
      'business_name': 'Muebles Inc.',
      'legal_name': 'Muebles Internacionales C.A.',
      'tax_id': 'J-456789012',
      'address': 'Valencia, Venezuela',
      'phone': '+58 241 555 1234',
      'email': 'contacto@mueblesinc.com',
      'contact_person': 'Ana Martínez',
      'is_active': 1,
      'notes': 'Proveedor de muebles para el hogar',
      'instagram': '@muebles_inc',
      'mercado_libre': 'muebles_inc',
      'website': 'https://www.mueblesinc.com',
      'created_at': now,
      'updated_at': now,
    });

    // Fashion Inc.
    await db.insert('suppliers', {
      'id': 'fashion_inc',
      'business_name': 'Fashion Inc.',
      'legal_name': 'Fashion Incorporated S.A.',
      'tax_id': 'J-654321098',
      'address': 'Caracas, Venezuela',
      'phone': '+58 212 555 6789',
      'email': 'contacto@fashioninc.com',
      'contact_person': 'Laura Pérez',
      'is_active': 1,
      'notes': 'Proveedor de ropa y accesorios',
      'instagram': '@fashion_inc_ve',
      'mercado_libre': 'fashion_inc',
      'website': 'https://www.fashioninc.com',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _insertDefaultCustomers(Database db) async {
    final now = DateTime.now().toIso8601String();
    final uuid = Uuid();

    // Cliente 1
    await db.insert('customers', {
      'id': uuid.v4(),
      'first_name': 'Juan',
      'last_name': 'Pérez',
      'email': 'juan.perez@example.com',
      'phone': '+58 414 555 1234',
      'address': 'Calle Principal 123, Caracas',
      'notes': 'Cliente frecuente, compra productos electrónicos',
      'document_id': 'V-12345678',
      'document_type': 'Cédula',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Cliente 2
    await db.insert('customers', {
      'id': uuid.v4(),
      'first_name': 'María',
      'last_name': 'González',
      'email': 'maria.gonzalez@example.com',
      'phone': '+58 412 555 9876',
      'address': 'Avenida Libertador 456, Valencia',
      'notes': 'Prefiere pagos en efectivo',
      'document_id': 'V-87654321',
      'document_type': 'Cédula',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });

    // Cliente 3
    await db.insert('customers', {
      'id': uuid.v4(),
      'first_name': 'Empresa',
      'last_name': 'ABC',
      'email': 'contacto@empresaabc.com',
      'phone': '+58 212 555 4321',
      'address': 'Zona Industrial, Galpón 7, Maracay',
      'notes': 'Cliente corporativo, solicita facturas fiscales',
      'document_id': 'J-29876543',
      'document_type': 'RIF',
      'is_active': 1,
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

  // MÉTODOS PARA PROVEEDORES

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final List<Map<String, dynamic>> supplierMaps = await db.query('suppliers');
    
    if (supplierMaps.isEmpty) {
      return [];
    }

    return supplierMaps.map((supplierMap) => Supplier(
      id: supplierMap['id'],
      businessName: supplierMap['business_name'],
      legalName: supplierMap['legal_name'],
      taxId: supplierMap['tax_id'],
      address: supplierMap['address'],
      phone: supplierMap['phone'],
      email: supplierMap['email'],
      contactPerson: supplierMap['contact_person'],
      isActive: supplierMap['is_active'] == 1,
      notes: supplierMap['notes'],
      instagram: supplierMap['instagram'] ?? '',
      mercadoLibre: supplierMap['mercado_libre'] ?? '',
      website: supplierMap['website'] ?? '',
      createdAt: DateTime.parse(supplierMap['created_at']),
      updatedAt: DateTime.parse(supplierMap['updated_at']),
    )).toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> supplierMaps = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (supplierMaps.isEmpty) {
      return null;
    }

    return Supplier(
      id: supplierMaps.first['id'],
      businessName: supplierMaps.first['business_name'],
      legalName: supplierMaps.first['legal_name'],
      taxId: supplierMaps.first['tax_id'],
      address: supplierMaps.first['address'],
      phone: supplierMaps.first['phone'],
      email: supplierMaps.first['email'],
      contactPerson: supplierMaps.first['contact_person'],
      isActive: supplierMaps.first['is_active'] == 1,
      notes: supplierMaps.first['notes'],
      instagram: supplierMaps.first['instagram'] ?? '',
      mercadoLibre: supplierMaps.first['mercado_libre'] ?? '',
      website: supplierMaps.first['website'] ?? '',
      createdAt: DateTime.parse(supplierMaps.first['created_at']),
      updatedAt: DateTime.parse(supplierMaps.first['updated_at']),
    );
  }

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    return await db.insert(
      'suppliers',
      {
        'id': supplier.id,
        'business_name': supplier.businessName,
        'legal_name': supplier.legalName,
        'tax_id': supplier.taxId,
        'address': supplier.address,
        'phone': supplier.phone,
        'email': supplier.email,
        'contact_person': supplier.contactPerson,
        'is_active': supplier.isActive ? 1 : 0,
        'notes': supplier.notes,
        'instagram': supplier.instagram,
        'mercado_libre': supplier.mercadoLibre,
        'website': supplier.website,
        'created_at': supplier.createdAt.toIso8601String(),
        'updated_at': supplier.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update(
      'suppliers',
      {
        'business_name': supplier.businessName,
        'legal_name': supplier.legalName,
        'tax_id': supplier.taxId,
        'address': supplier.address,
        'phone': supplier.phone,
        'email': supplier.email,
        'contact_person': supplier.contactPerson,
        'is_active': supplier.isActive ? 1 : 0,
        'notes': supplier.notes,
        'instagram': supplier.instagram,
        'mercado_libre': supplier.mercadoLibre,
        'website': supplier.website,
        'updated_at': supplier.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(String id) async {
    final db = await database;
    
    // Verificar si hay productos asociados a este proveedor
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'supplier_id = ?',
      whereArgs: [id],
    );
    
    if (productMaps.isNotEmpty) {
      // Si hay productos asociados, no permitir la eliminación
      return 0;
    }
    
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Supplier>> getSuppliersByStatus(bool isActive) async {
    final db = await database;
    final List<Map<String, dynamic>> supplierMaps = await db.query(
      'suppliers',
      where: 'is_active = ?',
      whereArgs: [isActive ? 1 : 0],
    );
    
    if (supplierMaps.isEmpty) {
      return [];
    }

    return supplierMaps.map((supplierMap) => Supplier(
      id: supplierMap['id'],
      businessName: supplierMap['business_name'],
      legalName: supplierMap['legal_name'],
      taxId: supplierMap['tax_id'],
      address: supplierMap['address'],
      phone: supplierMap['phone'],
      email: supplierMap['email'],
      contactPerson: supplierMap['contact_person'],
      isActive: supplierMap['is_active'] == 1,
      notes: supplierMap['notes'],
      instagram: supplierMap['instagram'] ?? '',
      mercadoLibre: supplierMap['mercado_libre'] ?? '',
      website: supplierMap['website'] ?? '',
      createdAt: DateTime.parse(supplierMap['created_at']),
      updatedAt: DateTime.parse(supplierMap['updated_at']),
    )).toList();
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> supplierMaps = await db.query(
      'suppliers',
      where: 'business_name LIKE ? OR legal_name LIKE ? OR contact_person LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    
    if (supplierMaps.isEmpty) {
      return [];
    }

    return supplierMaps.map((supplierMap) => Supplier(
      id: supplierMap['id'],
      businessName: supplierMap['business_name'],
      legalName: supplierMap['legal_name'],
      taxId: supplierMap['tax_id'],
      address: supplierMap['address'],
      phone: supplierMap['phone'],
      email: supplierMap['email'],
      contactPerson: supplierMap['contact_person'],
      isActive: supplierMap['is_active'] == 1,
      notes: supplierMap['notes'],
      instagram: supplierMap['instagram'] ?? '',
      mercadoLibre: supplierMap['mercado_libre'] ?? '',
      website: supplierMap['website'] ?? '',
      createdAt: DateTime.parse(supplierMap['created_at']),
      updatedAt: DateTime.parse(supplierMap['updated_at']),
    )).toList();
  }

  // Método para obtener los productos de un proveedor específico
  Future<List<Product>> getProductsBySupplier(String supplierId) async {
    final db = await database;
    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
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

  // MÉTODOS PARA CLIENTES

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> customerMaps = await db.query('customers');
    
    if (customerMaps.isEmpty) {
      return [];
    }

    return customerMaps.map((customerMap) => Customer(
      id: customerMap['id'],
      firstName: customerMap['first_name'],
      lastName: customerMap['last_name'],
      email: customerMap['email'],
      phone: customerMap['phone'],
      address: customerMap['address'],
      notes: customerMap['notes'],
      documentId: customerMap['document_id'],
      documentType: customerMap['document_type'],
      isActive: customerMap['is_active'] == 1,
      createdAt: DateTime.parse(customerMap['created_at']),
      updatedAt: DateTime.parse(customerMap['updated_at']),
    )).toList();
  }

  // Obtener clientes activos
  Future<List<Customer>> getActiveCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> customerMaps = await db.query(
      'customers',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    
    if (customerMaps.isEmpty) {
      return [];
    }

    return customerMaps.map((customerMap) => Customer(
      id: customerMap['id'],
      firstName: customerMap['first_name'],
      lastName: customerMap['last_name'],
      email: customerMap['email'],
      phone: customerMap['phone'],
      address: customerMap['address'],
      notes: customerMap['notes'],
      documentId: customerMap['document_id'],
      documentType: customerMap['document_type'],
      isActive: customerMap['is_active'] == 1,
      createdAt: DateTime.parse(customerMap['created_at']),
      updatedAt: DateTime.parse(customerMap['updated_at']),
    )).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> customerMaps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (customerMaps.isEmpty) {
      return null;
    }

    return Customer(
      id: customerMaps.first['id'],
      firstName: customerMaps.first['first_name'],
      lastName: customerMaps.first['last_name'],
      email: customerMaps.first['email'],
      phone: customerMaps.first['phone'],
      address: customerMaps.first['address'],
      notes: customerMaps.first['notes'],
      documentId: customerMaps.first['document_id'],
      documentType: customerMaps.first['document_type'],
      isActive: customerMaps.first['is_active'] == 1,
      createdAt: DateTime.parse(customerMaps.first['created_at']),
      updatedAt: DateTime.parse(customerMaps.first['updated_at']),
    );
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(
      'customers',
      {
        'id': customer.id,
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'email': customer.email,
        'phone': customer.phone,
        'address': customer.address,
        'notes': customer.notes,
        'document_id': customer.documentId,
        'document_type': customer.documentType,
        'is_active': customer.isActive ? 1 : 0,
        'created_at': customer.createdAt.toIso8601String(),
        'updated_at': customer.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      {
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'email': customer.email,
        'phone': customer.phone,
        'address': customer.address,
        'notes': customer.notes,
        'document_id': customer.documentId,
        'document_type': customer.documentType,
        'is_active': customer.isActive ? 1 : 0,
        'updated_at': customer.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(String id) async {
    final db = await database;
    
    // Aquí se puede agregar lógica para verificar si hay ventas asociadas a este cliente
    
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> customerMaps = await db.query(
      'customers',
      where: 'first_name LIKE ? OR last_name LIKE ? OR document_id LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    
    if (customerMaps.isEmpty) {
      return [];
    }

    return customerMaps.map((customerMap) => Customer(
      id: customerMap['id'],
      firstName: customerMap['first_name'],
      lastName: customerMap['last_name'],
      email: customerMap['email'],
      phone: customerMap['phone'],
      address: customerMap['address'],
      notes: customerMap['notes'],
      documentId: customerMap['document_id'],
      documentType: customerMap['document_type'],
      isActive: customerMap['is_active'] == 1,
      createdAt: DateTime.parse(customerMap['created_at']),
      updatedAt: DateTime.parse(customerMap['updated_at']),
    )).toList();
  }

  // MÉTODOS PARA VENTAS

  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query('sales', orderBy: 'date DESC');
    
    if (saleMaps.isEmpty) {
      return [];
    }

    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      // Obtener los items para esta venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        id: itemMap['id'],
        saleId: itemMap['sale_id'],
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        discount: itemMap['discount'],
        notes: itemMap['notes'],
      )).toList();

      // Obtener los pagos para esta venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payment_details',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<PaymentDetail> payments = paymentMaps.map((paymentMap) => PaymentDetail(
        id: paymentMap['id'],
        method: Sale.stringToPaymentMethod(paymentMap['method']),
        amount: paymentMap['amount'],
        currency: Sale.stringToPaymentCurrency(paymentMap['currency'] ?? 'bsf'),
        exchangeRate: paymentMap['exchange_rate'] ?? 1.0,
        amountInUsd: paymentMap['amount_in_usd'] ?? paymentMap['amount'],
        reference: paymentMap['reference'],
        date: DateTime.parse(paymentMap['date']),
        notes: paymentMap['notes'],
      )).toList();

      // Crear el objeto Sale
      sales.add(Sale(
        id: saleMap['id'],
        customerId: saleMap['customer_id'],
        customerName: saleMap['customer_name'],
        date: DateTime.parse(saleMap['date']),
        items: items,
        subtotal: saleMap['subtotal'],
        discount: saleMap['discount'],
        total: saleMap['total'],
        totalInUsd: saleMap['total_in_usd'] ?? saleMap['total'],
        exchangeRate: saleMap['exchange_rate'] ?? 1.0,
        payments: payments,
        status: Sale.stringToStatus(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
        paidAmount: saleMap['paid_amount'],
        pendingAmount: saleMap['pending_amount'],
      ));
    }

    return sales;
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    
    if (saleMaps.isEmpty) {
      return [];
    }

    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      // Obtener los items para esta venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        id: itemMap['id'],
        saleId: itemMap['sale_id'],
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        discount: itemMap['discount'],
        notes: itemMap['notes'],
      )).toList();

      // Obtener los pagos para esta venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payment_details',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<PaymentDetail> payments = paymentMaps.map((paymentMap) => PaymentDetail(
        id: paymentMap['id'],
        method: Sale.stringToPaymentMethod(paymentMap['method']),
        amount: paymentMap['amount'],
        currency: Sale.stringToPaymentCurrency(paymentMap['currency'] ?? 'bsf'),
        exchangeRate: paymentMap['exchange_rate'] ?? 1.0,
        amountInUsd: paymentMap['amount_in_usd'] ?? paymentMap['amount'],
        reference: paymentMap['reference'],
        date: DateTime.parse(paymentMap['date']),
        notes: paymentMap['notes'],
      )).toList();

      // Crear el objeto Sale
      sales.add(Sale(
        id: saleMap['id'],
        customerId: saleMap['customer_id'],
        customerName: saleMap['customer_name'],
        date: DateTime.parse(saleMap['date']),
        items: items,
        subtotal: saleMap['subtotal'],
        discount: saleMap['discount'],
        total: saleMap['total'],
        totalInUsd: saleMap['total_in_usd'] ?? saleMap['total'],
        exchangeRate: saleMap['exchange_rate'] ?? 1.0,
        payments: payments,
        status: Sale.stringToStatus(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
        paidAmount: saleMap['paid_amount'],
        pendingAmount: saleMap['pending_amount'],
      ));
    }

    return sales;
  }

  Future<List<Sale>> getSalesByCustomer(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    
    if (saleMaps.isEmpty) {
      return [];
    }

    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      // Obtener los items para esta venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        id: itemMap['id'],
        saleId: itemMap['sale_id'],
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        discount: itemMap['discount'],
        notes: itemMap['notes'],
      )).toList();

      // Obtener los pagos para esta venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payment_details',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<PaymentDetail> payments = paymentMaps.map((paymentMap) => PaymentDetail(
        id: paymentMap['id'],
        method: Sale.stringToPaymentMethod(paymentMap['method']),
        amount: paymentMap['amount'],
        currency: Sale.stringToPaymentCurrency(paymentMap['currency'] ?? 'bsf'),
        exchangeRate: paymentMap['exchange_rate'] ?? 1.0,
        amountInUsd: paymentMap['amount_in_usd'] ?? paymentMap['amount'],
        reference: paymentMap['reference'],
        date: DateTime.parse(paymentMap['date']),
        notes: paymentMap['notes'],
      )).toList();

      // Crear el objeto Sale
      sales.add(Sale(
        id: saleMap['id'],
        customerId: saleMap['customer_id'],
        customerName: saleMap['customer_name'],
        date: DateTime.parse(saleMap['date']),
        items: items,
        subtotal: saleMap['subtotal'],
        discount: saleMap['discount'],
        total: saleMap['total'],
        totalInUsd: saleMap['total_in_usd'] ?? saleMap['total'],
        exchangeRate: saleMap['exchange_rate'] ?? 1.0,
        payments: payments,
        status: Sale.stringToStatus(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
        paidAmount: saleMap['paid_amount'],
        pendingAmount: saleMap['pending_amount'],
      ));
    }

    return sales;
  }

  Future<Sale?> getSaleById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (saleMaps.isEmpty) {
      return null;
    }

    // Obtener los items para esta venta
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    
    List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
      id: itemMap['id'],
      saleId: itemMap['sale_id'],
      productId: itemMap['product_id'],
      productName: itemMap['product_name'],
      price: itemMap['price'],
      quantity: itemMap['quantity'],
      subtotal: itemMap['subtotal'],
      discount: itemMap['discount'],
      notes: itemMap['notes'],
    )).toList();

    // Obtener los pagos para esta venta
    final List<Map<String, dynamic>> paymentMaps = await db.query(
      'payment_details',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    
    List<PaymentDetail> payments = paymentMaps.map((paymentMap) => PaymentDetail(
      id: paymentMap['id'],
      method: Sale.stringToPaymentMethod(paymentMap['method']),
      amount: paymentMap['amount'],
      currency: Sale.stringToPaymentCurrency(paymentMap['currency'] ?? 'bsf'),
      exchangeRate: paymentMap['exchange_rate'] ?? 1.0,
      amountInUsd: paymentMap['amount_in_usd'] ?? paymentMap['amount'],
      reference: paymentMap['reference'],
      date: DateTime.parse(paymentMap['date']),
      notes: paymentMap['notes'],
    )).toList();

    // Crear el objeto Sale
    return Sale(
      id: saleMaps.first['id'],
      customerId: saleMaps.first['customer_id'],
      customerName: saleMaps.first['customer_name'],
      date: DateTime.parse(saleMaps.first['date']),
      items: items,
      subtotal: saleMaps.first['subtotal'],
      discount: saleMaps.first['discount'],
      total: saleMaps.first['total'],
      totalInUsd: saleMaps.first['total_in_usd'] ?? saleMaps.first['total'],
      exchangeRate: saleMaps.first['exchange_rate'] ?? 1.0,
      payments: payments,
      status: Sale.stringToStatus(saleMaps.first['status']),
      notes: saleMaps.first['notes'],
      createdAt: DateTime.parse(saleMaps.first['created_at']),
      updatedAt: DateTime.parse(saleMaps.first['updated_at']),
      paidAmount: saleMaps.first['paid_amount'],
      pendingAmount: saleMaps.first['pending_amount'],
    );
  }

  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await database;
    
    // Iniciar una transacción
    return await db.transaction((txn) async {
      // Insertar la venta principal
      final saleId = await txn.insert(
        'sales',
        {
          'id': sale.id,
          'customer_id': sale.customerId,
          'customer_name': sale.customerName,
          'date': sale.date.toIso8601String(),
          'subtotal': sale.subtotal,
          'discount': sale.discount,
          'total': sale.total,
          'total_in_usd': sale.totalInUsd,
          'exchange_rate': sale.exchangeRate,
          'status': Sale.statusToString(sale.status),
          'notes': sale.notes,
          'created_at': sale.createdAt.toIso8601String(),
          'updated_at': sale.updatedAt.toIso8601String(),
          'paid_amount': sale.paidAmount,
          'pending_amount': sale.pendingAmount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insertar los items de la venta
      for (SaleItem item in items) {
        await txn.insert(
          'sale_items',
          {
            'id': item.id,
            'sale_id': sale.id,
            'product_id': item.productId,
            'product_name': item.productName,
            'price': item.price,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
            'discount': item.discount,
            'notes': item.notes,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Actualizar el stock del producto
        final productMapList = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        
        if (productMapList.isNotEmpty) {
          final currentStock = productMapList.first['current_stock'] as int;
          await txn.update(
            'products',
            {
              'current_stock': currentStock - item.quantity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      // Insertar los pagos
      for (var payment in sale.payments) {
        await txn.insert(
          'payment_details',
          {
            'id': payment.id,
            'sale_id': sale.id,
            'method': Sale.paymentMethodToString(payment.method),
            'amount': payment.amount,
            'currency': Sale.paymentCurrencyToString(payment.currency),
            'exchange_rate': payment.exchangeRate,
            'amount_in_usd': payment.amountInUsd,
            'reference': payment.reference,
            'date': payment.date.toIso8601String(),
            'notes': payment.notes,
            'created_at': DateTime.now().toIso8601String(), // Añadir campo created_at
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return 1; // Éxito
    });
  }

  Future<int> updateSaleStatus(String id, SaleStatus status) async {
    final db = await database;
    return await db.update(
      'sales',
      {
        'status': Sale.statusToString(status),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSale(String id) async {
    final db = await database;
    
    // Comenzar una transacción
    return await db.transaction((txn) async {
      // Obtener los items de la venta
      final List<Map<String, dynamic>> itemMaps = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [id],
      );
      
      // Si la venta tiene ítems, verificar estado y restaurar stock
      final List<Map<String, dynamic>> saleMap = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (saleMap.isNotEmpty) {
        final status = Sale.stringToStatus(saleMap.first['status']);
        
        // Solo restaurar stock si la venta está completada
        if (status == SaleStatus.completed) {
          for (var item in itemMaps) {
            final productId = item['product_id'];
            final quantity = item['quantity'] as int;
            
            // Obtener el producto
            final productMap = await txn.query(
              'products',
              where: 'id = ?',
              whereArgs: [productId],
            );
            
            if (productMap.isNotEmpty) {
              final currentStock = productMap.first['current_stock'] as int;
              
              // Restaurar el stock
              await txn.update(
                'products',
                {
                  'current_stock': currentStock + quantity,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [productId],
              );
            }
          }
        }
      }
      
      // Eliminar los items de la venta (se eliminarán en cascada por la relación)
      await txn.delete(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [id],
      );
      
      // Eliminar la venta principal
      return await txn.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Método para obtener métricas de ventas (por ejemplo, ventas por período)
  Future<Map<String, dynamic>> getSalesMetrics(DateTime start, DateTime end) async {
    final db = await database;
    
    // Obtener el total de ventas en el período
    final totalSalesResult = await db.rawQuery('''
      SELECT SUM(total) as total_sales, COUNT(*) as sale_count
      FROM sales
      WHERE date BETWEEN ? AND ?
      AND status = ?
    ''', [start.toIso8601String(), end.toIso8601String(), Sale.statusToString(SaleStatus.completed)]);
    
    final double totalSales = totalSalesResult.first['total_sales'] != null 
        ? (totalSalesResult.first['total_sales'] as num).toDouble() 
        : 0.0;
    
    final int saleCount = totalSalesResult.first['sale_count'] != null 
        ? totalSalesResult.first['sale_count'] as int 
        : 0;
    
    // Obtener los productos más vendidos
    final topProductsResult = await db.rawQuery('''
      SELECT product_id, product_name, SUM(quantity) as total_quantity
      FROM sale_items
      INNER JOIN sales ON sale_items.sale_id = sales.id
      WHERE sales.date BETWEEN ? AND ?
      AND sales.status = ?
      GROUP BY product_id
      ORDER BY total_quantity DESC
      LIMIT 5
    ''', [start.toIso8601String(), end.toIso8601String(), Sale.statusToString(SaleStatus.completed)]);
    
    // Convertir los resultados a un formato utilizable
    final List<Map<String, dynamic>> topProducts = topProductsResult.map((result) {
      return {
        'productId': result['product_id'],
        'productName': result['product_name'],
        'totalQuantity': result['total_quantity'],
      };
    }).toList();
    
    return {
      'totalSales': totalSales,
      'saleCount': saleCount,
      'topProducts': topProducts,
    };
  }

  // Nuevo método para obtener ventas a crédito
  Future<List<Sale>> getCreditSales() async {
    final db = await database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'status = ? OR pending_amount > 0',
      whereArgs: [Sale.statusToString(SaleStatus.credit)],
      orderBy: 'date DESC',
    );
    
    if (saleMaps.isEmpty) {
      return [];
    }

    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      // Obtener los items para esta venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        id: itemMap['id'],
        saleId: itemMap['sale_id'],
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        discount: itemMap['discount'],
        notes: itemMap['notes'],
      )).toList();

      // Obtener los pagos para esta venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payment_details',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      
      List<PaymentDetail> payments = paymentMaps.map((paymentMap) => PaymentDetail(
        id: paymentMap['id'],
        method: Sale.stringToPaymentMethod(paymentMap['method']),
        amount: paymentMap['amount'],
        currency: Sale.stringToPaymentCurrency(paymentMap['currency'] ?? 'bsf'),
        exchangeRate: paymentMap['exchange_rate'] ?? 1.0,
        amountInUsd: paymentMap['amount_in_usd'] ?? paymentMap['amount'],
        reference: paymentMap['reference'],
        date: DateTime.parse(paymentMap['date']),
        notes: paymentMap['notes'],
      )).toList();

      // Crear el objeto Sale
      sales.add(Sale(
        id: saleMap['id'],
        customerId: saleMap['customer_id'],
        customerName: saleMap['customer_name'],
        date: DateTime.parse(saleMap['date']),
        items: items,
        subtotal: saleMap['subtotal'],
        discount: saleMap['discount'],
        total: saleMap['total'],
        totalInUsd: saleMap['total_in_usd'] ?? saleMap['total'],
        exchangeRate: saleMap['exchange_rate'] ?? 1.0,
        payments: payments,
        status: Sale.stringToStatus(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
        paidAmount: saleMap['paid_amount'],
        pendingAmount: saleMap['pending_amount'],
      ));
    }

    return sales;
  }

  // Actualizar los montos pagados y pendientes de una venta
  Future<int> updateSalePayments(String saleId, double paidAmount, double pendingAmount) async {
    final db = await database;
    return await db.update(
      'sales',
      {
        'paid_amount': paidAmount,
        'pending_amount': pendingAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  // Añadir un nuevo pago a una venta existente
  Future<int> addPaymentToSale(String saleId, PaymentDetail payment) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      // Insertar el detalle de pago
      final paymentId = await txn.insert(
        'payment_details',
        {
          'id': payment.id,
          'sale_id': saleId,
          'method': Sale.paymentMethodToString(payment.method),
          'amount': payment.amount,
          'currency': Sale.paymentCurrencyToString(payment.currency),
          'exchange_rate': payment.exchangeRate,
          'amount_in_usd': payment.amountInUsd,
          'reference': payment.reference,
          'date': payment.date.toIso8601String(),
          'notes': payment.notes,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Obtener la venta
      final saleMap = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );
      
      if (saleMap.isNotEmpty) {
        final currentPaidAmount = saleMap.first['paid_amount'] as double;
        final currentPendingAmount = saleMap.first['pending_amount'] as double;
        final total = saleMap.first['total'] as double;
        
        // Calcular los nuevos montos
        final newPaidAmount = currentPaidAmount + payment.amount;
        final newPendingAmount = total - newPaidAmount;
        
        // Determinar si la venta debe cambiar de estado
        String status = saleMap.first['status'] as String;
        if (newPendingAmount <= 0 && status == Sale.statusToString(SaleStatus.credit)) {
          status = Sale.statusToString(SaleStatus.completed);
        }
        
        // Actualizar la venta
        await txn.update(
          'sales',
          {
            'paid_amount': newPaidAmount,
            'pending_amount': newPendingAmount,
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [saleId],
        );
      }
      
      return paymentId;
    });
  }

  Future<void> addMonthlySales(String month, String year, double amount, String method, String reference, String date) async {
    final db = await database;
    
    final saleId = Uuid().v4();
    final itemId = Uuid().v4();
    final paymentId = Uuid().v4();
    
    // Insertar venta
    await db.insert(
      'sales',
      {
        'id': saleId,
        'customer_id': 'system',
        'customer_name': 'Sistema',
        'date': date,
        'subtotal': amount,
        'discount': 0.0,
        'total': amount,
        'total_in_usd': amount,
        'exchange_rate': 1.0,
        'status': 'Completada',
        'notes': 'Venta mensual para $month/$year',
        'created_at': date,
        'updated_at': date,
        'paid_amount': amount,
        'pending_amount': 0.0,
      },
    );
    
    // Insertar ítem
    await db.insert(
      'sale_items',
      {
        'id': itemId,
        'sale_id': saleId,
        'product_id': 'monthly_sales',
        'product_name': 'Ventas Mensuales',
        'price': amount,
        'quantity': 1,
        'subtotal': amount,
        'discount': 0.0,
        'notes': 'Ventas acumuladas para $month/$year',
      },
    );
    
    // Insertar pago
    await db.insert(
      'payment_details',
      {
        'id': paymentId,
        'sale_id': saleId,
        'method': method,
        'amount': amount,
        'currency': 'bsf',
        'exchange_rate': 1.0,
        'amount_in_usd': amount,
        'reference': reference,
        'date': date,
        'notes': 'Venta mensual para $month/$year',
        'created_at': date,
      },
    );
  }
} 