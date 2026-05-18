import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/product_model.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final transProv = Provider.of<TransactionProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context, auth),
      body: SafeArea(
        child: productProv.isLoading
            ? _loadingState(context)
            : productProv.errorMessage != null
                ? _errorState(context, productProv.errorMessage!)
                : RefreshIndicator(
                    color: context.color.primary,
                    backgroundColor: context.color.surfaceContainer,
                    onRefresh: () => productProv.fetchProducts(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, auth, user),
                          const SizedBox(height: 20),
                          _buildSummaryCards(context, productProv, transProv),
                          const SizedBox(height: 20),
                          if (productProv.jumlahMendekatiExpired > 0) ...[
                            _buildExpiryBanner(context, productProv),
                            const SizedBox(height: 20),
                          ],
                          _buildSectionHeader(
                            context,
                            title: 'Stok Kritis',
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppTheme.error,
                            count: productProv.jumlahStokKritis,
                            countColor: AppTheme.error,
                          ),
                          const SizedBox(height: 12),
                          if (productProv.stokKritis.isEmpty)
                            _allSafeState(context)
                          else
                            ...productProv.stokKritis
                                .take(5)
                                .map((p) => _buildCriticalStockItem(context, p)),
                          const SizedBox(height: 20),
                          if (productProv.barangMendekatiExpired.isNotEmpty ||
                              productProv.barangSudahExpired.isNotEmpty) ...[
                            _buildSectionHeader(
                              context,
                              title: 'Mendekati Kedaluwarsa',
                              icon: Icons.calendar_month_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              count: productProv.jumlahMendekatiExpired,
                              countColor: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(height: 12),
                            ...productProv.barangMendekatiExpired
                                .take(5)
                                .map((p) => _buildExpiryItem(context, p)),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider auth) {
    return AppBar(
      backgroundColor: context.color.surfaceContainer,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: context.color.outline,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: context.color.onSurface),
          onPressed: () =>
              ctx.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.color.primary, context.color.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Dashboard',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.color.secondary),
            tooltip: 'Refresh data',
            onPressed: () =>
                Provider.of<ProductProvider>(ctx, listen: false).fetchProducts(),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _loadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: context.color.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang 👋',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.nama ?? 'User',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.color.onSurface,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getGreeting(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: auth.isAdmin
                    ? [const Color(0xFF1B2A4A), const Color(0xFF2D4A7A)]
                    : [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (auth.isAdmin
                          ? const Color(0xFF1B2A4A)
                          : AppTheme.success)
                      .withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  user?.roleLabel ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi, semangat bekerja!';
    if (hour < 15) return 'Selamat siang, tetap produktif!';
    if (hour < 18) return 'Selamat sore, hampir selesai!';
    return 'Selamat malam, kerja keras hari ini!';
  }

  Widget _buildSummaryCards(
      BuildContext context, ProductProvider pp, TransactionProvider tp) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      // FIX OVERFLOW: Increase aspect ratio so cards have more vertical space
      childAspectRatio: 1.55,
      children: [
        _summaryCard(
          context,
          icon: Icons.inventory_2_rounded,
          label: 'Total Barang',
          value: '${pp.totalBarang}',
          color: context.color.primary,
          gradient: [const Color(0xFF1B2A4A), const Color(0xFF2D4A7A)],
        ),
        _summaryCard(
          context,
          icon: Icons.warning_amber_rounded,
          label: 'Stok Kritis',
          value: '${pp.jumlahStokKritis}',
          color: AppTheme.error,
          gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          isAlert: pp.jumlahStokKritis > 0,
        ),
        _summaryCard(
          context,
          icon: Icons.calendar_month_rounded,
          label: 'Mendekati Expired',
          value: '${pp.jumlahMendekatiExpired}',
          color: const Color(0xFFF59E0B),
          gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          isAlert: pp.jumlahMendekatiExpired > 0,
        ),
        _summaryCard(
          context,
          icon: Icons.swap_horiz_rounded,
          label: 'Transaksi Hari Ini',
          value: '${tp.totalTransaksiHariIni}',
          color: AppTheme.success,
          gradient: [const Color(0xFF22C55E), const Color(0xFF16A34A)],
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              if (isAlert)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.color.onSurface,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.color.onSurfaceVariant,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner(BuildContext context, ProductProvider pp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perhatian! Barang Mendekati Exp.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pp.jumlahMendekatiExpired} barang akan expired dalam 30 hari ke depan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded,
              color: const Color(0xFFD97706).withValues(alpha: 0.7), size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
    required Color countColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.color.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: countColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: countColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalStockItem(BuildContext context, Product product) {
    final persen = product.stokMinimum > 0
        ? (product.stok / product.stokMinimum).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_rounded,
                color: AppTheme.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nama,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.color.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.sku} • ${product.rakLokasi}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: persen,
                    backgroundColor:
                        AppTheme.error.withValues(alpha: 0.12),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.error),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stok}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.error,
                ),
              ),
              Text(
                'min: ${product.stokMinimum}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: context.color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryItem(BuildContext context, Product product) {
    final sisa = product.sisaHariExpired ?? 0;
    final Color sisaColor = sisa <= 7
        ? AppTheme.error
        : sisa <= 15
            ? const Color(0xFFF59E0B)
            : const Color(0xFF84CC16);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sisaColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: sisaColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded, color: sisaColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nama,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.color.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'EAN ${product.barcode} • ${product.rakLokasi}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.color.onSurfaceVariant,
                  ),
                ),
                if (product.expiredDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Expired: ${_formatDate(product.expiredDate!)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: sisaColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: sisaColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sisaColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$sisa',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: sisaColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  'hari\nlagi',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: sisaColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allSafeState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.06),
            AppTheme.success.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                size: 32, color: AppTheme.success),
          ),
          const SizedBox(height: 12),
          Text(
            'Semua Stok Aman! 🎉',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tidak ada barang di bawah stok minimum.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF22C55E),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.cloud_off_rounded, size: 36, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.color.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.color.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
