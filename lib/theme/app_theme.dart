import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color.fromARGB(255, 1, 166, 255);  // Azul principal
  static const backgroundColor = Colors.white;
  static const cardBackground = Color(0xFFF8F9FE);
  static const textColor = Colors.black87;           // Color de texto principal
  static const secondaryColor = Color(0xFF5D5FEF);   // Color secundario
  static const accentColor = Color(0xFF00C853);      // Color de acento
  static const errorColor = Color(0xFFE53935);       // Color de error
  
  static ThemeData theme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Quicksand',
    
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        fontFamily: 'Quicksand',
        color: Colors.black,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
    
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      elevation: 4,
    ),
    
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      focusColor: primaryColor,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIconColor: primaryColor,
      suffixIconColor: primaryColor,
      iconColor: primaryColor,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: primaryColor.withOpacity(0.3),
      selectionHandleColor: primaryColor,
    ),
    
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: backgroundColor,
      indicatorColor: const Color.fromARGB(255, 52, 37, 255).withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Quicksand',
        ),
      ),
      height: 65,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Quicksand',
      ),
    ),
  );
}