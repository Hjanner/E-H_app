import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:ehstore_app/services/sale_service.dart';
import 'package:ehstore_app/models/sale.dart';
import 'package:intl/intl.dart';
import 'sale_list_screen.dart';
import 'debt_list_screen.dart';
import 'date_filter_utils.dart';

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
  
  // Variables de filtro
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
          sales = await _saleService.getSalesOfDay();
          break;
        case DateFilterOption.thisWeek:
          sales = await _saleService.getSalesOfWeek();
          break;
        case DateFilterOption.thisMonth:
          sales = await _saleService.getSalesOfMonth();
          break;
        case DateFilterOption.custom:
          if (startDate != null && endDate != null) {
            sales = await _saleService.getSalesByDateRange(startDate!, endDate!);
          }
          break;
      }
      
      // Actualizar título del filtro
      setState(() {
        filterTitle = DateFilterUtils.buildFilterTitle(selectedFilter, startDate, endDate);
      });
      
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
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
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 