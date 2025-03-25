import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color.fromARGB(255, 1, 166, 255);  // Azul principal
  static const backgroundColor = Colors.white;
  static const cardBackground = Color(0xFFF8F9FE);
  
  static ThemeData theme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Quicksand',
    
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: backgroundColor,
      indicatorColor: const Color.fromARGB(255, 52, 37, 255).withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
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