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
  
  // Datos de la venta
  Customer? _selectedCustomer;
  List<SaleItem> _selectedItems = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _taxRate = 16.0; // IVA por defecto (16%)
  double _discount = 0.0;
  String? _reference;
  String? _notes;
  
  // Listas de datos
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  
  // Controladores
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
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
    _referenceController.dispose();
    _notesController.dispose();
    _discountController.dispose();
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

  double _calculateTax() {
    return _calculateSubtotal() * (_taxRate / 100);
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax() - _discount;
  }

  Future<void> _saveSale() async {
    // Validar que haya cliente seleccionado
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que haya productos en la venta
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generar ID para la venta
      final saleId = _saleService.generateSaleId();
      
      // Actualizar IDs de los items con el ID real de la venta
      final updatedItems = _selectedItems.map((item) => SaleItem(
        id: _saleService.generateSaleItemId(),
        saleId: saleId,
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        subtotal: item.subtotal,
        discount: item.discount,
        notes: item.notes,
      )).toList();
      
      // Crear objeto de venta
      final newSale = Sale(
        id: saleId,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.fullName,
        date: DateTime.now(),
        items: updatedItems,
        subtotal: _calculateSubtotal(),
        tax: _calculateTax(),
        discount: _discount,
        total: _calculateTotal(),
        paymentMethod: _paymentMethod,
        status: SaleStatus.completed, // Por defecto completada
        reference: _reference,
        notes: _notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Guardar la venta
      final success = await _saleService.createSale(newSale, updatedItems);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Volver a la pantalla anterior con resultado exitoso
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar la venta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                            
                            // Formulario adicional (método de pago, referencia, etc.)
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
        const Text(
          'Cliente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Campo de búsqueda de clientes
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
          ),
          onChanged: _searchCustomers,
          onTap: () {
            setState(() {
              _isSearchingCustomer = true;
            });
          },
          validator: (value) {
            if (_selectedCustomer == null) {
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
                                    image: FileImage(File(product.imageUrls.first)),
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
                // Método de pago
                DropdownButtonFormField<PaymentMethod>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem<PaymentMethod>(
                      value: method,
                      child: Row(
                        children: [
                          Icon(Sale.getPaymentMethodIcon(method), size: 18),
                          const SizedBox(width: 8),
                          Text(Sale.paymentMethodToString(method)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _paymentMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Referencia (opcional, solo para transferencias, etc.)
                if (_paymentMethod != PaymentMethod.cash)
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Referencia',
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'Número de referencia (opcional)',
                    ),
                    onChanged: (value) {
                      _reference = value.isNotEmpty ? value : null;
                    },
                  ),
                
                if (_paymentMethod != PaymentMethod.cash)
                  const SizedBox(height: 16),
                
                // Descuento
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    labelText: 'Descuento',
                    prefixIcon: Icon(Icons.discount),
                    hintText: '0.00',
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
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IVA (${_taxRate.toStringAsFixed(0)}%)'),
              Text(currencyFormat.format(_calculateTax())),
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
} 