import 'package:uuid/uuid.dart';
import '../models/product.dart';
import 'database_service.dart';

class ProductService {
  final DatabaseService _dbService = DatabaseService();
  static final _uuid = Uuid();
  static bool _mockDataAdded = false;

  // Obtener todos los productos
  Future<List<Product>> getAllProducts() async {
    final products = await _dbService.getAllProducts();
    if (products.isEmpty && !_mockDataAdded) {
      await addMockData();
      return await _dbService.getAllProducts();
    }
    return products;
  }

  // Obtener producto por ID
  Future<Product?> getProductById(String id) async {
    return await _dbService.getProductById(id);
  }

  // Filtrar productos
  Future<List<Product>> filterProducts({
    String? searchQuery,
    String? categoryId,
    bool? lowStockOnly,
  }) async {
    List<Product> products = await _dbService.getAllProducts();

    return products.where((product) {
      // Filtrar por texto de búsqueda
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtrar por categoría
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        if (product.categoryId != categoryId) {
          return false;
        }
      }

      // Filtrar por stock bajo
      if (lowStockOnly == true) {
        if (!product.isLowStock) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Crear producto
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int current_stock,
    required int minimumStock,
    String? categoryId,
    required String supplierId,
    required List<String> imageUrls,
    required Map<String, dynamic> specifications,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: _uuid.v4(),
      name: name,
      description: description,
      price: price,
      current_stock: current_stock,
      minimumStock: minimumStock,
      categoryId: categoryId,
      supplierId: supplierId,
      imageUrls: imageUrls,
      specifications: specifications,
      createdAt: now,
      updatedAt: now,
    );

    await _dbService.insertProduct(product);
    return product;
  }

  // Actualizar producto
  Future<Product?> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? current_stock,
    int? minimumStock,
    String? categoryId,
    String? supplierId,
    List<String>? imageUrls,
    Map<String, dynamic>? specifications,
  }) async {
    final oldProduct = await _dbService.getProductById(id);
    if (oldProduct == null) return null;

    final updatedProduct = Product(
      id: oldProduct.id,
      name: name ?? oldProduct.name,
      description: description ?? oldProduct.description,
      price: price ?? oldProduct.price,
      current_stock: current_stock ?? oldProduct.current_stock,
      minimumStock: minimumStock ?? oldProduct.minimumStock,
      categoryId: categoryId ?? oldProduct.categoryId,
      supplierId: supplierId ?? oldProduct.supplierId,
      imageUrls: imageUrls ?? oldProduct.imageUrls,
      specifications: specifications ?? oldProduct.specifications,
      createdAt: oldProduct.createdAt,
      updatedAt: DateTime.now(),
    );

    await _dbService.updateProduct(updatedProduct);
    return updatedProduct;
  }

  // Eliminar producto
  Future<bool> deleteProduct(String id) async {
    final result = await _dbService.deleteProduct(id);
    return result > 0;
  }

  // Agregar stock
  Future<Product?> addStock(String id, int quantity) async {
    final product = await _dbService.getProductById(id);
    if (product == null) return null;

    final newStock = product.current_stock + quantity;
    await _dbService.updateProductStock(id, newStock);
    
    return await _dbService.getProductById(id);
  }

  // Remover stock
  Future<Product?> removeStock(String id, int quantity) async {
    final product = await _dbService.getProductById(id);
    if (product == null) return null;

    if (product.current_stock < quantity) {
      throw Exception('No hay suficiente stock disponible');
    }

    final newStock = product.current_stock - quantity;
    await _dbService.updateProductStock(id, newStock);
    
    return await _dbService.getProductById(id);
  }

  // Agregar datos de prueba
  Future<void> addMockData() async {
    if (_mockDataAdded) return;

    final now = DateTime.now();
    
    final List<Product> mockProducts = [
      Product(
        id: _uuid.v4(),
        name: 'Smartphone Samsung Galaxy S21',
        description: 'Smartphone de alta gama con cámara de 108MP y pantalla AMOLED de 6.2"',
        price: 799.99,
        current_stock: 15,
        minimumStock: 5,
        categoryId: 'electrónica',
        supplierId: 'samsung',
        imageUrls: ['https://via.placeholder.com/300x300?text=Samsung+S21'],
        specifications: {
          'processor': 'Exynos 2100',
          'ram': '8GB',
          'storage': '128GB',
          'screen': '6.2" AMOLED',
        },
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Laptop HP Pavilion',
        description: 'Laptop con procesador Intel i5, 8GB RAM y SSD de 512GB',
        price: 649.99,
        current_stock: 8,
        minimumStock: 3,
        categoryId: 'electrónica',
        supplierId: 'hp',
        imageUrls: ['https://via.placeholder.com/300x300?text=HP+Pavilion'],
        specifications: {
          'processor': 'Intel i5',
          'ram': '8GB',
          'storage': '512GB SSD',
          'screen': '15.6" Full HD',
        },
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Silla de Oficina Ergonómica',
        description: 'Silla ergonómica con soporte lumbar y apoyabrazos ajustables',
        price: 199.99,
        current_stock: 12,
        minimumStock: 5,
        categoryId: 'hogar',
        supplierId: 'muebles_inc',
        imageUrls: ['https://via.placeholder.com/300x300?text=Office+Chair'],
        specifications: {
          'material': 'Malla y plástico de alto impacto',
          'color': 'Negro',
          'peso_max': '120kg',
        },
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Televisor LG OLED 65"',
        description: 'Smart TV OLED con resolución 4K y tecnología de IA',
        price: 1299.99,
        current_stock: 5,
        minimumStock: 2,
        categoryId: 'electrónica',
        supplierId: 'lg',
        imageUrls: ['https://via.placeholder.com/300x300?text=LG+OLED+TV'],
        specifications: {
          'pantalla': 'OLED 65"',
          'resolución': '4K UHD',
          'smart_tv': 'WebOS',
          'conectividad': 'HDMI, USB, Wi-Fi, Bluetooth',
        },
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Camisa de Algodón Premium',
        description: 'Camisa casual de algodón de alta calidad con diseño elegante',
        price: 49.99,
        current_stock: 25,
        minimumStock: 10,
        categoryId: 'ropa',
        supplierId: 'fashion_inc',
        imageUrls: ['https://via.placeholder.com/300x300?text=Premium+Shirt'],
        specifications: {
          'material': 'Algodón 100%',
          'colores': 'Blanco, Negro, Azul',
          'tallas': 'S, M, L, XL',
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final product in mockProducts) {
      await _dbService.insertProduct(product);
    }

    _mockDataAdded = true;
  }
} 