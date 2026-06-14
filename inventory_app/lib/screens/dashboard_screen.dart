import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../models/product_model.dart';

// Import Screens untuk Grid Menu
import 'pos_screen.dart';
import 'product_list_screen.dart';
import 'stock_update_screen.dart';
import 'transaction_log_screen.dart';
import 'report_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final salesProv = Provider.of<SalesProvider>(context);
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: context.color.surface,
      body: SafeArea(
        child: productProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: context.color.primary,
                backgroundColor: context.color.surfaceContainer,
                onRefresh: () async {
                  await Future.wait([
                    productProv.fetchProducts(),
                    salesProv.fetchSales(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TOP BAR (Help & Theme) ──
                      _buildTopBar(context),
                      const SizedBox(height: 24),

                      // ── HEADER GREETING ──
                      Text(
                        'Hi ${user?.nama?.split(" ").first ?? 'User'}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.color.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── SUMMARY CARD (Omset & Transaksi) ──
                      _buildSummaryCard(context, salesProv),
                      const SizedBox(height: 28),

                      // ── GRID MENU (Book and explore style) ──
                      Text(
                        'Akses Cepat',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGridMenu(context, isAdmin),
                      const SizedBox(height: 32),

                      // ── HORIZONTAL CARDS (Stok Kritis) ──
                      if (productProv.stokKritis.isNotEmpty) ...[
                        Text(
                          'Stok Kritis Perlu Perhatian',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCriticalStockHorizontal(context, productProv.stokKritis),
                        const SizedBox(height: 32),
                      ],

                      // ── TOP PRODUCTS (Make your trip complete style) ──
                      if (salesProv.top5Terlaris.isNotEmpty) ...[
                        Text(
                          'Produk Terlaris Bulan Ini',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTopProductsHorizontal(context, salesProv.top5Terlaris),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Bantuan Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.color.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.color.outline.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 16, color: context.color.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Bantuan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.color.onSurface,
                ),
              ),
            ],
          ),
        ),
        // Switch Theme Button (Mirip Card Button merah)
        GestureDetector(
          onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.color.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.color.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tema',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

  Widget _buildSummaryCard(BuildContext context, SalesProvider sp) {
    final fmtRp = NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: context.color.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Omset (Sisi Kiri)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Omset Hari Ini',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmtRp.format(sp.omsetHariIni),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.color.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 40,
            width: 1,
            color: context.color.outline,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Transaksi (Sisi Kanan)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${sp.jumlahTransaksiHariIni}',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.color.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.color.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_upward_rounded,
                        size: 14, color: context.color.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context, bool isAdmin) {
    List<Map<String, dynamic>> menuItems = [];

    if (isAdmin) {
      menuItems = [
        {'title': 'Kasir', 'icon': Icons.point_of_sale_rounded, 'screen': const PosScreen()},
        {'title': 'Barang', 'icon': Icons.inventory_2_rounded, 'screen': const ProductListScreen()},
        {'title': 'Laporan', 'icon': Icons.bar_chart_rounded, 'screen': const ReportScreen()},
        {'title': 'Log Stok', 'icon': Icons.receipt_long_rounded, 'screen': const TransactionLogScreen()},
        {'title': 'Update Stok', 'icon': Icons.qr_code_scanner_rounded, 'screen': const StockUpdateScreen()},
      ];
    } else {
      menuItems = [
        {'title': 'Kasir', 'icon': Icons.point_of_sale_rounded, 'screen': const PosScreen()},
        {'title': 'Update Stok', 'icon': Icons.qr_code_scanner_rounded, 'screen': const StockUpdateScreen()},
        {'title': 'Log Stok', 'icon': Icons.receipt_long_rounded, 'screen': const TransactionLogScreen()},
      ];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item['screen'] as Widget),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.color.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: context.color.outline.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: context.color.primary, // Ikon merah
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.color.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCriticalStockHorizontal(BuildContext context, List<ProductModel> kritis) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kritis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = kritis[index];
          return Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.color.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: context.color.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // Icon / Indikator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.color.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: context.color.error),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.nama,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.color.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sisa Stok: ${p.stok} ${p.satuan}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.color.error,
                        ),
                      ),
                      Text(
                        'Batas Minimum: ${p.stokMinimum}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: context.color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopProductsHorizontal(BuildContext context, List<Map<String, dynamic>> topProducts) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = topProducts[index];
          return Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.color.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.color.outline.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                // Rank number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.color.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.color.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['nama'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.color.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 10, color: context.color.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${item['jumlahTerjual']} terjual',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: context.color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
