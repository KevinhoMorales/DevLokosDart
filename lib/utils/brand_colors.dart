import 'package:flutter/material.dart';

/// Clase para manejar los colores del brand DevLokos
/// Basado en el logo oficial con colores naranja, negro y blanco
class BrandColors {
  // Colores principales del logo
  static const Color primaryOrange = Color(0xFFFF914D); // #ff914D
  static const Color primaryBlack = Color(0xFF000000);  // #000000
  static const Color primaryWhite = Color(0xFFFFFFFF);  // #FFFFFF

  // Variaciones del naranja
  static const Color orangeLight = Color(0xFFFFA366);
  static const Color orangeDark = Color(0xFFE67E22);
  static const Color orangeAccent = Color(0xFFFFB366);
  
  // Variaciones del negro
  static const Color blackLight = Color(0xFF1A1A1A);
  static const Color blackMedium = Color(0xFF2D2D2D);
  static const Color blackDark = Color(0xFF0D0D0D);
  
  // Grises para textos secundarios
  static const Color grayLight = Color(0xFFF5F5F5);
  static const Color grayMedium = Color(0xFF9E9E9E);
  static const Color grayDark = Color(0xFF616161);
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Gradientes del brand
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, orangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [primaryBlack, blackLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [primaryBlack, blackMedium],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombras con color del brand
  static List<BoxShadow> get orangeShadow => [
    BoxShadow(
      color: primaryOrange.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get blackShadow => [
    BoxShadow(
      color: primaryBlack.withOpacity(0.5),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  // Colores para temas
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: grayLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryOrange,
      foregroundColor: primaryWhite,
      elevation: 0,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: primaryBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: primaryWhite,
      elevation: 0,
    ),
  );
}



