import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth       = Provider.of<AuthProvider>(context);
    final productProv= Provider.of<ProductProvider>(context);
    final transProv  = Provider.of<TransactionProvider>(context);
    final user       = auth.currentUser;
    final isDark     = context.isDarkMode;

    // Warna adaptif
    final bgColor    = context.color.surface;
    final cardColor  = context.color.surfaceContainer;
    final textPrimary= context.color.onSurface;
    final textMuted  = context.color.onSurfaceVariant;
    final borderColor= context.color.outline;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: context.color.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: borderColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // ────── HERO CARD ──────────────────────────────────
            _buildHeroCard(context, auth, user, isDark),
            const SizedBox(height: 16),

            // ────── STAT CARDS ─────────────────────────────────
            Row(children: [
              _statCard(context,
                icon: Icons.inventory_2_rounded,
                label: 'Total Barang',
                value: '${productProv.totalBarang}',
                color: context.color.primary,
                cardColor: cardColor, borderColor: borderColor,
                textPrimary: textPrimary, textMuted: textMuted,
              ),
              const SizedBox(width: 10),
              _statCard(context,
                icon: Icons.swap_horiz_rounded,
                label: 'Transaksi Hari Ini',
                value: '${transProv.totalTransaksiHariIni}',
                color: AppTheme.success,
                cardColor: cardColor, borderColor: borderColor,
                textPrimary: textPrimary, textMuted: textMuted,
              ),
              const SizedBox(width: 10),
              _statCard(context,
                icon: Icons.warning_amber_rounded,
                label: 'Stok Kritis',
                value: '${productProv.jumlahStokKritis}',
                color: AppTheme.error,
                cardColor: cardColor, borderColor: borderColor,
                textPrimary: textPrimary, textMuted: textMuted,
              ),
            ]),
            const SizedBox(height: 20),

            // ────── INFORMASI AKUN ─────────────────────────────
            _sectionLabel('INFORMASI AKUN', textMuted),
            const SizedBox(height: 8),
            _buildCard(context, cardColor, borderColor, [
              _infoTile(context,
                icon: Icons.person_rounded,
                iconColor: context.color.primary,
                label: 'Nama Lengkap',
                value: user?.nama ?? '-',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _divider(borderColor),
              _infoTile(context,
                icon: Icons.alternate_email_rounded,
                iconColor: context.color.primary,
                label: 'Email',
                value: user?.email ?? '-',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _divider(borderColor),
              _infoTile(context,
                icon: Icons.shield_rounded,
                iconColor: auth.isAdmin
                    ? context.color.primary
                    : AppTheme.success,
                label: 'Role',
                value: user?.roleLabel ?? '-',
                textPrimary: textPrimary,
                textMuted: textMuted,
                trailing: _roleBadge(context, auth, user),
              ),
              _divider(borderColor),
              _infoTile(context,
                icon: Icons.fingerprint_rounded,
                iconColor: textMuted,
                label: 'ID Pengguna',
                value: user?.id != null
                    ? '${user!.id.substring(0, 8)}...'
                    : '-',
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () {
                  if (user?.id != null) {
                    Clipboard.setData(ClipboardData(text: user!.id));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text('ID disalin!', style: GoogleFonts.inter()),
                      ]),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
                trailingIcon: Icons.copy_rounded,
              ),
            ]),

            const SizedBox(height: 16),

            // ────── TAMPILAN ───────────────────────────────────
            _sectionLabel('TAMPILAN', textMuted),
            const SizedBox(height: 8),
            _buildCard(context, cardColor, borderColor, [
              _themeTile(context, textPrimary, textMuted),
            ]),

            const SizedBox(height: 16),



            // ────── LAINNYA ────────────────────────────────────
            _sectionLabel('LAINNYA', textMuted),
            const SizedBox(height: 8),
            _buildCard(context, cardColor, borderColor, [
              _menuTile(context,
                icon: Icons.info_rounded,
                iconColor: textMuted,
                label: 'Tentang Aplikasi',
                subtitle: 'Smart Retail Inventory v1.0.0',
                textPrimary: textPrimary, textMuted: textMuted,
                borderColor: borderColor,
                onTap: () => _showAboutDialog(context),
              ),
              _divider(borderColor),
              _menuTile(context,
                icon: Icons.help_rounded,
                iconColor: textMuted,
                label: 'Bantuan & Panduan',
                subtitle: 'Cara menggunakan aplikasi',
                textPrimary: textPrimary, textMuted: textMuted,
                borderColor: borderColor,
                onTap: () => _showComingSoon(context),
              ),
            ]),

            const SizedBox(height: 20),

            // ────── LOGOUT BUTTON ──────────────────────────────
            InkWell(
              onTap: () => _handleLogout(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: isDark ? 0.1 : 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Keluar dari Akun',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context, AuthProvider auth, user, bool isDark) {
    final initial = (user?.nama != null && user!.nama.trim().isNotEmpty)
        ? (user.nama[0].toUpperCase())
        : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: auth.isAdmin
              ? [const Color(0xFF1E3A5F), const Color(0xFF2D5A8E)]
              : [const Color(0xFF15803D), const Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (auth.isAdmin
                    ? const Color(0xFF1E3A5F)
                    : const Color(0xFF22C55E))
                .withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(initial,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.nama ?? 'User',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(user?.email ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.person_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(user?.roleLabel ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Card ─────────────────────────────────────────────────
  Widget _statCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9, color: textMuted),
                textAlign: TextAlign.center,
                maxLines: 2),
          ],
        ),
      ),
    );
  }

  // ── Section helpers ───────────────────────────────────────────
  Widget _sectionLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: color,
            )),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color cardColor, Color borderColor,
      List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, color: color, indent: 16, endIndent: 16);
  }

  // ── Theme Toggle Tile ─────────────────────────────────────────
  Widget _themeTile(BuildContext context, Color textPrimary, Color textMuted) {
    return Consumer<ThemeProvider>(
      builder: (ctx, themeProv, _) {
        final dark = themeProv.isDarkMode;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (dark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    key: ValueKey(dark),
                    color: dark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFFF59E0B),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema Aplikasi',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        )),
                    Text(dark ? 'Mode Gelap aktif' : 'Mode Terang aktif',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: textMuted)),
                  ],
                ),
              ),
              // Custom toggle switch
              GestureDetector(
                onTap: () => themeProv.toggleTheme(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 26,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF3B82F6)
                        : context.color.outline,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: dark
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Info Tile ─────────────────────────────────────────────────
  Widget _infoTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textMuted,
    Widget? trailing,
    VoidCallback? onTap,
    IconData? trailingIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: textMuted)),
                  const SizedBox(height: 2),
                  trailing ??
                      Text(value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          )),
                ],
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, size: 16, color: textMuted),
          ],
        ),
      ),
    );
  }

  // ── Role Badge ────────────────────────────────────────────────
  Widget _roleBadge(BuildContext context, AuthProvider auth, user) {
    final isAdmin = auth.isAdmin;
    final color =
        isAdmin ? context.color.primary : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(user?.roleLabel ?? '-',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          )),
    );
  }

  // ── Menu Tile ─────────────────────────────────────────────────
  Widget _menuTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      )),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
          ],
        ),
      ),
    );
  }

  // ── Dialogs & Helpers ─────────────────────────────────────────
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.rocket_launch_rounded,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text('Fitur segera hadir! 🚀', style: GoogleFonts.inter()),
      ]),
      backgroundColor: context.color.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.color.surfaceContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.color.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Smart Retail',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface)),
            Text('Inventory System',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.color.onSurfaceVariant)),
          ]),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Versi 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  )),
            ),
            const SizedBox(height: 10),
            Text(
              'Aplikasi manajemen stok minimarket berbasis Supabase. '
              'Didesain untuk memudahkan pencatatan barang, monitoring stok kritis, '
              'dan peringatan kedaluwarsa secara real-time.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.color.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.color.primary,
              foregroundColor: isDark
                  ? const Color(0xFF0D1117)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Tutup', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.color.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.error, size: 22),
          const SizedBox(width: 10),
          Text('Konfirmasi Keluar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: context.color.onSurface,
              )),
        ]),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: GoogleFonts.inter(
              fontSize: 14, color: context.color.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(
                    color: context.color.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false)
                  .logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Keluar', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }
}
