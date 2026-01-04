import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double kBorderRadius = 8.0;

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF346346), // Dark Green
  primary: const Color(0xFF346346),
  brightness: Brightness.light,
  surfaceBright: const Color(0xFFF9FAFB), // Off-white
  surface: Colors.white,
  onSurface: const Color(0xFF1C242E), // Dark Text
  surfaceContainerHighest: const Color(0xFFE5E7EB), // Light Gray
  primaryContainer: Colors.grey.shade100,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF346346),
  primary: const Color(0xFF346346),
  brightness: Brightness.dark,
  surfaceBright: const Color(0xFF1C242E), // Dark Background
  surface: const Color(0xFF2B3442), // Slightly Lighter Surface
  onSurface: const Color(0xFFF9FAFB), // Light Text
  surfaceContainerHighest: const Color(0xFF6B7280), // Gray for variants
  primaryContainer: Colors.grey.shade100,
);

ThemeData buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.primaryContainer,
    textTheme: GoogleFonts.latoTextTheme(
      ThemeData(brightness: colorScheme.brightness).textTheme,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(),
      filled: true,
      fillColor: colorScheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        // textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    dataTableTheme: DataTableThemeData(
      dataRowColor: WidgetStateProperty.all(colorScheme.surface),
      headingRowColor: WidgetStateProperty.all(colorScheme.surface),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      dividerThickness: 1,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
