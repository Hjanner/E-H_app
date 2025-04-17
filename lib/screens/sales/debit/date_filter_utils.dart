import 'package:flutter/material.dart';
import 'package:ehstore_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:ehstore_app/models/product.dart';

// Definir la enumeración de filtros de fecha como pública
enum DateFilterOption {
  today,
  thisWeek,
  thisMonth,
  custom
}

// Clase de utilidades para manejar filtros de fecha
class DateFilterUtils {
  // Obtener texto para el filtro actual
  static String getFilterText(DateFilterOption filter, DateTime? startDate, DateTime? endDate) {
    switch (filter) {
      case DateFilterOption.today:
        return 'Hoy';
      case DateFilterOption.thisWeek:
        return 'Esta semana';
      case DateFilterOption.thisMonth:
        return 'Este mes';
      case DateFilterOption.custom:
        if (startDate != null && endDate != null) {
          final startDateFormat = DateFormat('dd/MM/yy').format(startDate);
          final endDateFormat = DateFormat('dd/MM/yy').format(endDate);
          return '$startDateFormat - $endDateFormat';
        }
        return 'Personalizado';
    }
  }

  // Construir el título del filtro
  static String buildFilterTitle(DateFilterOption filter, DateTime? startDate, DateTime? endDate) {
    switch (filter) {
      case DateFilterOption.today:
        return 'Ventas del Día';
      case DateFilterOption.thisWeek:
        return 'Ventas de la Semana';
      case DateFilterOption.thisMonth:
        return 'Ventas del Mes';
      case DateFilterOption.custom:
        if (startDate != null && endDate != null) {
          final formatter = DateFormat('dd/MM/yy');
          return 'Ventas del\n${formatter.format(startDate)} al ${formatter.format(endDate)}';
        }
        return 'Ventas Personalizadas';
    }
  }

  // Mostrar selector de rango de fechas con tema consistente
  static Future<DateTimeRange?> showDateRangePickerDialog(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate, end: endDate)
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                backgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
            dialogBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // Construir widget para mostrar totales de ventas
  static Widget buildSalesTotalsWidget(double totalSales, bool isLoading) {
    return isLoading
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
                    '\$${totalSales.toStringAsFixed(2)}',
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
                    'Bs. ${(totalSales * Product.exchangeRate).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          );
  }
} 