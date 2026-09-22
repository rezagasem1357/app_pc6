import 'package:flutter/material.dart';

/// تم این اپ عیناً از رنگ‌ها و فونت اپ موبایل صندوق/مدیریت (Vazir + سبز تیره
/// #185C3A) الگوبرداری شده تا حس بصری بین موبایل و ویندوز یکسان باشد.
class AppColors {
  static const primaryGreen = Color(0xFF185C3A);
  static const splashGreen = Color(0xFF12462D);
  static const gold = Color(0xFFD6B65A);
  static const darkGreen = Color(0xFF2D7B54);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazir',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6F5),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Vazir', height: 1.55),
      bodyMedium: TextStyle(fontFamily: 'Vazir', height: 1.5),
      titleLarge: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Vazir',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(fontFamily: 'Vazir'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(180, 38),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(180, 38),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(120, 36),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        textStyle: const TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(180, 38),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.primaryGreen,
      selectedIconTheme: const IconThemeData(color: AppColors.gold),
      unselectedIconTheme: const IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: const TextStyle(
          fontFamily: 'Vazir', color: AppColors.gold, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: const TextStyle(fontFamily: 'Vazir', color: Colors.white70),
      indicatorColor: Colors.white.withOpacity(0.12),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 0.6),
  );
}
