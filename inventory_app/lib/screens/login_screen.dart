import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

/// ============================================================
/// HALAMAN LOGIN — Smart Retail Inventory
/// ============================================================
/// Desain adaptif Light / Dark mode.
/// Light: Latar putih bersih, aksen navy biru — enterprise look.
/// Dark : Latar slate gelap GitHub-style, aksen biru cerah.
/// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Warna adaptif
    final bgColor       = isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F6F9);
    final cardColor     = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor   = isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);
    final primaryColor  = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A5F);
    final textPrimary   = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0F172A);
    final textMuted     = isDark ? const Color(0xFF8B949E) : const Color(0xFF64748B);
    final inputFill     = isDark ? const Color(0xFF21262D) : const Color(0xFFF8FAFC);
    final inputBorder   = isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);
    final accentBlue    = isDark ? const Color(0xFF60A5FA) : const Color(0xFF4A6FA5);

    // Status bar adaptif
    SystemChrome.setSystemUIOverlayStyle(isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D1117), const Color(0xFF161B22), const Color(0xFF0F172A)]
                : [const Color(0xFFF4F6F9), const Color(0xFFE0E7FF), const Color(0xFFF4F6F9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ══════════════════════════════════════
                    // LOGO & BRAND
                    // ══════════════════════════════════════
                    _buildBrandSection(
                        isDark, primaryColor, textPrimary, textMuted, borderColor),

                    const SizedBox(height: 32),

                    // ══════════════════════════════════════
                    // FORM CARD
                    // ══════════════════════════════════════
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? cardColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? borderColor : Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? Colors.black.withValues(alpha: 0.3) 
                                : primaryColor.withValues(alpha: 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Judul form
                            Text(
                              'Masuk ke Akun',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Masukkan email dan password untuk melanjutkan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Field Email ──────────────────
                            _buildLabel('Email', textMuted),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: textPrimary),
                              decoration: _inputDecoration(
                                hint: 'nama@perusahaan.com',
                                icon: Icons.alternate_email_rounded,
                                isDark: isDark,
                                fillColor: inputFill,
                                borderColor: inputBorder,
                                accentColor: accentBlue,
                                textMuted: textMuted,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ── Field Password ───────────────
                            _buildLabel('Password', textMuted),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: textPrimary),
                              decoration: _inputDecoration(
                                hint: '••••••••••',
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                fillColor: inputFill,
                                borderColor: inputBorder,
                                accentColor: accentBlue,
                                textMuted: textMuted,
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),

                            // ── Error Message ────────────────
                            Consumer<AuthProvider>(
                              builder: (ctx, auth, _) {
                                if (auth.errorMessage == null) {
                                  return const SizedBox(height: 4);
                                }
                                return Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.error
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded,
                                          size: 16, color: AppTheme.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          auth.errorMessage!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // ── Tombol Login ─────────────────
                            Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: _isLoading ? null : LinearGradient(
                                  colors: isDark 
                                      ? [primaryColor, const Color(0xFF3B82F6)] 
                                      : [primaryColor, const Color(0xFF2563EB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                color: _isLoading ? primaryColor.withValues(alpha: 0.5) : null,
                                boxShadow: _isLoading || isDark ? [] : [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: isDark
                                              ? const Color(0xFF0D1117)
                                              : Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Masuk',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? const Color(0xFF0D1117)
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: isDark
                                                ? const Color(0xFF0D1117)
                                                : Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Footer info ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Koneksi aman & terenkripsi',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '© 2026 Smart Retail Inventory',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// Brand section — logo + nama aplikasi
  Widget _buildBrandSection(bool isDark, Color primaryColor, Color textPrimary,
      Color textMuted, Color borderColor) {
    return Column(
      children: [
        // Logo icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [primaryColor, const Color(0xFF3B82F6)] 
                  : [primaryColor, const Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.4 : 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.storefront_rounded,
              size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Smart Retail MVP',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15)),
          ),
          child: Text(
            'Inventory Management System',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF4A6FA5),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  /// Label field yang konsisten
  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  /// Dekorasi input field yang adaptif
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
    required Color accentColor,
    required Color textMuted,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          fontSize: 14, color: textMuted.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, size: 18, color: textMuted),
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffixIcon,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.error, width: 2),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: AppTheme.error),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}
