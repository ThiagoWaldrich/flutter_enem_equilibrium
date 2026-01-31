import 'package:flutter/material.dart';

class AppTheme {
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
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light().copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        error: dangerColor,
        surface: cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white), 
        actionsIconTheme:
            IconThemeData(color: Colors.white), 
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      iconTheme: const IconThemeData(
        color: Colors.white,
      ),

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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF1E293B),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8ECF0),
        thickness: 1,
        space: 24,
      ),
    );
  }
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
      'Artes': const Color(0xFFFFD700),
      'Inglês': const Color(0xFF0EA5E9),
      'Espanhol': const Color(0xFFF43F5E),
      'Simulado': const Color(0xFF78716C),
      'Língua Portuguesa': const Color(0xFF22C55E),
    };

    return colors[subjectName] ?? darkGray;
  }

  static Color getTopicColor(String topicName) {
    final hash = topicName.hashCode;
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6), 
      const Color(0xFF10B981), 
      const Color(0xFFF59E0B), 
      const Color(0xFF8B5CF6), 
      const Color(0xFFEC4899), 
      const Color(0xFF06B6D4), 
      const Color(0xFFF97316), 
      const Color(0xFF84CC16), 
      const Color(0xFF6366F1), 
    ];
    return colors[hash.abs() % colors.length];
  }

  static Color getSubtopicColor(String subtopicName) {
    final hash = subtopicName.hashCode;
    final colors = [
      const Color(0xFFFEE2E2),
      const Color(0xFFDBEAFE), 
      const Color(0xFFD1FAE5),
      const Color(0xFFFEF3C7), 
      const Color(0xFFEDE9FE), 
      const Color(0xFFFCE7F3), 
      const Color(0xFFCFFAFE),
      const Color(0xFFFFEDD5),
      const Color(0xFFD9F99D), 
      const Color(0xFFE0E7FF),
    ];
    return colors[hash.abs() % colors.length];
  }
  static Gradient getSubjectGradient(String subjectName) {
    final baseColor = getSubjectColor(subjectName);
    return LinearGradient(
      colors: [
        baseColor,
        Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color getTextOnGradient(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance < 0.5 ? Colors.white : Colors.black;
  }
  static Map<String, Color> getErrorColors() {
    return {
      'conteudo': dangerColor,
      'atencao': warningColor,
      'tempo': infoColor,
    };
  }
  static Map<String, Color> getStatusColors() {
    return {
      'success': successColor,
      'warning': warningColor,
      'error': dangerColor,
      'info': infoColor,
    };
  }
}
