import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:ehstore_app/models/product.dart';
import 'package:intl/intl.dart';
import 'sale_list_screen.dart';
import 'debt_list_screen.dart';

// Definir la enumeración de filtros de fecha como pública
enum DateFilterOption {
  today,
  thisWeek,
  thisMonth,
  custom
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SaleService _saleService = SaleService();
  
  double _totalSales = 0.0;
  bool _isLoading = true;
  
  // Hacer variables públicas para que las pantallas hijas puedan acceder
  DateFilterOption selectedFilter = DateFilterOption.today;
  String filterTitle = 'Ventas del Día';
  DateTime? startDate;
  DateTime? endDate;
  
  // Key para forzar la reconstrucción de las pestañas cuando cambia el filtro
  final GlobalKey<SaleListScreenState> _saleListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSalesData();
  }
  
  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<Sale> sales = [];
      
      // Cargar ventas según el filtro seleccionado
      switch (selectedFilter) {
        case DateFilterOption.today:
          setState(() {
            filterTitle = 'Ventas del Día';
          });
          sales = await _saleService.getSalesOfDay();
          break;
          
        case DateFilterOption.thisWeek:
          setState(() {
            filterTitle = 'Ventas de la Semana';
          });
          sales = await _saleService.getSalesOfWeek();
          break;
          
        case DateFilterOption.thisMonth:
          setState(() {
            filterTitle = 'Ventas del Mes';
          });
          sales = await _saleService.getSalesOfMonth();
          break;
          
        case DateFilterOption.custom:
          if (startDate != null && endDate != null) {
            final formatter = DateFormat('dd/MM/yyyy');
            setState(() {
              filterTitle = 'Ventas del ${formatter.format(startDate!)} al ${formatter.format(endDate!)}';
            });
            sales = await _saleService.getSalesByDateRange(startDate!, endDate!);
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
          _totalSales = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de ventas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        startDate = dateRange.start;
        endDate = dateRange.end;
        selectedFilter = DateFilterOption.custom;
      });
      
      // Recargar datos con el nuevo filtro
      _loadSalesData();
      
      // Forzar actualización de pestaña de ventas
      if (_saleListKey.currentState != null) {
        _saleListKey.currentState!.reloadSales(
          selectedFilter, 
          startDate, 
          endDate
        );
      }
    }
  }
  
  void _applyFilter(DateFilterOption filter) {
    setState(() {
      selectedFilter = filter;
      
      // Si no es filtro personalizado, limpiar fechas
      if (filter != DateFilterOption.custom) {
        startDate = null;
        endDate = null;
      }
    });
    
    // Recargar datos con el nuevo filtro
    _loadSalesData();
    
    // Forzar actualización de pestaña de ventas
    if (_saleListKey.currentState != null) {
      _saleListKey.currentState!.reloadSales(
        selectedFilter, 
        startDate, 
        endDate
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          // Botón de filtro de fecha
          PopupMenuButton<DateFilterOption>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por fecha',
            onSelected: _applyFilter,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<DateFilterOption>>[
              const PopupMenuItem<DateFilterOption>(
                value: DateFilterOption.today,
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20),
                    SizedBox(width: 8),
                    Text('Hoy'),
                  ],
                ),
              ),
              const PopupMenuItem<DateFilterOption>(
                value: DateFilterOption.thisWeek,
                child: Row(
                  children: [
                    Icon(Icons.view_week, size: 20),
                    SizedBox(width: 8),
                    Text('Esta semana'),
                  ],
                ),
              ),
              const PopupMenuItem<DateFilterOption>(
                value: DateFilterOption.thisMonth,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text('Este mes'),
                  ],
                ),
              ),
              const PopupMenuItem<DateFilterOption>(
                value: DateFilterOption.custom,
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20),
                    SizedBox(width: 8),
                    Text('Rango personalizado'),
                  ],
                ),
              ),
            ],
          ),
          if (selectedFilter == DateFilterOption.custom)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Seleccionar fechas',
              onPressed: _showDateRangePicker,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Ventas'),
            Tab(text: 'Deudas'), 
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSalesInfo(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SaleListScreen(
                  key: _saleListKey,
                  initialFilter: selectedFilter,
                  startDate: startDate,
                  endDate: endDate,
                ),
                const DebtListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSalesInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Card(
        color: AppTheme.cardBackground,
        elevation: 2,
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
                      filterTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selectedFilter == DateFilterOption.custom && (startDate == null || endDate == null))
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
              _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total en USD',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '\$${_totalSales.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total en Bs',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Bs. ${(_totalSales * Product.exchangeRate).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 