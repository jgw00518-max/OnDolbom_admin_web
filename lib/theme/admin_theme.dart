import 'package:flutter/material.dart';

/// 웹·앱 공통 팔레트. 화면의 업무 로직과 분리해 색상과 형태만 정의한다.
abstract final class AdminColors {
  static const peach = Color(0xFFF6B08A);
  static const lightPeach = Color(0xFFFFD6B5);
  static const cream = Color(0xFFFCEEE3);
  static const sage = Color(0xFFB7C8A1);
  static const ink = Color(0xFF3E3A39);
  static const background = Color(0xFFFBF8F5);
  static const border = Color(0xFFEEE5DF);
  static const muted = Color(0xFF817873);
  static const sageLight = Color(0xFFEDF3E8);
}

ThemeData buildAdminTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AdminColors.peach).copyWith(
    primary: AdminColors.ink,
    onPrimary: Colors.white,
    secondary: AdminColors.sage,
    onSecondary: AdminColors.ink,
    surface: Colors.white,
    onSurface: AdminColors.ink,
    outline: AdminColors.border,
    primaryContainer: AdminColors.cream,
    onPrimaryContainer: AdminColors.ink,
  );
  final theme = ThemeData(useMaterial3: true, colorScheme: scheme);
  return theme.copyWith(
    scaffoldBackgroundColor: AdminColors.background,
    textTheme: theme.textTheme.apply(
      bodyColor: AdminColors.ink,
      displayColor: AdminColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AdminColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AdminColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AdminColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFDFA),
      labelStyle: const TextStyle(fontSize: 13, color: AdminColors.muted),
      hintStyle: const TextStyle(fontSize: 13, color: AdminColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminColors.peach, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AdminColors.peach,
        foregroundColor: AdminColors.ink,
        minimumSize: const Size(72, 44),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AdminColors.ink,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminColors.ink,
        minimumSize: const Size(64, 40),
        side: const BorderSide(color: AdminColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        color: AdminColors.ink,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: AdminColors.ink,
      collapsedIconColor: AdminColors.muted,
      shape: Border(),
      collapsedShape: Border(),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AdminColors.muted,
      titleTextStyle: TextStyle(
        color: AdminColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(
        color: AdminColors.muted,
        fontSize: 12,
        height: 1.7,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AdminColors.peach,
    ),
  );
}
