import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extension untuk mempermudah akses warna dari mana saja di UI
/// Contoh: context.color.primary | context.isDarkMode
extension ThemeExtension on BuildContext {
  ColorScheme get color => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────────────────────
// THEME PROVIDER — mengelola preferensi tema (light/dark/system)
// ─────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  // Default: Light Mode (bisa diubah user via toggle)
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      return dispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────
// APP THEME — definisi lengkap Light & Dark theme
// ─────────────────────────────────────────────────────────────
class AppTheme {
  // ── Warna Semantik (sama di semua mode) ──────────────────────
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color error   = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info    = Color(0xFF3B82F6); // Blue 500

  // ── LIGHT MODE — Clean & Minimalist (White/Blue) ─────────────────
  // Palette: Blue primary, clean white surface, subtle gray background
  static const _lPrimary        = Color(0xFF3B82F6); // Soft Blue 500
  static const _lPrimaryVar     = Color(0xFF2563EB); // Soft Blue 600
  static const _lSecondary      = Color(0xFF60A5FA); // Light Blue
  static const _lBackground     = Color(0xFFF9FAFB); // Cool Gray 50 (Slightly off-white)
  static const _lSurface        = Color(0xFFFFFFFF); // Pure White for Cards
  static const _lSurfaceVar     = Color(0xFFF3F4F6); // Gray 100 for Inputs
  static const _lOnSurface      = Color(0xFF1F2937); // Gray 800 (Dark text)
  static const _lOnSurfaceVar   = Color(0xFF6B7280); // Gray 500 (Muted text)
  static const _lOutline        = Color(0xFFE5E7EB); // Gray 200 (Borders)
  static const _lOutlineVar     = Color(0xFFD1D5DB); // Gray 300

  // ── DARK MODE — True Dark (High Contrast) ────────────────────
  // Palette: True black/charcoal background, sky blue accent, crisp white text
  static const _dPrimary        = Color(0xFF60A5FA); // Sky Blue 400 — visible on dark
  static const _dPrimaryVar     = Color(0xFF3B82F6); // Blue 500
  static const _dSecondary      = Color(0xFF93C5FD); // Sky Blue 300
  static const _dBackground     = Color(0xFF0A0F1C); // True near-black
  static const _dSurface        = Color(0xFF141927); // Very dark navy — card bg
  static const _dSurfaceVar     = Color(0xFF1E2535); // Dark navy — input bg
  static const _dOnSurface      = Color(0xFFF1F5F9); // Slate 100 — crisp white text
  static const _dOnSurfaceVar   = Color(0xFF94A3B8); // Slate 400 — muted but readable
  static const _dOutline        = Color(0xFF2E3A4E); // Subtle border
  static const _dOutlineVar     = Color(0xFF3D4F66); // Slightly brighter border

  // ── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary:              _lPrimary,
      primaryContainer:     _lPrimaryVar,
      secondary:            _lSecondary,
      surface:              _lBackground,
      surfaceContainer:     _lSurface,
      surfaceContainerLow:  _lSurfaceVar,
      onSurface:            _lOnSurface,
      onSurfaceVariant:     _lOnSurfaceVar,
      outline:              _lOutline,
      outlineVariant:       _lOutlineVar,
      tertiary:             success,
      error:                error,
    ),
    scaffoldBackgroundColor: _lBackground,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: _lOnSurface,
      displayColor: _lOnSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:        _lSurface,
      foregroundColor:        _lOnSurface,
      elevation:              0,
      scrolledUnderElevation: 1,
      shadowColor:            _lOutline,
      surfaceTintColor:       Colors.transparent,
      iconTheme:              const IconThemeData(color: _lOnSurface),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700, color: _lOnSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: _lSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _lOutline, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _lOutline, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lSurfaceVar,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lSecondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );

  // ── DARK THEME ───────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:              _dPrimary,
      primaryContainer:     _dPrimaryVar,
      secondary:            _dSecondary,
      surface:              _dBackground,
      surfaceContainer:     _dSurface,
      surfaceContainerLow:  _dSurfaceVar,
      onSurface:            _dOnSurface,
      onSurfaceVariant:     _dOnSurfaceVar,
      outline:              _dOutline,
      outlineVariant:       _dOutlineVar,
      tertiary:             success,
      error:                error,
    ),
    scaffoldBackgroundColor: _dBackground,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: _dOnSurface,
      displayColor: _dOnSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:        _dSurface,
      foregroundColor:        _dOnSurface,
      elevation:              0,
      scrolledUnderElevation: 1,
      shadowColor:            _dOutline,
      surfaceTintColor:       Colors.transparent,
      iconTheme:              const IconThemeData(color: _dOnSurface),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700, color: _dOnSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: _dSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _dOutline, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _dOutline, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _dSurfaceVar,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _dPrimary,
        foregroundColor: const Color(0xFF0A0F1C), // Dark text on bright button
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF141927),
      selectedItemColor: Color(0xFF60A5FA),
      unselectedItemColor: Color(0xFF64748B),
    ),
  );
}
