import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/sale_item.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/product_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({Key? key}) : super(key: key);

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final SaleService _saleService = SaleService();
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final Uuid _uuid = Uuid();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSearchingCustomer = false;
  bool _isSearchingProducts = false;
  bool _showAddPaymentForm = false;
  
  // Datos de la venta
  Customer? _selectedCustomer;
  List<SaleItem> _selectedItems = [];
  SaleStatus _saleStatus = SaleStatus.completed;
  List<PaymentDetail> _payments = [];
  double _discount = 0.0;
  String? _notes;
  
  // Para cliente no registrado
  bool _isUnregisteredCustomer = false;
  final TextEditingController _unregisteredCustomerNameController = TextEditingController();
  final TextEditingController _unregisteredCustomerPhoneController = TextEditingController();
  
  // Listas de datos
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  
  // Controladores
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
  // Para pagos
  final TextEditingController _paymentAmountController = TextEditingController();
  final TextEditingController _paymentReferenceController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  
  // Formato moneda
  final currencyFormat = NumberFormat.currency(
    locale: 'es_VE',
    symbol: 'Bs. ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _productSearchController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _unregisteredCustomerNameController.dispose();
    _unregisteredCustomerPhoneController.dispose();
    _paymentAmountController.dispose();
    _paymentReferenceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar clientes activos
      final customers = await _customerService.getActiveCustomers();
      
      // Cargar productos
      final products = await _productService.getAllProducts();
      
      setState(() {
        _customers = customers;
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchCustomers(String query) {
    setState(() {
      _isSearchingCustomer = query.isNotEmpty;
      if (query.isEmpty) {
        _loadInitialData();
      }
    });

    if (query.isEmpty) {
      return;
    }

    _customerService.searchCustomers(query).then((customers) {
      if (mounted) {
        setState(() {
          _customers = customers;
        });
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
        _isSearchingProducts = false;
      });
      return;
    }

    setState(() {
      _isSearchingProducts = true;
      _filteredProducts = _products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerSearchController.text = customer.fullName;
      _isSearchingCustomer = false;
      _isUnregisteredCustomer = false;
    });
  }

  void _addProductToSale(Product product) {
    // Verificar si hay suficiente stock
    if (product.currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay stock disponible para este producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el producto ya está en la lista
    final existingItemIndex = _selectedItems.indexWhere(
      (item) => item.productId == product.id
    );

    if (existingItemIndex >= 0) {
      // Si ya existe, incrementar la cantidad
      final existingItem = _selectedItems[existingItemIndex];
      
      // Verificar si hay suficiente stock para incrementar
      if (product.currentStock <= existingItem.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay más stock disponible para este producto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedItems[existingItemIndex] = SaleItem(
          id: existingItem.id,
          saleId: existingItem.saleId,
          productId: existingItem.productId,
          productName: existingItem.productName,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
          subtotal: (existingItem.price * (existingItem.quantity + 1)),
          discount: existingItem.discount,
          notes: existingItem.notes,
        );
      });
    } else {
      // Si no existe, agregar como nuevo item
      final saleId = _uuid.v4(); // ID temporal para la venta
      final newItem = _saleService.createSaleItem(
        saleId: saleId,
        product: product,
        quantity: 1,
      );
      
      setState(() {
        _selectedItems.add(newItem);
      });
    }
    
    // Limpiar búsqueda
    _productSearchController.clear();
    setState(() {
      _filteredProducts = _products;
      _isSearchingProducts = false;
    });
  }

  void _removeProductFromSale(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int newQuantity) {
    final item = _selectedItems[index];
    
    // Obtener el producto para verificar stock disponible
    final product = _products.firstWhere(
      (product) => product.id == item.productId,
      orElse: () => Product(
        id: '',
        name: '',
        description: '',
        price: 0,
        currentStock: 0,
        minimumStock: 0,
        categoryId: '',
        supplierId: '',
        imageUrls: [],
        specifications: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    // Verificar límite inferior
    if (newQuantity <= 0) {
      // Si la cantidad es 0 o menos, eliminar el item
      _removeProductFromSale(index);
      return;
    }
    
    // Verificar stock disponible
    if (product.id.isNotEmpty && newQuantity > product.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo hay ${product.currentStock} unidades disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Actualizar cantidad
    setState(() {
      _selectedItems[index] = SaleItem(
        id: item.id,
        saleId: item.saleId,
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: newQuantity,
        subtotal: (item.price * newQuantity),
        discount: item.discount,
        notes: item.notes,
      );
    });
  }

  double _calculateSubtotal() {
    return _selectedItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  double _calculateTotal() {
    return _calculateSubtotal() - _discount;
  }

  double _calculateTotalPaid() {
    return _payments.fold(0, (sum, payment) => sum + payment.amountInUsd);
  }

  double _calculatePendingAmount() {
    final totalSale = _calculateTotal();
    final totalPaid = _calculateTotalPaid();
    
    // Convertir el totalSale a USD usando el método asíncrono
    double pendingAmount = totalSale - totalPaid;
    return pendingAmount > 0 ? pendingAmount : 0;
  }

  void _addPayment() async {
    if (_paymentAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un monto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final totalPaid = _calculateTotalPaid();
    final totalSale = _calculateTotal();
    
    try {
      final amount = double.parse(_paymentAmountController.text);
      
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto debe ser mayor a cero'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Verificar que el total de pagos no exceda el total de la venta
      if (totalPaid + amount > totalSale) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El total de pagos no puede exceder el total de la venta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Determinar la moneda basada en el método de pago
      final isForeignCurrency = _paymentMethod == PaymentMethod.foreignCash;
      final currency = isForeignCurrency ? PaymentCurrency.usd : PaymentCurrency.bsf;
      
      // Crear nuevo pago
      final newPayment = await _saleService.createPaymentDetail(
        saleId: '',  // Se asignará cuando se cree la venta
        method: _paymentMethod,
        amount: amount,
        currency: currency,
        reference: _paymentReferenceController.text.isEmpty ? null : _paymentReferenceController.text,
      );
      
      setState(() {
        _payments.add(newPayment);
        _paymentAmountController.clear();
        _paymentReferenceController.clear();
        _paymentMethod = PaymentMethod.cash;
        _showAddPaymentForm = false;
        
        // Si la suma de pagos es igual al total, la venta está completada
        // Si es menor, está a crédito
        if (totalPaid + amount >= totalSale) {
          _saleStatus = SaleStatus.completed;
        } else {
          _saleStatus = SaleStatus.credit;
        }
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePayment(int index) {
    setState(() {
      _payments.removeAt(index);
      
      // Recalcular el estado de la venta
      if (_payments.isEmpty) {
        _saleStatus = SaleStatus.completed;
      } else {
        final totalPaid = _calculateTotalPaid();
        final totalSale = _calculateTotal();
        
        if (totalPaid >= totalSale) {
          _saleStatus = SaleStatus.completed;
        } else {
          _saleStatus = SaleStatus.credit;
        }
      }
    });
  }

  void _toggleClientType() {
    setState(() {
      _isUnregisteredCustomer = !_isUnregisteredCustomer;
      if (_isUnregisteredCustomer) {
        _selectedCustomer = null;
        _customerSearchController.clear();
      } else {
        _unregisteredCustomerNameController.clear();
        _unregisteredCustomerPhoneController.clear();
      }
    });
  }

  void _navigateToRegisterCustomer() async {
    final result = await Navigator.pushNamed(context, '/customers/new');
    if (result == true && mounted) {
      _loadInitialData();
    }
  }

  Future<void> _saveSale() async {
    // Validar que haya productos seleccionados
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un producto a la venta'))
      );
      return;
    }

    // Validar que haya al menos un método de pago
    if (_payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un método de pago'))
      );
      return;
    }

    // Obtener datos del cliente (registrado o no registrado)
    String customerId = 'no_registered';
    String? customerName;
    
    if (_isUnregisteredCustomer && _selectedCustomer == null) {
      if (_unregisteredCustomerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el nombre del cliente no registrado'))
        );
        return;
      }
      customerName = _unregisteredCustomerNameController.text.trim();
    } else if (_selectedCustomer != null) {
      customerId = _selectedCustomer!.id;
      customerName = _selectedCustomer!.fullName;
    }

    try {
      // Generar IDs únicos
      final saleId = _saleService.generateSaleId();
      
      // Preparar ítems de venta
      final items = _selectedItems.map((item) {
        return SaleItem(
          id: _saleService.generateSaleItemId(),
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: item.quantity,
          subtotal: item.quantity * item.price,
          discount: 0,
          notes: null,
        );
      }).toList();
      
      // Obtener la tasa de cambio actual
      final dolarRate = await Product.getDolarRate();
      
      // Calcular subtotal y total
      final subtotal = _calculateSubtotal();
      final total = _calculateTotal();
      final totalInUsd = await Sale.convertBsToUsd(total);
      
      // Determinar el monto total pagado
      double totalPaid = 0;
      for (var payment in _payments) {
        if (payment.currency == PaymentCurrency.usd) {
          totalPaid += payment.amountInUsd;
        } else {
          totalPaid += payment.amountInUsd;
        }
      }
      
      // Determinar el monto pendiente (para ventas a crédito)
      final pendingAmount = totalInUsd - totalPaid;
      
      // Determinar el estado de la venta
      SaleStatus saleStatus;
      if (pendingAmount <= 0) {
        saleStatus = SaleStatus.completed;
      } else {
        saleStatus = SaleStatus.credit;
      }
      
      // Crear el objeto de venta
      final sale = Sale(
        id: saleId,
        customerId: customerId,
        customerName: customerName,
        date: DateTime.now(),
        items: items,
        subtotal: subtotal,
        discount: _discountController.text.isNotEmpty ? double.parse(_discountController.text) : 0,
        total: total,
        totalInUsd: totalInUsd,
        exchangeRate: dolarRate,
        payments: _payments,
        status: saleStatus,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        reference: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paidAmount: totalPaid,
        pendingAmount: pendingAmount,
      );
      
      // Guardar la venta
      final success = await _saleService.createSale(sale, items);
      
      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada correctamente'))
        );
        
        // Limpiar formulario o volver a la pantalla anterior
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar la venta'))
        );
      }
    } catch (e) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : GestureDetector(
              onTap: () {
                // Cerrar el teclado al tocar fuera de los campos
                FocusScope.of(context).unfocus();
                setState(() {
                  _isSearchingCustomer = false;
                  _isSearchingProducts = false;
                });
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Sección principal (formulario y productos)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selección de cliente
                            _buildCustomerSelection(),
                            const SizedBox(height: 24),
                            
                            // Selección de productos
                            _buildProductSelection(),
                            const SizedBox(height: 24),
                            
                            // Lista de productos seleccionados
                            _buildSelectedProductsList(),
                            const SizedBox(height: 24),
                            
                            // Sección de pagos
                            _buildPaymentsSection(),
                            const SizedBox(height: 24),
                            
                            // Formulario adicional (notas, descuento)
                            _buildAdditionalForm(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Sección inferior (resumen y botón de guardar)
                    _buildSummaryFooter(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _toggleClientType,
                  icon: Icon(
                    _isUnregisteredCustomer ? Icons.person_off : Icons.person_add,
                    size: 18,
                  ),
                  label: Text(
                    _isUnregisteredCustomer ? 'Cliente registrado' : 'Cliente no registrado',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!_isUnregisteredCustomer)
                  TextButton.icon(
                    onPressed: _navigateToRegisterCustomer,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Nuevo', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Cliente no registrado
        if (_isUnregisteredCustomer)
          Column(
            children: [
              TextFormField(
                controller: _unregisteredCustomerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (_isUnregisteredCustomer && (value == null || value.isEmpty)) {
                    return 'Ingrese el nombre del cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _unregisteredCustomerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          )
        else
          // Campo de búsqueda de clientes
          Column(
            children: [
              TextFormField(
                controller: _customerSearchController,
                decoration: InputDecoration(
                  hintText: 'Buscar cliente',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _customerSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _customerSearchController.clear();
                            setState(() {
                              _isSearchingCustomer = false;
                              _selectedCustomer = null;
                            });
                            _loadInitialData();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _searchCustomers,
                onTap: () {
                  setState(() {
                    _isSearchingCustomer = true;
                  });
                },
                validator: (value) {
                  if (!_isUnregisteredCustomer && _selectedCustomer == null) {
                    return 'Debe seleccionar un cliente';
                  }
                  return null;
                },
              ),
              
              // Lista de resultados de búsqueda
              if (_isSearchingCustomer)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                  ),
                  child: _customers.isEmpty
                      ? const ListTile(
                          title: Text('No se encontraron clientes'),
                          leading: Icon(Icons.search_off),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            return ListTile(
                              title: Text(customer.fullName),
                              subtitle: Text(customer.phone),
                              leading: const Icon(Icons.person_outline),
                              onTap: () => _selectCustomer(customer),
                            );
                          },
                        ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Campo de búsqueda de productos
        TextFormField(
          controller: _productSearchController,
          decoration: InputDecoration(
            hintText: 'Buscar productos',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _productSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _productSearchController.clear();
                      setState(() {
                        _filteredProducts = _products;
                        _isSearchingProducts = false;
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: _searchProducts,
          onTap: () {
            setState(() {
              _isSearchingProducts = true;
            });
          },
        ),
        
        // Lista de resultados de búsqueda
        if (_isSearchingProducts)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            child: _filteredProducts.isEmpty
                ? const ListTile(
                    title: Text('No se encontraron productos'),
                    leading: Icon(Icons.search_off),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Row(
                          children: [
                            Text(currencyFormat.format(product.price)),
                            const SizedBox(width: 8),
                            Text(
                              'Stock: ${product.currentStock}',
                              style: TextStyle(
                                color: product.isLowStock
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        leading: product.imageUrls.isNotEmpty
                            ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: product.imageUrls.first.startsWith('http')
                                      ? NetworkImage(product.imageUrls.first) as ImageProvider
                                      : FileImage(File(product.imageUrls.first)),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                            : const Icon(Icons.inventory_2_outlined),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: product.currentStock > 0
                              ? () => _addProductToSale(product)
                              : null,
                          color: product.currentStock > 0
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildSelectedProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Productos seleccionados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedItems.isNotEmpty)
              Text(
                '${_selectedItems.length} ${_selectedItems.length == 1 ? 'artículo' : 'artículos'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        _selectedItems.isEmpty
            ? Card(
                elevation: 0,
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_shopping_cart,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No hay productos seleccionados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Busca y selecciona productos para añadirlos a la venta',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Card(
                elevation: 0,
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Encabezado de la lista
                      const Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text('Producto'),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Cant.', textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Precio', textAlign: TextAlign.end),
                          ),
                          SizedBox(width: 16), // Espacio para botones
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Lista de productos
                      ...List.generate(_selectedItems.length, (index) {
                        final item = _selectedItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // Nombre del producto
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // Cantidad con botones para ajustar
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                                      onPressed: () => _updateItemQuantity(index, item.quantity - 1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        item.quantity.toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 18),
                                      onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Precio y subtotal
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(item.price),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      currencyFormat.format(item.subtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Botón para eliminar
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _removeProductFromSale(index),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPaymentsSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pagos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddPaymentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Pago'),
                ),
              ],
            ),
            const Divider(),
            
            // Lista de pagos
            if (_payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No hay pagos registrados',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final payment = _payments[index];
                  final currencySymbol = payment.currency == PaymentCurrency.usd ? '\$' : 'Bs';
                  
                  return ListTile(
                    leading: Icon(_getPaymentMethodIcon(payment.method)),
                    title: Text('${payment.method.toString().split('.').last} - $currencySymbol${payment.amount.toStringAsFixed(2)}'),
                    subtitle: payment.reference != null
                        ? Text('Ref: ${payment.reference}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removePayment(index),
                    ),
                  );
                },
              ),
            
            const Divider(),
            
            // Resumen de pagos
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pagado (USD):'),
                      Text('\$${_calculateTotalPaid().toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo Pendiente (USD):'),
                      Text('\$${_calculatePendingAmount().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _calculatePendingAmount() > 0 ? Colors.red : Colors.green,
                        )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles adicionales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Card(
          elevation: 0,
          color: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Descuento
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    labelText: 'Descuento',
                    prefixIcon: Icon(Icons.discount),
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    try {
                      if (value.isEmpty) {
                        setState(() {
                          _discount = 0.0;
                        });
                      } else {
                        setState(() {
                          _discount = double.parse(value);
                        });
                      }
                    } catch (e) {
                      // Si hay error de formato, no cambiar el valor
                    }
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        final discount = double.parse(value);
                        if (discount < 0) {
                          return 'El descuento no puede ser negativo';
                        }
                        if (discount > _calculateSubtotal()) {
                          return 'El descuento no puede ser mayor al subtotal';
                        }
                      } catch (e) {
                        return 'Ingrese un número válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Notas adicionales
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Notas adicionales (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _notes = value.isNotEmpty ? value : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumen de totales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(currencyFormat.format(_calculateSubtotal())),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Descuento'),
                Text(
                  '- ${currencyFormat.format(_discount)}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(_calculateTotal()),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botón para guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedItems.isEmpty ? null : _saveSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Registrar Venta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para abrir el diálogo de agregar pago
  void _showAddPaymentDialog() {
    PaymentMethod _selectedMethod = PaymentMethod.cash;
    PaymentCurrency _selectedCurrency = PaymentCurrency.usd;
    final _amountController = TextEditingController();
    final _referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Pago'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Método de pago
              DropdownButtonFormField<PaymentMethod>(
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                value: _selectedMethod,
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem<PaymentMethod>(
                    value: method,
                    child: Text(method.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _selectedMethod = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Moneda
              DropdownButtonFormField<PaymentCurrency>(
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCurrency,
                items: PaymentCurrency.values.map((currency) {
                  return DropdownMenuItem<PaymentCurrency>(
                    value: currency,
                    child: Text(currency == PaymentCurrency.usd ? 'Dólares (\$)' : 'Bolívares (Bs)'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _selectedCurrency = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Monto
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Referencia (para transferencia, etc.)
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validar que haya un monto
              if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingrese un monto válido')),
                );
                return;
              }
              
              final amount = double.parse(_amountController.text);
              
              // Obtener tasa de cambio y calcular monto en USD
              double exchangeRate = 1.0;
              double amountInUsd = amount;
              
              if (_selectedCurrency == PaymentCurrency.bsf) {
                final dolarRate = await Product.getDolarRate();
                exchangeRate = dolarRate;
                amountInUsd = amount / dolarRate;
              }
              
              // Generar ID único para el pago
              final paymentId = _saleService.generatePaymentId();
              
              // Crear objeto de pago
              final payment = PaymentDetail(
                id: paymentId,
                method: _selectedMethod,
                amount: amount,
                currency: _selectedCurrency,
                exchangeRate: exchangeRate,
                amountInUsd: amountInUsd,
                reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
                date: DateTime.now(),
              );
              
              // Agregar el pago a la lista
              setState(() {
                _payments.add(payment);
              });
              
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Obtener icono para método de pago
  IconData _getPaymentMethodIcon(PaymentMethod method) {
    return Sale.getPaymentMethodIcon(method);
  }
} 