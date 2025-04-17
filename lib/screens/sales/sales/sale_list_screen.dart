import 'package:flutter/material.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/services/customer_service.dart';
import 'package:ehstore_app/models/customer.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'sale_detail_screen.dart';
import 'new_sale_screen.dart';
import 'package:intl/intl.dart';
import '../debit/date_filter_utils.dart';

class SaleListScreen extends StatefulWidget {
  final DateFilterOption? initialFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const SaleListScreen({
    Key? key,
    this.initialFilter,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  SaleListScreenState createState() => SaleListScreenState();
}

class SaleListScreenState extends State<SaleListScreen> {
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  Map<String, Customer> _customersCache = {};
  bool _isLoading = true;
  String _searchQuery = '';
  double _totalSales = 0.0;
  
  DateFilterOption _currentFilter = DateFilterOption.today;
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    // Inicializar filtros desde los parámetros
    _currentFilter = widget.initialFilter ?? DateFilterOption.today;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _loadSales();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Método público para recargar ventas con filtros nuevos
  void reloadSales(DateFilterOption filter, DateTime? startDate, DateTime? endDate) {
    setState(() {
      _currentFilter = filter;
      _startDate = startDate;
      _endDate = endDate;
    });
    _loadSalesWithFilter();
  }
  
  Future<void> _loadSalesWithFilter() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Sale> sales = [];
      
      // Cargar ventas según el filtro seleccionado
      switch (_currentFilter) {
        case DateFilterOption.today:
          sales = await _saleService.getSalesOfDay();
          break;
          
        case DateFilterOption.thisWeek:
          sales = await _saleService.getSalesOfWeek();
          break;
          
        case DateFilterOption.thisMonth:
          sales = await _saleService.getSalesOfMonth();
          break;
          
        case DateFilterOption.custom:
          if (_startDate != null && _endDate != null) {
            sales = await _saleService.getSalesByDateRange(_startDate!, _endDate!);
          } else {
            sales = await _saleService.getAllSales();
          }
          break;
      }
      
      // Calcular total de ventas
      double total = 0;
      for (var sale in sales) {
        total += sale.total;
      }
      
      if (mounted) {
        setState(() {
          _sales = sales;
          _filteredSales = sales;
          _totalSales = total;
          _isLoading = false;
        });
        
        // Precargar información de clientes
        _preloadCustomers();
        
        // Aplicar filtros si hay alguno
        if (_searchQuery.isNotEmpty) {
          _filterSales();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ventas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadSales() async {
    // Simplemente llamar al método que maneja los filtros
    await _loadSalesWithFilter();
  }
  
  // Precarga información de clientes para mostrar nombres
  Future<void> _preloadCustomers() async {
    try {
      // Obtener IDs únicos de clientes
      final Set<String> customerIds = _sales.map((sale) => sale.customerId).toSet();
      
      // Cargar información de clientes
      for (String id in customerIds) {
        if (!_customersCache.containsKey(id)) {
          final customer = await _customerService.getCustomerById(id);
          if (customer != null && mounted) {
            setState(() {
              _customersCache[id] = customer;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _filterSales() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredSales = _sales;
      });
      return;
    }
    
    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredSales = _sales.where((sale) {
        // Verificar si el cliente está en caché
        final customer = _customersCache[sale.customerId];
        final String customerName = customer != null 
            ? '${customer.firstName} ${customer.lastName}'.toLowerCase() 
            : '';
        
        // Buscar por ID de venta, cliente, o fecha
        return sale.id.toLowerCase().contains(query) ||
               customerName.contains(query) ||
               DateFormat('dd/MM/yyyy').format(sale.createdAt).contains(query);
      }).toList();
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterSales();
  }
  
  Future<void> _refreshSales() async {
    await _loadSales();
  }
  
  // Mostrar menú de filtros de fecha
  void _showFilterMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<DateFilterOption>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<DateFilterOption>(
          value: DateFilterOption.today,
          child: Text('Hoy'),
        ),
        const PopupMenuItem<DateFilterOption>(
          value: DateFilterOption.thisWeek,
          child: Text('Esta semana'),
        ),
        const PopupMenuItem<DateFilterOption>(
          value: DateFilterOption.thisMonth,
          child: Text('Este mes'),
        ),
        const PopupMenuItem<DateFilterOption>(
          value: DateFilterOption.custom,
          child: Text('Rango personalizado'),
        ),
      ],
    ).then((DateFilterOption? value) {
      if (value != null) {
        if (value == DateFilterOption.custom) {
          _showDateRangePicker();
        } else {
          setState(() {
            _currentFilter = value;
            _startDate = null;
            _endDate = null;
          });
          _loadSalesWithFilter();
        }
      }
    });
  }
  
  // Mostrar selector de rango de fechas
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? dateRange = await DateFilterUtils.showDateRangePickerDialog(
      context, 
      _startDate, 
      _endDate
    );

    if (dateRange != null) {
      setState(() {
        _currentFilter = DateFilterOption.custom;
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });
      _loadSalesWithFilter();
    }
  }
  
  // Construir tarjeta con información de ventas
  Widget _buildSalesInfoCard() {
    return Card(
      color: AppTheme.cardBackground,
      elevation: 2,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFilterUtils.buildFilterTitle(_currentFilter, _startDate, _endDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_currentFilter == DateFilterOption.custom && (_startDate == null || _endDate == null))
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Seleccionar fechas'),
                    onPressed: _showDateRangePicker,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DateFilterUtils.buildSalesTotalsWidget(_totalSales, _isLoading),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          const SizedBox(height: 18,),
          // Tarjeta de información de ventas
          _buildSalesInfoCard(),

          //filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: Row(
              children: [            
                // Campo de búsqueda
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ventas...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                const SizedBox(width: 8),

                // Botón de filtro
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Builder(
                    builder: (context) => InkWell(
                      onTap: () => _showFilterMenu(context),
                      borderRadius: BorderRadius.circular(9),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, color: AppTheme.primaryColor),
                            SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
               
              ],
            ),
          ),
 
          const SizedBox(height: 8,),

        //informacion ventas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredSales.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron ventas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshSales,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = _filteredSales[index];
                            final customer = _customersCache[sale.customerId];
                            final customerName = customer != null 
                                ? '${customer.firstName} ${customer.lastName}'
                                : 'Cliente #${sale.customerId}';
                            
                            return Card(
                              color: AppTheme.cardBackground,
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: _buildStatusIcon(sale.status),
                                title: Text(
                                  'Venta #${sale.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cliente: $customerName'),
                                    Text('${DateFormat('dd/MM/yy hh:mma').format(sale.createdAt)}'),
                                    if (sale.status == SaleStatus.credit)
                                      Text(
                                        'Deuda: \$${(sale.total - sale.totalPaid).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  '\$${sale.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SaleDetailScreen(saleId: sale.id),
                                    ),
                                  ).then((_) => _refreshSales());
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),      
        ],
      ),

      // Botón flotante para agregar producto
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewSaleScreen(),
            ),
          ).then((_) => _refreshSales());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white,),
      ), 
    );
  }
  
  Widget _buildStatusIcon(SaleStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case SaleStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SaleStatus.credit:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case SaleStatus.canceled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case SaleStatus.refunded:
        icon = Icons.replay;
        color = Colors.purple;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }
} 