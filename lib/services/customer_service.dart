import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/database_service.dart';
import 'package:uuid/uuid.dart';

class CustomerService {
  final _databaseService = DatabaseService();
  final _uuid = Uuid();

  // Obtener todos los clientes
  Future<List<Customer>> getAllCustomers() async {
    return await _databaseService.getAllCustomers();
  }

  // Obtener clientes activos
  Future<List<Customer>> getActiveCustomers() async {
    return await _databaseService.getActiveCustomers();
  }

  // Obtener cliente por ID
  Future<Customer?> getCustomerById(String id) async {
    return await _databaseService.getCustomerById(id);
  }

  // Buscar clientes por nombre o documento
  Future<List<Customer>> searchCustomers(String query) async {
    return await _databaseService.searchCustomers(query);
  }

  // Crear un nuevo cliente
  Future<String> createCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String notes,
    required String documentId,
    required String documentType,
    required bool isActive,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    
    final customer = Customer(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      notes: notes,
      documentId: documentId,
      documentType: documentType,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
    
    await _databaseService.insertCustomer(customer);
    return id;
  }

  // Actualizar un cliente existente
  Future<bool> updateCustomer({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String notes,
    required String documentId,
    required String documentType,
    required bool isActive,
  }) async {
    final existingCustomer = await _databaseService.getCustomerById(id);
    
    if (existingCustomer == null) {
      return false;
    }
    
    final updatedCustomer = existingCustomer.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      address: address,
      notes: notes,
      documentId: documentId,
      documentType: documentType,
      isActive: isActive,
    );
    
    final result = await _databaseService.updateCustomer(updatedCustomer);
    return result > 0;
  }

  // Cambiar el estado (activo/inactivo) de un cliente
  Future<bool> toggleCustomerStatus(String id) async {
    final customer = await _databaseService.getCustomerById(id);
    
    if (customer == null) {
      return false;
    }
    
    final updatedCustomer = customer.copyWith(
      isActive: !customer.isActive,
    );
    
    final result = await _databaseService.updateCustomer(updatedCustomer);
    return result > 0;
  }

  // Eliminar un cliente
  Future<bool> deleteCustomer(String id) async {
    // Aquí se podría verificar si hay ventas asociadas a este cliente
    // antes de permitir eliminarlo
    
    final result = await _databaseService.deleteCustomer(id);
    return result > 0;
  }

  // Filtrar clientes
  Future<List<Customer>> filterCustomers({
    required String searchQuery,
    required bool showInactive,
  }) async {
    // Primero obtenemos todos los clientes de la base de datos
    List<Customer> customers = await getAllCustomers();
    
    // Luego aplicamos los filtros en memoria
    return customers.where((customer) {
      // Filtrar por estado (activo/inactivo)
      if (!showInactive && !customer.isActive) {
        return false;
      }
      
      // Filtrar por texto de búsqueda (si hay)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final fullName = '${customer.firstName} ${customer.lastName}'.toLowerCase();
        
        return fullName.contains(query) || 
               customer.documentId.toLowerCase().contains(query) ||
               customer.email.toLowerCase().contains(query) ||
               customer.phone.contains(query);
      }
      
      return true;
    }).toList();
  }
} 