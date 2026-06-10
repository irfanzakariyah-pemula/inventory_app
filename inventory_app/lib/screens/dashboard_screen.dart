// ============================================================
// DASHBOARD SCREEN — Fase B Upgrade
// ============================================================
// Berisi:
//   [1] 4 Kartu KPI Live: Omset Hari Ini, Transaksi, Profit, Stok Kritis
//   [2] Bar Chart: Omset 7 Hari Terakhir (via fl_chart)
//   [3] List Top 5 Produk Terlaris
//   [4] Bagian Stok Kritis & Mendekati Expired (dari sebelumnya)
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../models/product_model.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final salesProv = Provider.of<SalesProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context, auth, salesProv),
      body: SafeArea(
        child: productProv.isLoading
            ? _loadingState(context)
            : productProv.errorMessage != null
                ? _errorState(context, productProv.errorMessage!)
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
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, auth, user),
                          const SizedBox(height: 20),

                          // ── KPI CARDS ──────────────────────────────────────
                          _buildKpiCards(context, productProv, salesProv),
                          const SizedBox(height: 24),

                          // ── BAR CHART: OMSET 7 HARI ─────────────────────
                          _buildChartSection(context, salesProv),
                          const SizedBox(height: 24),

                          // ── TOP 5 TERLARIS ──────────────────────────────
                          if (salesProv.top5Terlaris.isNotEmpty) ...[
                            _buildTopProducts(context, salesProv),
                            const SizedBox(height: 24),
                          ],

                          // ── EXPIRY BANNER ──────────────────────────────
                          if (productProv.jumlahMendekatiExpired > 0) ...[
                            _buildExpiryBanner(context, productProv),
                            const SizedBox(height: 20),
                          ],

                          // ── STOK KRITIS ─────────────────────────────────
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

                          // ── MENDEKATI EXPIRED ────────────────────────────
                          if (productProv.barangMendekatiExpired.isNotEmpty ||
                              productProv.barangSudahExpired.isNotEmpty) ...[
                            const SizedBox(height: 20),
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

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AuthProvider auth, SalesProvider salesProv) {
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
            onPressed: () {
              Provider.of<ProductProvider>(ctx, listen: false).fetchProducts();
              Provider.of<SalesProvider>(ctx, listen: false).fetchSales();
            },
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // HEADER (Greeting)
  // ============================================================

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
                const Icon(Icons.person_rounded, color: Colors.white, size: 14),
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

  // ============================================================
  // [1] KPI CARDS (4 kartu live)
  // ============================================================

  Widget _buildKpiCards(
      BuildContext context, ProductProvider pp, SalesProvider sp) {
    final fmtRp = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _kpiCard(
          context,
          icon: Icons.attach_money_rounded,
          label: 'Omset Hari Ini',
          value: fmtRp.format(sp.omsetHariIni),
          gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          color: const Color(0xFF3B82F6),
        ),
        _kpiCard(
          context,
          icon: Icons.receipt_rounded,
          label: 'Transaksi Hari Ini',
          value: '${sp.jumlahTransaksiHariIni} struk',
          gradient: [const Color(0xFF22C55E), const Color(0xFF16A34A)],
          color: AppTheme.success,
        ),
        _kpiCard(
          context,
          icon: Icons.trending_up_rounded,
          label: 'Profit Hari Ini',
          value: fmtRp.format(sp.profitHariIni),
          gradient: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
          color: const Color(0xFF8B5CF6),
          isAlert: sp.profitHariIni == 0 && sp.jumlahTransaksiHariIni == 0,
        ),
        _kpiCard(
          context,
          icon: Icons.warning_amber_rounded,
          label: 'Stok Kritis',
          value: '${pp.jumlahStokKritis} barang',
          gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          color: AppTheme.error,
          isAlert: pp.jumlahStokKritis > 0,
        ),
      ],
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
    required Color color,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
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
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 5,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.color.onSurface,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
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

  // ============================================================
  // [2] BAR CHART — Omset 7 Hari Terakhir
  // ============================================================

  Widget _buildChartSection(BuildContext context, SalesProvider sp) {
    final data = sp.omset7Hari;
    final maxVal = data.map((d) => d['total'] as int).fold(0, (a, b) => a > b ? a : b);
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: Color(0xFF3B82F6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Omset 7 Hari Terakhir',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.color.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                _fmtCompact(sp.omsetBulanIni),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bulan ini: ${_fmtCompact(sp.omsetBulanIni)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: context.color.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 160,
            child: maxVal == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart_rounded,
                            size: 36,
                            color: context.color.onSurfaceVariant
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada transaksi dalam 7 hari',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.25,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => isDark
                              ? const Color(0xFF1E3A5F)
                              : const Color(0xFF1B2A4A),
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          tooltipMargin: 6,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = data[group.x]['label'] as String;
                            final val = rod.toY.toInt();
                            return BarTooltipItem(
                              '$day\n',
                              GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: _fmtCompact(val),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            interval: maxVal > 0 ? (maxVal * 1.25 / 4) : 1,
                            getTitlesWidget: (value, meta) => Text(
                              _fmtCompact(value.toInt()),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= data.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data[idx]['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: context.color.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal > 0 ? (maxVal * 1.25 / 4) : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: context.color.outline.withValues(alpha: 0.4),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (i) {
                        final total = (data[i]['total'] as int).toDouble();
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: total,
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                              gradient: LinearGradient(
                                colors: total > 0
                                    ? [
                                        const Color(0xFF60A5FA),
                                        const Color(0xFF3B82F6),
                                        const Color(0xFF1D4ED8),
                                      ]
                                    : [
                                        context.color.outline.withValues(alpha: 0.3),
                                        context.color.outline.withValues(alpha: 0.2),
                                      ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // [3] TOP 5 PRODUK TERLARIS
  // ============================================================

  Widget _buildTopProducts(BuildContext context, SalesProvider sp) {
    final top = sp.top5Terlaris;
    final maxQty = top.isNotEmpty
        ? (top.first['jumlahTerjual'] as int).toDouble()
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFF8B5CF6), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Top 5 Produk Terlaris',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.color.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(top.length, (i) {
            final item = top[i];
            final nama = item['nama'] as String;
            final qty = item['jumlahTerjual'] as int;
            final ratio = maxQty > 0 ? qty / maxQty : 0.0;

            final medalColors = [
              const Color(0xFFF59E0B), // Gold
              const Color(0xFF94A3B8), // Silver
              const Color(0xFFCD7C3C), // Bronze
            ];
            final barColors = [
              [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
              [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              [const Color(0xFF22C55E), const Color(0xFF16A34A)],
              [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i < 3
                          ? medalColors[i].withValues(alpha: 0.15)
                          : context.color.outline.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: i < 3
                          ? Icon(Icons.emoji_events_rounded,
                              size: 14, color: medalColors[i])
                          : Text(
                              '${i + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + progress bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                nama,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.color.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$qty ${item['satuan'] ?? 'pcs'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: barColors[i % barColors.length].first,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor:
                                barColors[i % barColors.length].first
                                    .withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              barColors[i % barColors.length].first,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // EXISTING WIDGETS (dipertahankan dari sebelumnya)
  // ============================================================

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
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.08)),
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
          // Thumbnail produk — gambar atau ikon fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.error.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.error,
                        size: 22,
                      ),
                    )
                  : Icon(Icons.inventory_2_rounded,
                      color: AppTheme.error, size: 22),
            ),
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
                    backgroundColor: AppTheme.error.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.error),
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
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sisaColor.withValues(alpha: 0.12)),
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
          // Thumbnail produk — gambar atau ikon fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sisaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: sisaColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Icon(
                        Icons.calendar_month_rounded,
                        color: sisaColor,
                        size: 22,
                      ),
                    )
                  : Icon(Icons.calendar_month_rounded,
                      color: sisaColor, size: 22),
            ),
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
              border: Border.all(color: sisaColor.withValues(alpha: 0.2)),
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
              child: Icon(Icons.cloud_off_rounded,
                  size: 36, color: AppTheme.error),
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

  // ============================================================
  // HELPERS
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi, semangat bekerja!';
    if (hour < 15) return 'Selamat siang, tetap produktif!';
    if (hour < 18) return 'Selamat sore, hampir selesai!';
    return 'Selamat malam, kerja keras hari ini!';
  }

  String _fmtCompact(int value) {
    if (value >= 1000000000) return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    return 'Rp $value';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
