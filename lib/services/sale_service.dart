import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/services/database_service.dart';
import 'package:uuid/uuid.dart';

class SaleService {
  final _databaseService = DatabaseService();
  final _uuid = Uuid();

  // Obtener todas las ventas
  Future<List<Sale>> getAllSales() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query('sales');
    
    if (saleMaps.isEmpty) {
      return [];
    }

    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final String saleId = saleMap['id'];
      
      // Obtener items de la venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        priceInBs: itemMap['price_in_bs'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        subtotalInBs: itemMap['subtotal_in_bs'],
      )).toList();
      
      // Obtener pagos de la venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<Payment> payments = paymentMaps.map((paymentMap) => Payment(
        id: paymentMap['id'],
        method: PaymentMethod.values.byName(paymentMap['method']),
        amount: paymentMap['amount'],
        referenceNumber: paymentMap['reference_number'],
        date: DateTime.parse(paymentMap['date']),
      )).toList();

      // Crear objeto Sale
      sales.add(Sale(
        id: saleId,
        customerId: saleMap['customer_id'],
        items: items,
        payments: payments,
        total: saleMap['total'],
        totalPaid: saleMap['total_paid'],
        status: SaleStatus.values.byName(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
      ));
    }

    return sales;
  }
  
  // Obtener ventas por cliente
  Future<List<Sale>> getSalesByCustomer(String customerId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    
    if (saleMaps.isEmpty) {
      return [];
    }

    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final String saleId = saleMap['id'];
      
      // Obtener items de la venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        priceInBs: itemMap['price_in_bs'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        subtotalInBs: itemMap['subtotal_in_bs'],
      )).toList();
      
      // Obtener pagos de la venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<Payment> payments = paymentMaps.map((paymentMap) => Payment(
        id: paymentMap['id'],
        method: PaymentMethod.values.byName(paymentMap['method']),
        amount: paymentMap['amount'],
        referenceNumber: paymentMap['reference_number'],
        date: DateTime.parse(paymentMap['date']),
      )).toList();

      // Crear objeto Sale
      sales.add(Sale(
        id: saleId,
        customerId: saleMap['customer_id'],
        items: items,
        payments: payments,
        total: saleMap['total'],
        totalPaid: saleMap['total_paid'],
        status: SaleStatus.values.byName(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
      ));
    }

    return sales;
  }

  // Obtener venta por ID
  Future<Sale?> getSaleById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (saleMaps.isEmpty) {
      return null;
    }

    final saleMap = saleMaps.first;
    
    // Obtener items de la venta
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    
    List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
      productId: itemMap['product_id'],
      productName: itemMap['product_name'],
      price: itemMap['price'],
      priceInBs: itemMap['price_in_bs'],
      quantity: itemMap['quantity'],
      subtotal: itemMap['subtotal'],
      subtotalInBs: itemMap['subtotal_in_bs'],
    )).toList();
    
    // Obtener pagos de la venta
    final List<Map<String, dynamic>> paymentMaps = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    
    List<Payment> payments = paymentMaps.map((paymentMap) => Payment(
      id: paymentMap['id'],
      method: PaymentMethod.values.byName(paymentMap['method']),
      amount: paymentMap['amount'],
      referenceNumber: paymentMap['reference_number'],
      date: DateTime.parse(paymentMap['date']),
    )).toList();

    // Crear objeto Sale
    return Sale(
      id: id,
      customerId: saleMap['customer_id'],
      items: items,
      payments: payments,
      total: saleMap['total'],
      totalPaid: saleMap['total_paid'],
      status: SaleStatus.values.byName(saleMap['status']),
      notes: saleMap['notes'],
      createdAt: DateTime.parse(saleMap['created_at']),
      updatedAt: DateTime.parse(saleMap['updated_at']),
    );
  }

  // Crear una nueva venta
  Future<String> createSale({
    required String customerId,
    required List<SaleItem> items,
    required List<Payment> payments,
    required double total,
    required double totalPaid,
    required SaleStatus status,
    required String notes,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final id = _uuid.v4();
    
    // Iniciar una transacción
    return await db.transaction((txn) async {
      // Insertar la venta
      await txn.insert(
        'sales',
        {
          'id': id,
          'customer_id': customerId,
          'total': total,
          'total_paid': totalPaid,
          'status': status.name,
          'notes': notes,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      );

      // Insertar los items de la venta
      for (var item in items) {
        await txn.insert(
          'sale_items',
          {
            'sale_id': id,
            'product_id': item.productId,
            'product_name': item.productName,
            'price': item.price,
            'price_in_bs': item.priceInBs,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
            'subtotal_in_bs': item.subtotalInBs,
          },
        );
        
        // Actualizar el stock del producto
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ?, updated_at = ? WHERE id = ?',
          [item.quantity, now.toIso8601String(), item.productId],
        );
      }

      // Insertar los pagos
      for (var payment in payments) {
        await txn.insert(
          'payments',
          {
            'id': payment.id,
            'sale_id': id,
            'method': payment.method.name,
            'amount': payment.amount,
            'reference_number': payment.referenceNumber,
            'date': payment.date.toIso8601String(),
          },
        );
      }

      // Si es una venta a crédito, crear la deuda
      if (status == SaleStatus.credit) {
        final debtId = _uuid.v4();
        final dueDate = now.add(const Duration(days: 30)); // Vencimiento a 30 días por defecto
        
        await txn.insert(
          'debts',
          {
            'id': debtId,
            'sale_id': id,
            'customer_id': customerId,
            'total_amount': total,
            'paid_amount': totalPaid,
            'is_paid': 0, // No pagada
            'due_date': dueDate.toIso8601String(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        );
        
        // Asociar los pagos iniciales a la deuda si hay
        for (var payment in payments) {
          if (payment.method != PaymentMethod.debt) {
            await txn.insert(
              'debt_payments',
              {
                'debt_id': debtId,
                'payment_id': payment.id,
              },
            );
          }
        }
      }

      return id;
    });
  }

  // Obtener todas las deudas
  Future<List<Debt>> getAllDebts() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> debtMaps = await db.query('debts');
    
    if (debtMaps.isEmpty) {
      return [];
    }

    List<Debt> debts = [];
    for (var debtMap in debtMaps) {
      final String debtId = debtMap['id'];
      
      // Obtener los IDs de pago asociados a esta deuda
      final List<Map<String, dynamic>> debtPaymentMaps = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );
      
      List<String> paymentIds = debtPaymentMaps.map((map) => map['payment_id'] as String).toList();
      
      // Obtener los pagos basados en los IDs
      List<Payment> payments = [];
      for (var paymentId in paymentIds) {
        final List<Map<String, dynamic>> paymentMaps = await db.query(
          'payments',
          where: 'id = ?',
          whereArgs: [paymentId],
        );
        
        if (paymentMaps.isNotEmpty) {
          payments.add(Payment(
            id: paymentMaps.first['id'],
            method: PaymentMethod.values.byName(paymentMaps.first['method']),
            amount: paymentMaps.first['amount'],
            referenceNumber: paymentMaps.first['reference_number'],
            date: DateTime.parse(paymentMaps.first['date']),
          ));
        }
      }

      // Crear objeto Debt
      debts.add(Debt(
        id: debtId,
        saleId: debtMap['sale_id'],
        customerId: debtMap['customer_id'],
        totalAmount: debtMap['total_amount'],
        paidAmount: debtMap['paid_amount'],
        payments: payments,
        isPaid: debtMap['is_paid'] == 1,
        dueDate: DateTime.parse(debtMap['due_date']),
        createdAt: DateTime.parse(debtMap['created_at']),
        updatedAt: DateTime.parse(debtMap['updated_at']),
      ));
    }

    return debts;
  }

  // Obtener deudas por cliente
  Future<List<Debt>> getDebtsByCustomer(String customerId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> debtMaps = await db.query(
      'debts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    
    if (debtMaps.isEmpty) {
      return [];
    }

    List<Debt> debts = [];
    for (var debtMap in debtMaps) {
      final String debtId = debtMap['id'];
      
      // Obtener los IDs de pago asociados a esta deuda
      final List<Map<String, dynamic>> debtPaymentMaps = await db.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );
      
      List<String> paymentIds = debtPaymentMaps.map((map) => map['payment_id'] as String).toList();
      
      // Obtener los pagos basados en los IDs
      List<Payment> payments = [];
      for (var paymentId in paymentIds) {
        final List<Map<String, dynamic>> paymentMaps = await db.query(
          'payments',
          where: 'id = ?',
          whereArgs: [paymentId],
        );
        
        if (paymentMaps.isNotEmpty) {
          payments.add(Payment(
            id: paymentMaps.first['id'],
            method: PaymentMethod.values.byName(paymentMaps.first['method']),
            amount: paymentMaps.first['amount'],
            referenceNumber: paymentMaps.first['reference_number'],
            date: DateTime.parse(paymentMaps.first['date']),
          ));
        }
      }

      // Crear objeto Debt
      debts.add(Debt(
        id: debtId,
        saleId: debtMap['sale_id'],
        customerId: debtMap['customer_id'],
        totalAmount: debtMap['total_amount'],
        paidAmount: debtMap['paid_amount'],
        payments: payments,
        isPaid: debtMap['is_paid'] == 1,
        dueDate: DateTime.parse(debtMap['due_date']),
        createdAt: DateTime.parse(debtMap['created_at']),
        updatedAt: DateTime.parse(debtMap['updated_at']),
      ));
    }

    return debts;
  }

  // Registrar un pago para una deuda
  Future<bool> registerDebtPayment({
    required String debtId,
    required PaymentMethod method,
    required double amount,
    String? referenceNumber,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    
    // Obtener la deuda
    final List<Map<String, dynamic>> debtMaps = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    
    if (debtMaps.isEmpty) {
      return false;
    }
    
    final debtMap = debtMaps.first;
    final String saleId = debtMap['sale_id'];
    final double totalAmount = debtMap['total_amount'];
    final double currentPaidAmount = debtMap['paid_amount'];
    
    // Verificar que el monto a pagar no exceda la deuda pendiente
    if (currentPaidAmount + amount > totalAmount) {
      return false;
    }
    
    // Crear un nuevo pago
    final paymentId = _uuid.v4();
    
    // Iniciar una transacción
    return await db.transaction((txn) async {
      // Insertar el nuevo pago
      await txn.insert(
        'payments',
        {
          'id': paymentId,
          'sale_id': saleId,
          'method': method.name,
          'amount': amount,
          'reference_number': referenceNumber,
          'date': now.toIso8601String(),
        },
      );
      
      // Asociar el pago a la deuda
      await txn.insert(
        'debt_payments',
        {
          'debt_id': debtId,
          'payment_id': paymentId,
        },
      );
      
      // Actualizar el monto pagado de la deuda
      final newPaidAmount = currentPaidAmount + amount;
      final isPaid = newPaidAmount >= totalAmount ? 1 : 0;
      
      await txn.update(
        'debts',
        {
          'paid_amount': newPaidAmount,
          'is_paid': isPaid,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );
      
      // Actualizar el total pagado de la venta
      await txn.rawUpdate(
        'UPDATE sales SET total_paid = total_paid + ?, updated_at = ? WHERE id = ?',
        [amount, now.toIso8601String(), saleId],
      );
      
      // Si la deuda está completamente pagada, actualizar el estado de la venta
      if (isPaid == 1) {
        await txn.update(
          'sales',
          {
            'status': SaleStatus.completed.name,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [saleId],
        );
      }
      
      return true;
    });
  }
  
  // Obtener ventas del día actual
  Future<List<Sale>> getSalesOfDay() async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final tomorrow = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [today, tomorrow],
    );
    
    if (saleMaps.isEmpty) {
      return [];
    }
    
    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final String saleId = saleMap['id'];
      
      // Obtener items de la venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        priceInBs: itemMap['price_in_bs'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        subtotalInBs: itemMap['subtotal_in_bs'],
      )).toList();
      
      // Obtener pagos de la venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<Payment> payments = paymentMaps.map((paymentMap) => Payment(
        id: paymentMap['id'],
        method: PaymentMethod.values.byName(paymentMap['method']),
        amount: paymentMap['amount'],
        referenceNumber: paymentMap['reference_number'],
        date: DateTime.parse(paymentMap['date']),
      )).toList();

      // Crear objeto Sale
      sales.add(Sale(
        id: saleId,
        customerId: saleMap['customer_id'],
        items: items,
        payments: payments,
        total: saleMap['total'],
        totalPaid: saleMap['total_paid'],
        status: SaleStatus.values.byName(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
      ));
    }
    
    return sales;
  }
  
  // Obtener ventas del mes actual
  Future<List<Sale>> getSalesOfMonth() async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();
    
    final List<Map<String, dynamic>> saleMaps = await db.query(
      'sales',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [firstDayOfMonth, firstDayOfNextMonth],
    );
    
    if (saleMaps.isEmpty) {
      return [];
    }
    
    List<Sale> sales = [];
    for (var saleMap in saleMaps) {
      final String saleId = saleMap['id'];
      
      // Obtener items de la venta
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<SaleItem> items = itemMaps.map((itemMap) => SaleItem(
        productId: itemMap['product_id'],
        productName: itemMap['product_name'],
        price: itemMap['price'],
        priceInBs: itemMap['price_in_bs'],
        quantity: itemMap['quantity'],
        subtotal: itemMap['subtotal'],
        subtotalInBs: itemMap['subtotal_in_bs'],
      )).toList();
      
      // Obtener pagos de la venta
      final List<Map<String, dynamic>> paymentMaps = await db.query(
        'payments',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      
      List<Payment> payments = paymentMaps.map((paymentMap) => Payment(
        id: paymentMap['id'],
        method: PaymentMethod.values.byName(paymentMap['method']),
        amount: paymentMap['amount'],
        referenceNumber: paymentMap['reference_number'],
        date: DateTime.parse(paymentMap['date']),
      )).toList();

      // Crear objeto Sale
      sales.add(Sale(
        id: saleId,
        customerId: saleMap['customer_id'],
        items: items,
        payments: payments,
        total: saleMap['total'],
        totalPaid: saleMap['total_paid'],
        status: SaleStatus.values.byName(saleMap['status']),
        notes: saleMap['notes'],
        createdAt: DateTime.parse(saleMap['created_at']),
        updatedAt: DateTime.parse(saleMap['updated_at']),
      ));
    }
    
    return sales;
  }
} 