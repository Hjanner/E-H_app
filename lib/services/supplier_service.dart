import 'package:ehstore_app/models/supplier.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/database_service.dart';
import 'package:uuid/uuid.dart';

class SupplierService {
  final _databaseService = DatabaseService();
  final _uuid = Uuid();

  // Obtener todos los proveedores
  Future<List<Supplier>> getAllSuppliers() async {
    return await _databaseService.getAllSuppliers();
  }

  // Obtener proveedores activos
  Future<List<Supplier>> getActiveSuppliers() async {
    return await _databaseService.getSuppliersByStatus(true);
  }

  // Obtener proveedores inactivos
  Future<List<Supplier>> getInactiveSuppliers() async {
    return await _databaseService.getSuppliersByStatus(false);
  }

  // Obtener proveedor por ID
  Future<Supplier?> getSupplierById(String id) async {
    return await _databaseService.getSupplierById(id);
  }

  // Buscar proveedores por nombre
  Future<List<Supplier>> searchSuppliers(String query) async {
    return await _databaseService.searchSuppliers(query);
  }

  // Crear un nuevo proveedor
  Future<String> createSupplier({
    required String businessName,
    required String legalName,
    required String taxId,
    required String address,
    required String phone,
    required String email,
    required String contactPerson,
    required bool isActive,
    required String notes,
    String instagram = '',
    String mercadoLibre = '',
    String website = '',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    
    final supplier = Supplier(
      id: id,
      businessName: businessName,
      legalName: legalName,
      taxId: taxId,
      address: address,
      phone: phone,
      email: email,
      contactPerson: contactPerson,
      isActive: isActive,
      notes: notes,
      instagram: instagram,
      mercadoLibre: mercadoLibre,
      website: website,
      createdAt: now,
      updatedAt: now,
    );
    
    await _databaseService.insertSupplier(supplier);
    return id;
  }

  // Actualizar un proveedor existente
  Future<bool> updateSupplier({
    required String id,
    required String businessName,
    required String legalName,
    required String taxId,
    required String address,
    required String phone,
    required String email,
    required String contactPerson,
    required bool isActive,
    required String notes,
    String instagram = '',
    String mercadoLibre = '',
    String website = '',
  }) async {
    final existingSupplier = await _databaseService.getSupplierById(id);
    
    if (existingSupplier == null) {
      return false;
    }
    
    final updatedSupplier = existingSupplier.copyWith(
      businessName: businessName,
      legalName: legalName,
      taxId: taxId,
      address: address,
      phone: phone,
      email: email,
      contactPerson: contactPerson,
      isActive: isActive,
      notes: notes,
      instagram: instagram,
      mercadoLibre: mercadoLibre,
      website: website,
    );
    
    final result = await _databaseService.updateSupplier(updatedSupplier);
    return result > 0;
  }

  // Cambiar el estado (activo/inactivo) de un proveedor
  Future<bool> toggleSupplierStatus(String id) async {
    final supplier = await _databaseService.getSupplierById(id);
    
    if (supplier == null) {
      return false;
    }
    
    final updatedSupplier = supplier.copyWith(
      isActive: !supplier.isActive,
    );
    
    final result = await _databaseService.updateSupplier(updatedSupplier);
    return result > 0;
  }

  // Eliminar un proveedor
  Future<bool> deleteSupplier(String id) async {
    // Verificar si hay productos asociados a este proveedor
    final products = await _databaseService.getProductsBySupplier(id);
    
    if (products.isNotEmpty) {
      // No se puede eliminar un proveedor con productos asociados
      return false;
    }
    
    final result = await _databaseService.deleteSupplier(id);
    return result > 0;
  }

  // Obtener productos por proveedor
  Future<List<Product>> getProductsBySupplier(String supplierId) async {
    return await _databaseService.getProductsBySupplier(supplierId);
  }
} 