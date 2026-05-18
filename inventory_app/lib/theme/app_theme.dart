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

  // ── LIGHT MODE — Clean & Professional ───────────────────────
  // Palette: Navy primary, clean white surface, subtle gray
  static const _lPrimary        = Color(0xFF1E3A5F); // Deep Navy
  static const _lPrimaryVar     = Color(0xFF2D5A8E); // Navy variant
  static const _lSecondary      = Color(0xFF4A6FA5); // Steel Blue
  static const _lBackground     = Color(0xFFF4F6F9); // Cool Gray 50
  static const _lSurface        = Color(0xFFFFFFFF); // Pure White
  static const _lSurfaceVar     = Color(0xFFF8FAFC); // Off-White
  static const _lOnSurface      = Color(0xFF0F172A); // Slate 900
  static const _lOnSurfaceVar   = Color(0xFF64748B); // Slate 500
  static const _lOutline        = Color(0xFFE2E8F0); // Slate 200
  static const _lOutlineVar     = Color(0xFFCBD5E1); // Slate 300

  // ── DARK MODE — Industry Standard (GitHub-inspired) ──────────
  // Reference: GitHub Dark, Linear, Vercel, Notion Dark
  // Palette: Pure dark backgrounds, not navy — proper contrast
  static const _dPrimary        = Color(0xFF60A5FA); // Blue 400 — CTA, links
  static const _dPrimaryVar     = Color(0xFF3B82F6); // Blue 500
  static const _dSecondary      = Color(0xFF93C5FD); // Blue 300 — secondary
  static const _dBackground     = Color(0xFF0D1117); // GitHub bg — true dark
  static const _dSurface        = Color(0xFF161B22); // GitHub surface
  static const _dSurfaceVar     = Color(0xFF21262D); // Elevated surface
  static const _dOnSurface      = Color(0xFFE6EDF3); // Near-white text
  static const _dOnSurfaceVar   = Color(0xFF8B949E); // Muted text
  static const _dOutline        = Color(0xFF30363D); // Subtle border
  static const _dOutlineVar     = Color(0xFF3D444D); // Visible border

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
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
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
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
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
        foregroundColor: const Color(0xFF0D1117),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
