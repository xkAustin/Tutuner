import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A84FF),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final dark = brightness == Brightness.dark;
    final glassSurface = scheme.surface.withValues(alpha: dark ? 0.42 : 0.62);
    final glassBorder = Colors.white.withValues(alpha: dark ? 0.14 : 0.64);
    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface.withValues(alpha: dark ? 0.94 : 0.92),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: glassSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: glassBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.72),
            width: 1.4,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: dark ? 0.34 : 0.22)
                : scheme.surface.withValues(alpha: dark ? 0.24 : 0.42),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurface,
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(pillShape),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: glassBorder),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.09),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(pillShape),
          elevation: const WidgetStatePropertyAll<double>(0),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.08)
                : scheme.primary.withValues(alpha: dark ? 0.78 : 0.88),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(pillShape),
          backgroundColor: WidgetStatePropertyAll<Color>(glassSurface),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: glassBorder),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: 0.20)
                : scheme.surface.withValues(alpha: dark ? 0.34 : 0.54),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: glassBorder),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glassSurface,
        selectedColor: scheme.primary.withValues(alpha: dark ? 0.32 : 0.20),
        side: BorderSide(color: glassBorder),
        shape: pillShape,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.62)
              : scheme.onSurface.withValues(alpha: 0.12),
        ),
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        trackOutlineColor: WidgetStatePropertyAll<Color>(
          glassBorder.withValues(alpha: 0.72),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll<Color>(glassSurface),
        elevation: const WidgetStatePropertyAll<double>(0),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: glassBorder),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(pillShape),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 1,
        backgroundColor: scheme.primary.withValues(alpha: dark ? 0.76 : 0.88),
        foregroundColor: scheme.onPrimary,
        shape: pillShape,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surface.withValues(alpha: dark ? 0.94 : 0.90),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: glassBorder),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 8,
        color: scheme.surface.withValues(alpha: dark ? 0.96 : 0.92),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: glassBorder),
        ),
      ),
    );
  }
}
