import 'package:flutter/material.dart';

/// Paleta de Lapticon (la misma del ícono de la app).
class AppColors {
  static const azul = Color(0xFF1456C8);
  static const azulClaro = Color(0xFF2F7BE8);
  static const azulOscuro = Color(0xFF0B3D91);
  static const ambar = Color(0xFFFFB800);
  static const tinta = Color(0xFF14213D); // texto principal
  static const fondo = Color(0xFFF4F6FB);
  static const borde = Color(0xFFE3E8F1);

  static const gradiente = LinearGradient(
    colors: [azulClaro, azulOscuro],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData construirTema() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.azul,
    primary: AppColors.azul,
    secondary: AppColors.ambar,
    surface: Colors.white,
  );
  final redondeado = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondo,
      foregroundColor: AppColors.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.tinta),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borde),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: borde(AppColors.borde),
      enabledBorder: borde(AppColors.borde),
      focusedBorder: borde(AppColors.azul, 2),
      errorBorder: borde(scheme.error),
      focusedErrorBorder: borde(scheme.error, 2),
      disabledBorder: borde(AppColors.borde),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: redondeado,
        minimumSize: const Size(0, 50),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: redondeado,
        minimumSize: const Size(0, 50),
        side: const BorderSide(color: AppColors.borde, width: 1.5),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.azul,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.azul.withValues(alpha: 0.12),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.azul : Colors.grey.shade600,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.azul : Colors.grey.shade600,
          )),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borde, space: 1),
  );
}
