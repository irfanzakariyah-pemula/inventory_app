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
import 'expired_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: context.color.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final pp = Provider.of<ProductProvider>(context, listen: false);
            final sp = Provider.of<SalesProvider>(context, listen: false);
            await pp.fetchProducts();
            await sp.fetchSales();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──
                _buildHeader(context, user?.nama ?? 'User', isAdmin),
                const SizedBox(height: 24),

                // ── KPI CARDS ──
                _buildKpiCardsRow(context),
                const SizedBox(height: 24),

                // ── GRAFIK PENJUALAN ──
                _buildChartSection(context),
                const SizedBox(height: 24),

                // ── ALERT BANNER ──
                _buildAlertBanner(context),
                const SizedBox(height: 24),

                // ── STOK KRITIS ──
                _buildStokKritisSection(context),
                const SizedBox(height: 24),

                // ── MENDEKATI KEDALUWARSA ──
                _buildExpiredSection(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String nama, bool isAdmin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang 👋',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nama.split(" ").first.toLowerCase(),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.color.onSurface,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Tombol Refresh
            Consumer2<ProductProvider, SalesProvider>(
              builder: (ctx, pp, sp, _) {
                final isRefreshing = pp.isLoading || sp.isLoading;
                return Material(
                  color: context.color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: isRefreshing ? null : () async {
                      await pp.fetchProducts();
                      await sp.fetchSales();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: isRefreshing 
                          ? SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2, 
                                color: context.color.primary,
                              ),
                            )
                          : Icon(Icons.refresh_rounded, size: 20, color: context.color.primary),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            // Badge role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded, size: 14, color: context.color.primary),
                  const SizedBox(width: 6),
                  Text(
                    isAdmin ? 'Administrator' : 'Petugas Gudang',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.color.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCardsRow(BuildContext context) {
    return Consumer2<ProductProvider, SalesProvider>(
      builder: (ctx, productProv, salesProv, _) {
        final products = productProv.allProducts;
        final totalBarang = products.length;
        final stokKritis = products.where((p) => p.isStokKritis).length;
        final mendekatiExpired = products.where((p) => p.isMendekatiExpired || p.isSudahExpired).length;
        final now = DateTime.now();
        final transaksiHarian = salesProv.allSales.where((s) {
          return s.createdAt.year == now.year && s.createdAt.month == now.month && s.createdAt.day == now.day;
        }).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _kpiCard(
              context,
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF3B82F6), // Blue
              iconBgColor: const Color(0xFFEFF6FF),
              value: totalBarang.toString(),
              label: 'Total\nBarang',
            ),
            _kpiCard(
              context,
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444), // Red
              iconBgColor: const Color(0xFFFEF2F2),
              value: stokKritis.toString(),
              label: 'Stok\nKritis',
              valueColor: const Color(0xFFEF4444),
            ),
            _kpiCard(
              context,
              icon: Icons.event_busy_rounded,
              iconColor: const Color(0xFFEF4444), // Red
              iconBgColor: const Color(0xFFFEF2F2),
              value: mendekatiExpired.toString(),
              label: 'Mendekati\nExpired',
              valueColor: const Color(0xFFEF4444),
            ),
            _kpiCard(
              context,
              icon: Icons.swap_horiz_rounded,
              iconColor: const Color(0xFF10B981), // Green
              iconBgColor: const Color(0xFFECFDF5),
              value: transaksiHarian.toString(),
              label: 'Transaksi\nHari Ini',
              valueColor: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40 - 36) / 4, // 4 items, 3 gaps of 12
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? context.color.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: context.color.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (ctx, productProv, _) {
        final expiredCount = productProv.allProducts.where((p) => p.isMendekatiExpired || p.isSudahExpired).length;
        if (expiredCount == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiredListScreen()));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barang Mendekati Kedaluwarsa!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$expiredCount barang akan expired dalam 30 hari ke depan',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB91C1C)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStokKritisSection(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (ctx, productProv, _) {
        final kritisList = productProv.allProducts.where((p) => p.isStokKritis).toList()
          ..sort((a, b) => a.stok.compareTo(b.stok));

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Stok Kritis',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: context.color.onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        kritisList.length.toString(),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)),
                      ),
                    )
                  ],
                ),
                Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.color.onSurfaceVariant),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (kritisList.isEmpty)
              _emptyState(context, 'Tidak ada stok kritis')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kritisList.length > 3 ? 3 : kritisList.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final p = kritisList[index];
                  return _buildStokKritisItem(context, p);
                },
              )
          ],
        );
      },
    );
  }

  Widget _buildStokKritisItem(BuildContext context, Product p) {
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    // Calculate progress ratio
    double ratio = p.stok / p.stokMinimum;
    if (ratio > 1.0) ratio = 1.0;
    if (ratio < 0.0) ratio = 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: context.color.surfaceContainerLow,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: p.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => Icon(Icons.inventory_2_rounded, color: context.color.outline),
                    )
                  : Icon(Icons.inventory_2_rounded, color: context.color.outline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.color.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.kategori} • Rak ${p.rakLokasi}',
                  style: GoogleFonts.inter(fontSize: 11, color: context.color.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 4,
                          backgroundColor: context.color.outlineVariant.withValues(alpha: 0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24), // Space before numbers
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.stok.toString(),
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
              ),
              Text(
                'min: ${p.stokMinimum}',
                style: GoogleFonts.inter(fontSize: 10, color: context.color.onSurfaceVariant),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildExpiredSection(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (ctx, productProv, _) {
        final expiredList = productProv.allProducts.where((p) => p.isMendekatiExpired || p.isSudahExpired).toList()
          ..sort((a, b) => (a.sisaHariExpired ?? 999).compareTo(b.sisaHariExpired ?? 999));

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Mendekati Kedaluwarsa',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: context.color.onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        expiredList.length.toString(),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)),
                      ),
                    )
                  ],
                ),
                GestureDetector(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiredListScreen()));
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.color.onSurfaceVariant),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (expiredList.isEmpty)
              _emptyState(context, 'Aman! Tidak ada produk hampir expired.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expiredList.length > 3 ? 3 : expiredList.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final p = expiredList[index];
                  return _buildExpiredItem(context, p);
                },
              )
          ],
        );
      },
    );
  }

  Widget _buildExpiredItem(BuildContext context, Product p) {
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    final isExpired = p.isSudahExpired;
    final sisaHari = p.sisaHariExpired ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: context.color.surfaceContainerLow,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: p.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => Icon(Icons.inventory_2_rounded, color: context.color.outline),
                    )
                  : Icon(Icons.inventory_2_rounded, color: context.color.outline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.color.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'EAN ${p.barcode} • Rak ${p.rakLokasi}',
                  style: GoogleFonts.inter(fontSize: 11, color: context.color.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  isExpired 
                    ? 'EXPIRED: ${DateFormat('dd MMM yyyy').format(p.expiredDate!)}'
                    : 'Expired: ${DateFormat('dd MMM yyyy').format(p.expiredDate!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    fontWeight: isExpired ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExpired ? 'EXPIRED' : sisaHari.toString(),
                style: GoogleFonts.inter(
                  fontSize: isExpired ? 14 : 18, 
                  fontWeight: FontWeight.w800, 
                  color: const Color(0xFFEF4444)
                ),
              ),
              if (!isExpired)
                Text(
                  'hari lagi',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFDC2626)),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13, color: context.color.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (ctx, salesProv, _) {
        final data = salesProv.omset7Hari.reversed.toList(); // kiri ke kanan: terlama ke terbaru

        double maxTotal = 0;
        for (var d in data) {
          if (d['total'] > maxTotal) {
            maxTotal = d['total'].toDouble();
          }
        }
        
        maxTotal = maxTotal * 1.2; // Tambahkan ruang kosong di atas
        if (maxTotal == 0) maxTotal = 1000;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Omset 7 Hari Terakhir',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: context.color.onSurface),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxTotal,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => context.color.primary,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(rod.toY)}',
                            GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 || value.toInt() >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[value.toInt()]['label'],
                                style: GoogleFonts.inter(
                                  color: context.color.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxTotal == 0 ? 100 : (maxTotal / 4),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: context.color.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: data.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value['total'].toDouble(),
                            color: context.color.primary,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxTotal,
                              color: context.color.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
