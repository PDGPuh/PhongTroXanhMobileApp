import 'package:flutter/cupertino.dart';
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
    height: 1.2,
    letterSpacing: -.1,
  );
  static TextStyle title([double size = 24]) => TextStyle(
    fontFamily: uiFont,
    fontSize: size < 13 ? 13 : size,
    fontWeight: FontWeight.w600,
    color: deep,
    height: 1.25,
    letterSpacing: size >= 24 ? -.25 : 0,
  );
  static TextStyle body([double size = 14, Color color = deep]) => TextStyle(
    fontFamily: uiFont,
    fontSize: size < 11 ? 11 : size,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.35,
    letterSpacing: 0,
  );
  static TextStyle caption([Color color = muted]) => TextStyle(
    fontFamily: uiFont,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.28,
    letterSpacing: 0,
  );
  static TextStyle price([double size = 20]) => title(
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: uiFont,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    iconTheme: const IconThemeData(color: deep),
    scaffoldBackgroundColor: Colors.white,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: Colors.white,
      onSurface: deep,
    ),
    textTheme: TextTheme(
      displayLarge: title(34),
      displayMedium: title(30),
      displaySmall: title(26),
      headlineLarge: title(24),
      headlineMedium: title(22),
      headlineSmall: title(20),
      titleLarge: title(18),
      titleMedium: title(15),
      titleSmall: title(14),
      bodyLarge: body(15),
      bodyMedium: body(14),
      bodySmall: body(12),
      labelLarge: body(13).copyWith(fontWeight: FontWeight.w500),
      labelMedium: body(12).copyWith(fontWeight: FontWeight.w500),
      labelSmall: caption().copyWith(fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: deep,
      centerTitle: false,
      elevation: 0,
      toolbarHeight: 46,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      hintStyle: body(13, muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
