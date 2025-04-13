import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/product_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'customer_selector_dialog.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saleService = SaleService();
  final _productService = ProductService();
  final _customerService = CustomerService();
  final _uuid = Uuid();
  
  // Controladores para los campos
  final _searchProductController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Datos de la venta
  Customer? _selectedCustomer;
  List<SaleItem> _cartItems = [];
  List<Payment> _payments = [];
  SaleStatus _saleStatus = SaleStatus.completed;
  
  // Productos disponibles y resultados de búsqueda
  List<Product> _availableProducts = [];
  List<Product> _searchResults = [];
  
  // Estado de carga y error
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  
  // Para pagos
  double _cashUsdAmount = 0;
  double _cashBsAmount = 0;
  double _bankTransferAmount = 0;
  String _bankTransferReference = '';
  double _mobilePaymentAmount = 0;
  String _mobilePaymentReference = '';
  double _creditAmount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  @override
  void dispose() {
    _searchProductController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final products = await _productService.getAllProducts();
      
      if (mounted) {
        setState(() {
          _availableProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar productos: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Filtrar productos en base a la búsqueda
  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = _availableProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
               product.description.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }
  
  // Añadir producto al carrito
  void _addProductToCart(Product product, int quantity) {
    // Verificar si hay stock suficiente
    if (quantity <= 0 || quantity > product.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cantidad inválida o stock insuficiente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Verificar si el producto ya está en el carrito
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id
    );
    
    setState(() {
      if (existingIndex >= 0) {
        // Actualizar cantidad si ya existe
        final existingItem = _cartItems[existingIndex];
        final newQuantity = existingItem.quantity + quantity;
        
        // Verificar que la nueva cantidad no exceda el stock
        if (newQuantity > product.currentStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La cantidad total excede el stock disponible'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Actualizar item
        _cartItems[existingIndex] = SaleItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          priceInBs: product.priceInBs,
          quantity: newQuantity,
          subtotal: product.price * newQuantity,
          subtotalInBs: product.priceInBs * newQuantity,
        );
      } else {
        // Añadir nuevo item
        _cartItems.add(SaleItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          priceInBs: product.priceInBs,
          quantity: quantity,
          subtotal: product.price * quantity,
          subtotalInBs: product.priceInBs * quantity,
        ));
      }
      
      // Limpiar búsqueda
      _searchProductController.clear();
      _searchResults = [];
    });
  }
  
  // Remover item del carrito
  void _removeCartItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }
  
  // Calcular total de la venta
  double get _cartTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }
  
  // Calcular total en bolívares
  double get _cartTotalInBs {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotalInBs);
  }
  
  // Mostrar diálogo para seleccionar cliente
  Future<void> _selectCustomer() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (context) => const CustomerSelectorDialog(),
    );
    
    if (customer != null) {
      setState(() {
        _selectedCustomer = customer;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        actions: [
          if (_cartItems.isNotEmpty && _selectedCustomer != null)
            TextButton.icon(
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text(
                'Procesar Pago',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Panel superior con búsqueda de productos
                        _buildProductSearchPanel(),
                        
                        // Panel de cliente seleccionado
                        _buildCustomerPanel(),
                        
                        // Lista de productos en el carrito
                        _buildCartItemsList(),
                        
                        // Panel inferior con total
                        _buildCartSummary(),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  // Panel de búsqueda de productos
  Widget _buildProductSearchPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buscar Productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchProductController,
            decoration: const InputDecoration(
              hintText: 'Nombre o descripción del producto',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _searchProducts,
          ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)} - Stock: ${product.currentStock}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => _showQuantityDialog(product),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  // Panel de selección de cliente
  Widget _buildCustomerPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _selectedCustomer != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cliente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _selectedCustomer!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _selectedCustomer!.documentId,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  )
                : const Text(
                    'No se ha seleccionado un cliente',
                    style: TextStyle(color: Colors.grey),
                  ),
          ),
          OutlinedButton.icon(
            onPressed: _selectCustomer,
            icon: const Icon(Icons.person),
            label: Text(_selectedCustomer == null ? 'Seleccionar' : 'Cambiar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // Lista de productos en el carrito
  Widget _buildCartItemsList() {
    if (_cartItems.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No hay productos en el carrito',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(item.productName),
              subtitle: Text('Cantidad: ${item.quantity} x \$${item.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeCartItem(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Panel de resumen del carrito
  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardBackground,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '\$${_cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'Bs. ${_cartTotalInBs.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _selectedCustomer == null
                ? _selectCustomer
                : _cartItems.isEmpty
                    ? null
                    : _showPaymentDialog,
            icon: Icon(_selectedCustomer == null ? Icons.person : Icons.payment),
            label: Text(_selectedCustomer == null ? 'Seleccionar Cliente' : 'Procesar Pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  // Diálogo para seleccionar cantidad
  void _showQuantityDialog(Product product) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir ${product.name}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock disponible: ${product.currentStock}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: quantity < product.currentStock
                        ? () => setState(() => quantity++)
                        : null,
                  ),
                ],
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
            onPressed: () {
              Navigator.pop(context);
              _addProductToCart(product, quantity);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
  
  // Método para mostrar el diálogo de pago
  void _showPaymentDialog() {
    // Resetear los montos
    _cashUsdAmount = 0;
    _cashBsAmount = 0;
    _bankTransferAmount = 0;
    _bankTransferReference = '';
    _mobilePaymentAmount = 0;
    _mobilePaymentReference = '';
    _creditAmount = 0;
    
    final double total = _cartTotal;
    double totalPaid = 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Actualizar total pagado
          totalPaid = _cashUsdAmount + _cashBsAmount / Product.exchangeRate + 
                      _bankTransferAmount + _mobilePaymentAmount;
          
          // Calcular saldo pendiente
          final double pending = total - totalPaid;
          final bool hasPending = pending > 0;
          
          return AlertDialog(
            title: const Text('Procesar Pago'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de la venta
                    Card(
                      color: AppTheme.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total a pagar:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total pagado:'),
                                Text(
                                  '\$${totalPaid.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: totalPaid > 0 ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (hasPending) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Saldo pendiente:'),
                                  Text(
                                    '\$${pending.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (totalPaid > total) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Cambio:'),
                                  Text(
                                    '\$${(totalPaid - total).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Métodos de pago
                    const Text(
                      'Métodos de Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Pago en efectivo USD
                    ExpansionTile(
                      title: const Text('Efectivo (USD)'),
                      leading: const Icon(Icons.attach_money),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Monto en USD',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _cashUsdAmount = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _cashUsdAmount = total - (totalPaid - _cashUsdAmount);
                                    if (_cashUsdAmount < 0) _cashUsdAmount = 0;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Todo'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Pago en efectivo Bs
                    ExpansionTile(
                      title: const Text('Efectivo (Bs)'),
                      leading: const Icon(Icons.money),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tasa de cambio: 1 USD = ${Product.exchangeRate} Bs',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Monto en Bs',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          _cashBsAmount = double.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        // Convertir el pendiente a Bs
                                        final pendingBs = (total - (totalPaid - _cashBsAmount / Product.exchangeRate)) * Product.exchangeRate;
                                        _cashBsAmount = pendingBs > 0 ? pendingBs : 0;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Todo'),
                                  ),
                                ],
                              ),
                              if (_cashBsAmount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Equivalente: \$${(_cashBsAmount / Product.exchangeRate).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Transferencia bancaria
                    ExpansionTile(
                      title: const Text('Transferencia Bancaria'),
                      leading: const Icon(Icons.account_balance),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Monto',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _bankTransferAmount = double.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Número de referencia',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _bankTransferReference = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        final pendingAmount = total - (totalPaid - _bankTransferAmount);
                                        _bankTransferAmount = pendingAmount > 0 ? pendingAmount : 0;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Todo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Pago móvil
                    ExpansionTile(
                      title: const Text('Pago Móvil'),
                      leading: const Icon(Icons.phone_android),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Monto',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _mobilePaymentAmount = double.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Número de referencia',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _mobilePaymentReference = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        final pendingAmount = total - (totalPaid - _mobilePaymentAmount);
                                        _mobilePaymentAmount = pendingAmount > 0 ? pendingAmount : 0;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Todo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Crédito (si hay saldo pendiente)
                    if (hasPending)
                      ExpansionTile(
                        title: const Text('A Crédito'),
                        leading: const Icon(Icons.credit_card),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo pendiente: \$${pending.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _creditAmount = pending;
                                    });
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Registrar a Crédito'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                if (_creditAmount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'A crédito: \$${_creditAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                    // Notas
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: totalPaid >= total || _creditAmount > 0 
                    ? () {
                        Navigator.of(context).pop();
                        _processSale(totalPaid);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Completar Venta'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Procesar la venta
  Future<void> _processSale(double totalPaid) async {
    if (_selectedCustomer == null || _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un cliente y agregar productos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final double total = _cartTotal;
      
      // Crear lista de pagos
      final List<Payment> payments = [];
      final now = DateTime.now();
      
      // Efectivo USD
      if (_cashUsdAmount > 0) {
        payments.add(Payment(
          id: _uuid.v4(),
          method: PaymentMethod.cashUSD,
          amount: _cashUsdAmount,
          date: now,
        ));
      }
      
      // Efectivo Bs
      if (_cashBsAmount > 0) {
        payments.add(Payment(
          id: _uuid.v4(),
          method: PaymentMethod.cashBs,
          amount: _cashBsAmount / Product.exchangeRate, // Convertir a USD
          date: now,
        ));
      }
      
      // Transferencia bancaria
      if (_bankTransferAmount > 0) {
        payments.add(Payment(
          id: _uuid.v4(),
          method: PaymentMethod.bankTransfer,
          amount: _bankTransferAmount,
          referenceNumber: _bankTransferReference,
          date: now,
        ));
      }
      
      // Pago móvil
      if (_mobilePaymentAmount > 0) {
        payments.add(Payment(
          id: _uuid.v4(),
          method: PaymentMethod.mobilePayment,
          amount: _mobilePaymentAmount,
          referenceNumber: _mobilePaymentReference,
          date: now,
        ));
      }
      
      // Crédito
      if (_creditAmount > 0) {
        payments.add(Payment(
          id: _uuid.v4(),
          method: PaymentMethod.debt,
          amount: _creditAmount,
          date: now,
        ));
      }
      
      // Determinar estado de la venta
      final SaleStatus status = _creditAmount > 0 ? SaleStatus.credit : SaleStatus.completed;
      
      // Crear la venta
      final String saleId = await _saleService.createSale(
        customerId: _selectedCustomer!.id,
        items: _cartItems,
        payments: payments,
        total: total,
        totalPaid: totalPaid,
        status: status,
        notes: _notesController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta registrada exitosamente. ID: $saleId'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        setState(() {
          _selectedCustomer = null;
          _cartItems = [];
          _payments = [];
          _notesController.clear();
          _isProcessing = false;
        });
        
        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 