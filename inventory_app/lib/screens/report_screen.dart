// ============================================================
// LAPORAN SCREEN — Fase B
// ============================================================
// 3 Tab:
//   [1] Ringkasan   → KPI per periode (hari/minggu/bulan)
//   [2] Transaksi   → Daftar struk expandable + detail item
//   [3] Terlaris    → Top produk dengan progress bar
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sales_provider.dart';
import '../models/sales_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriode = 'bulan'; // 'hari' | 'minggu' | 'bulan'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Format helpers ────────────────────────────────────────────

  final _fmtRp = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _fmtRpCompact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _fmtTgl(DateTime dt) {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(dt.toLocal());
  }

  String _periodeLabel() {
    switch (_selectedPeriode) {
      case 'hari':
        return 'Hari Ini';
      case 'minggu':
        return '7 Hari Terakhir';
      default:
        return 'Bulan Ini';
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<SalesProvider>(context);

    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context, sp),
      body: sp.isLoading
          ? _loadingState(context)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRingkasan(context, sp),
                _buildTransaksi(context, sp),
                _buildTerlaris(context, sp),
              ],
            ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, SalesProvider sp) {
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
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Laporan',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: const Color(0xFF8B5CF6)),
          tooltip: 'Refresh',
          onPressed: () =>
              Provider.of<SalesProvider>(context, listen: false).fetchSales(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: context.color.onSurfaceVariant,
        indicatorColor: const Color(0xFF8B5CF6),
        indicatorWeight: 2.5,
        labelStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Ringkasan'),
          Tab(text: 'Transaksi'),
          Tab(text: 'Terlaris'),
        ],
      ),
    );
  }

  // ============================================================
  //  TAB 1 — RINGKASAN
  // ============================================================

  Widget _buildRingkasan(BuildContext context, SalesProvider sp) {
    final sales = sp.getSalesByPeriode(_selectedPeriode);
    final totalOmset = sp.getTotalOmset(sales);
    final totalProfit = sp.getTotalProfit(sales);
    final jumlah = sales.length;
    final rata = jumlah > 0 ? totalOmset ~/ jumlah : 0;

    return RefreshIndicator(
      color: const Color(0xFF8B5CF6),
      backgroundColor: context.color.surfaceContainer,
      onRefresh: () => sp.fetchSales(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Periode selector ────────────────────────────
            _buildPeriodeSelector(context),
            const SizedBox(height: 20),

            // ── Judul ───────────────────────────────────────
            Row(
              children: [
                Text(
                  'Ringkasan — ${_periodeLabel()}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$jumlah struk',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── KPI Grid ────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _kpiCard(
                  context,
                  label: 'Total Omset',
                  value: _fmtRpCompact.format(totalOmset),
                  icon: Icons.attach_money_rounded,
                  gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                ),
                _kpiCard(
                  context,
                  label: 'Total Profit',
                  value: _fmtRpCompact.format(totalProfit),
                  icon: Icons.trending_up_rounded,
                  gradient: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                ),
                _kpiCard(
                  context,
                  label: 'Jumlah Struk',
                  value: '$jumlah transaksi',
                  icon: Icons.receipt_rounded,
                  gradient: [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                ),
                _kpiCard(
                  context,
                  label: 'Rata-rata / Struk',
                  value: _fmtRpCompact.format(rata),
                  icon: Icons.equalizer_rounded,
                  gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Perbandingan Omset vs Profit ────────────────
            if (jumlah > 0) ...[
              _buildOmsetProfitComparison(context, totalOmset, totalProfit),
              const SizedBox(height: 24),
            ],

            // ── Breakdown metode bayar ──────────────────────
            if (jumlah > 0) _buildMethodBreakdown(context, sales),

            // ── Empty state ─────────────────────────────────
            if (jumlah == 0) _emptyState(context, _periodeLabel()),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeSelector(BuildContext context) {
    final options = [
      ('hari', 'Hari Ini'),
      ('minggu', '7 Hari'),
      ('bulan', 'Bulan Ini'),
    ];
    return Row(
      children: options.map((opt) {
        final isSelected = _selectedPeriode == opt.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: opt.$1 != 'bulan' ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriode = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : context.color.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : context.color.outline.withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    opt.$2,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : context.color.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
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
              const SizedBox(height: 2),
              Text(
                label,
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

  Widget _buildOmsetProfitComparison(
      BuildContext context, int omset, int profit) {
    final marginPct =
        omset > 0 ? (profit / omset * 100).toStringAsFixed(1) : '0.0';
    final ratio = omset > 0 ? (profit / omset).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Margin Keuntungan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.color.onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$marginPct%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _barLabel(context, 'Omset', omset, const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _barLabel(context, 'Profit', profit, AppTheme.success),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barLabel(
      BuildContext context, String label, int value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: context.color.onSurfaceVariant)),
              Text(
                _fmtRpCompact.format(value),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.color.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBreakdown(
      BuildContext context, List<SalesTransaction> sales) {
    final Map<String, int> byMethod = {};
    for (final s in sales) {
      byMethod[s.metodeBayar] = (byMethod[s.metodeBayar] ?? 0) + s.total;
    }
    final total = byMethod.values.fold(0, (a, b) => a + b);

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF22C55E),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown Metode Bayar',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ...byMethod.entries.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final method = entry.value.key;
            final val = entry.value.value;
            final pct = total > 0 ? val / total : 0.0;
            final color = colors[idx % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            method.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.color.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}% — ${_fmtRpCompact.format(val)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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
  //  TAB 2 — RIWAYAT TRANSAKSI
  // ============================================================

  Widget _buildTransaksi(BuildContext context, SalesProvider sp) {
    final sales = sp.getSalesByPeriode(_selectedPeriode);

    return RefreshIndicator(
      color: const Color(0xFF8B5CF6),
      backgroundColor: context.color.surfaceContainer,
      onRefresh: () => sp.fetchSales(),
      child: sales.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: _emptyState(context, _periodeLabel()),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: sales.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPeriodeSelector(context),
                  );
                }
                final sale = sales[i - 1];
                return _TransactionCard(
                  sale: sale,
                  fmtRp: _fmtRp,
                  fmtTgl: _fmtTgl,
                );
              },
            ),
    );
  }

  // ============================================================
  //  TAB 3 — TERLARIS
  // ============================================================

  Widget _buildTerlaris(BuildContext context, SalesProvider sp) {
    final top = sp.top5Terlaris;

    return RefreshIndicator(
      color: const Color(0xFF8B5CF6),
      backgroundColor: context.color.surfaceContainer,
      onRefresh: () => sp.fetchSales(),
      child: top.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: _emptyState(context, 'periode ini'),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Top Produk Terlaris',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.color.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Berdasarkan data penjualan 30 hari terakhir',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Podium (top 3)
                  if (top.length >= 3) ...[
                    _buildPodium(context, top),
                    const SizedBox(height: 20),
                  ],

                  // Full list
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.color.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(top.length, (i) {
                        final item = top[i];
                        final nama = item['nama'] as String;
                        final qty = item['jumlahTerjual'] as int;
                        final maxQty =
                            (top.first['jumlahTerjual'] as int).toDouble();
                        final ratio = maxQty > 0 ? qty / maxQty : 0.0;

                        final barColors = [
                          [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                          [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                          [const Color(0xFFCD9158), const Color(0xFFB87333)],
                          [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                          [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                        ];
                        final barColor =
                            barColors[i % barColors.length].first;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '#${i + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: i == 0
                                          ? const Color(0xFFF59E0B)
                                          : i == 1
                                              ? const Color(0xFF94A3B8)
                                              : i == 2
                                                  ? const Color(0xFFCD9158)
                                                  : context
                                                      .color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            nama,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
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
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: barColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 7,
                                        backgroundColor: barColor
                                            .withValues(alpha: 0.12),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                barColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPodium(
      BuildContext context, List<Map<String, dynamic>> top) {
    final heights = [100.0, 75.0, 60.0]; // 1st, 2nd, 3rd
    final order = [1, 0, 2]; // Silver, Gold, Bronze order on screen
    final podiumColors = [
      const Color(0xFF94A3B8), // 2nd (silver, left)
      const Color(0xFFF59E0B), // 1st (gold, center)
      const Color(0xFFCD9158), // 3rd (bronze, right)
    ];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.06),
            const Color(0xFF6D28D9).withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((rankIdx) {
          final screenIdx = order.indexOf(rankIdx);
          final item = top[rankIdx];
          final nama = item['nama'] as String;
          final qty = item['jumlahTerjual'] as int;
          final color = podiumColors[screenIdx];
          final height = heights[rankIdx];

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Medal icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      rankIdx == 0
                          ? '🥇'
                          : rankIdx == 1
                              ? '🥈'
                              : '🥉',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    nama,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: context.color.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$qty ${item['satuan'] ?? 'pcs'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                // Podium block
                Container(
                  width: double.infinity,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.7),
                        color,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      '#${rankIdx + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────

  Widget _loadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: const Color(0xFF8B5CF6),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat laporan...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 38, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Transaksi',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada data untuk $label',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  TRANSACTION CARD (Expandable)
// ============================================================

class _TransactionCard extends StatefulWidget {
  final SalesTransaction sale;
  final NumberFormat fmtRp;
  final String Function(DateTime) fmtTgl;

  const _TransactionCard({
    required this.sale,
    required this.fmtRp,
    required this.fmtTgl,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _expanded = false;

  Color get _methodColor {
    switch (widget.sale.metodeBayar.toLowerCase()) {
      case 'cash':
      case 'tunai':
        return AppTheme.success;
      case 'qris':
        return const Color(0xFF8B5CF6);
      case 'debit':
      case 'kredit':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_rounded,
                        color: AppTheme.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.nomorStruk ?? 'Tanpa Nomor',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.fmtTgl(sale.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    _methodColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sale.metodeBayar.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _methodColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Total + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.fmtRp.format(sale.total),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sale.items.length} item',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: context.color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.color.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded items ───────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color:
                          context.color.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                children: [
                  // Item list
                  ...sale.items.map((item) => Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.namaProduk,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.color.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${item.jumlah} ${item.satuan} ×',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.fmtRp.format(item.subtotal),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.color.onSurface,
                              ),
                            ),
                          ],
                        ),
                      )),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      children: [
                        Divider(
                            color: context.color.outline
                                .withValues(alpha: 0.2)),
                        _receiptRow(context, 'Subtotal',
                            widget.fmtRp.format(sale.subtotal)),
                        if (sale.diskon > 0)
                          _receiptRow(
                              context,
                              'Diskon',
                              '- ${widget.fmtRp.format(sale.diskon)}',
                              color: AppTheme.error),
                        _receiptRow(
                            context,
                            'TOTAL',
                            widget.fmtRp.format(sale.total),
                            bold: true,
                            color: AppTheme.success),
                        _receiptRow(context, 'Bayar',
                            widget.fmtRp.format(sale.bayar)),
                        _receiptRow(context, 'Kembalian',
                            widget.fmtRp.format(sale.kembalian)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 12,
                                color: context.color.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              sale.userName,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: bold ? 13 : 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color ?? context.color.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: bold ? 13 : 11,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? context.color.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
