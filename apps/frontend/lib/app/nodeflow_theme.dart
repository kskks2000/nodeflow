import 'package:flutter/material.dart';

class NodeFlowColors {
  const NodeFlowColors._();

  static const deepBlue = Color(0xFF1E3A8A);
  static const mint = Color(0xFF10B981);
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF475569);
  static const softSlate = Color(0xFFE2E8F0);
  static const cloud = Color(0xFFF8FAFC);
  static const field = Color(0xFFF1F5F9);
  static const amber = Color(0xFFF59E0B);
}

class NodeFlowTheme {
  const NodeFlowTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NodeFlowColors.deepBlue,
      primary: NodeFlowColors.deepBlue,
      secondary: NodeFlowColors.mint,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NodeFlowColors.cloud,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: NodeFlowColors.ink,
          height: 1.08,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: NodeFlowColors.ink,
          height: 1.18,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: NodeFlowColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: NodeFlowColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: NodeFlowColors.slate,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: NodeFlowColors.slate,
          height: 1.4,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NodeFlowColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NodeFlowColors.softSlate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: NodeFlowColors.deepBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        labelStyle: const TextStyle(
          color: NodeFlowColors.slate,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: NodeFlowColors.deepBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NodeFlowColors.deepBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NodeFlowColors.mint;
          }
          return Colors.white;
        }),
        side: const BorderSide(color: NodeFlowColors.softSlate, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
