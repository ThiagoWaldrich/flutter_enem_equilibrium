import 'package:flutter/material.dart';

class AppTheme {
  // Cores baseadas na imagem
  static const Color primaryColor = Color(0xFF011B3D);
  static const Color secondaryColor = Color(0xFF6b8cbc);
  static const Color accentColor = Color(0xFFff7b54);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFE8ECF0);
  static const Color darkGray = Color(0xFF64748B);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Bordas e raios
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: dangerColor,
        background: backgroundColor,
        surface: cardBackground,
      ),
      
      // AppBar - TUDO BRANCO AQUI
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // ← Texto e ícones brancos
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white), // ← Ícones brancos
        actionsIconTheme: IconThemeData(color: Colors.white), // ← Ícones de ação brancos
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white, // ← Título branco
        ),
      ),
      
      // Ícones globais também brancos no AppBar
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      
      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: cardElevation,
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textSecondary),
      ),
      
      // Texto
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: lightGray,
        thickness: 1,
        space: 24,
      ),
    );
  }
  
  // Métodos auxiliares para cores de matérias
  static Color getSubjectColor(String subjectName) {
    final colors = {
      'Matemática': const Color(0xFF3B82F6),
      'Física': const Color(0xFFEF4444),
      'Química': const Color(0xFF14B8A6),
      'Biologia': const Color(0xFF10B981),
      'História': const Color(0xFFF59E0B),
      'Geografia': const Color(0xFF8B5CF6),
      'Sociologia': const Color(0xFF06B6D4),
      'Filosofia': const Color(0xFF6366F1),
      'Português': const Color(0xFF22C55E),
      'Literatura': const Color(0xFFEC4899),
      'Redação': const Color(0xFFF97316),
      'Artes': const Color(0xFFFFFF55),
      'Inglês': const Color(0xFF0EA5E9),
      'Espanhol': const Color(0xFFF43F5E),
      'Simulado': const Color(0xFF78716C),
    };
    
    return colors[subjectName] ?? darkGray;
  }
}