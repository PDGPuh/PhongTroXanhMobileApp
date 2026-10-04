import 'package:flutter/material.dart';

abstract final class PT {
  static const green = Color(0xFF008568);
  static const deep = Color(0xFF073B3C);
  static const mint = Color(0xFFEAF9F4);
  static const sage = Color(0xFFDAF5EC);
  static const muted = Color(0xFF586B7D);
  static const line = Color(0xFFE2EBEE);
  static const grey = Color(0xFFF1F4F7);
  static const error = Color(0xFFB42339);
  static const red = Color(0xFFFF4058);
  static const amber = Color(0xFFF59B18);
  static const uiFont = 'Be Vietnam Pro';
  static const tabMotionDuration = Duration(milliseconds: 260);
  static const navFeedbackDuration = Duration(milliseconds: 180);
  static const tabMotionCurve = Curves.easeOutCubic;

  /// The wordmark keeps the reference's serif character; app content uses
  /// one Vietnamese sans family and natural spacing throughout.
  static TextStyle brand([double size = 20]) => TextStyle(
    fontFamily: 'Lora',
    fontSize: size,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation('wght', 600)],
    color: deep,
    height: 1.3,
    letterSpacing: -.1,
  );
  static TextStyle title([double size = 26]) => TextStyle(
    fontFamily: uiFont,
    fontSize: size < 15 ? 15 : size,
    fontWeight: FontWeight.w600,
    color: deep,
    height: 1.35,
    letterSpacing: size >= 26 ? -.25 : 0,
  );
  static TextStyle body([double size = 15, Color color = deep]) => TextStyle(
    fontFamily: uiFont,
    fontSize: size < 12 ? 12 : (size <= 14 ? size + 1 : size),
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
    letterSpacing: 0,
  );
  static TextStyle caption([Color color = muted]) => TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.4,
    letterSpacing: 0,
  );
  static TextStyle price([double size = 22]) => title(
    size,
  ).copyWith(color: green, fontFeatures: const [FontFeature.tabularFigures()]);
  static BoxDecoration card({Color color = Colors.white, double radius = 14}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: deep.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      );
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: uiFont,
    iconTheme: const IconThemeData(color: deep),
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: Colors.white,
      onSurface: deep,
    ),
    textTheme: TextTheme(
      displayLarge: title(40),
      displayMedium: title(36),
      displaySmall: title(32),
      headlineLarge: title(30),
      headlineMedium: title(28),
      headlineSmall: title(24),
      titleLarge: title(22),
      titleMedium: title(17),
      titleSmall: title(15),
      bodyLarge: body(16),
      bodyMedium: body(),
      bodySmall: body(12),
      labelLarge: body(14).copyWith(fontWeight: FontWeight.w500),
      labelMedium: body(12).copyWith(fontWeight: FontWeight.w500),
      labelSmall: caption().copyWith(fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: deep,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: body(14, muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: deep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
  );
}
