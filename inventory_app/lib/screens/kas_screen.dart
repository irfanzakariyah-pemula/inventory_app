// ============================================================
// SCREEN MANAJEMEN KAS (BUKU BESAR KAS)
// ============================================================
// Halaman untuk memantau saldo kas secara real-time,
// mencatat kas masuk/keluar manual (setoran/tarik modal),
// serta menampilkan riwayat aliran dana secara detail.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/kas_provider.dart';
import '../providers/auth_provider.dart';
import '../models/kas_model.dart';

class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'semua'; // 'semua' | 'masuk' | 'keluar'

  @override
  void initState() {
    super.initState();
    // Ambil data kas saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KasProvider>(context, listen: false).fetchTransactions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final kasProv = Provider.of<KasProvider>(context);

    // Ambil daftar transaksi terfilter
    List<KasTransaction> transactions = kasProv.allTransactions;

    // Filter tipe
    if (_selectedFilter != 'semua') {
      transactions = transactions.where((tx) => tx.tipe == _selectedFilter).toList();
    }

    // Filter pencarian
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      transactions = transactions.where((tx) {
        return tx.kategoriLabel.toLowerCase().contains(q) ||
            (tx.keterangan?.toLowerCase().contains(q) ?? false) ||
            tx.userName.toLowerCase().contains(q);
      }).toList();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context),
      body: kasProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: kasProv.fetchTransactions,
              color: context.color.primary,
              child: CustomScrollView(
                slivers: [
                  // 1. HEADER CARD (SALDO KAS)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildSaldoCard(context, kasProv.saldoKas, currencyFmt, isDark),
                    ),
                  ),

                  // 2. SEARCH & FILTER CONTROLS
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildFilters(context),
                    ),
                  ),

                  // 3. LEDGER LIST
                  transactions.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(context),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildLedgerCard(
                                    context, transactions[index], currencyFmt);
                              },
                              childCount: transactions.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: _buildFAB(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.color.surfaceContainer,
      elevation: 0,
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
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)], // Teal gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Buku Kas Toko',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoCard(
      BuildContext context, int saldo, NumberFormat fmt, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // Deep Teal
            Color(0xFF0D9488), // Teal
            Color(0xFF14B8A6), // Light Teal
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                'TOTAL SALDO KAS TOKO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Real-time',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(saldo),
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          Text(
            'Informasi kas mencakup transaksi otomatis dari POS kasir dan pencatatan operasional.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari kategori, keterangan, kasir...',
            hintStyle: GoogleFonts.inter(
                fontSize: 14, color: context.color.onSurfaceVariant),
            prefixIcon:
                Icon(Icons.search_rounded, color: context.color.onSurfaceVariant),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        size: 18, color: context.color.onSurfaceVariant),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),

        // 2. Filter Buttons Row
        Row(
          children: [
            _filterChip(context, label: 'Semua Kas', value: 'semua'),
            const SizedBox(width: 8),
            _filterChip(context, label: 'Kas Masuk', value: 'masuk', icon: Icons.arrow_downward_rounded, color: AppTheme.success),
            const SizedBox(width: 8),
            _filterChip(context, label: 'Kas Keluar', value: 'keluar', icon: Icons.arrow_upward_rounded, color: AppTheme.error),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context,
      {required String label,
      required String value,
      IconData? icon,
      Color? color}) {
    final isSelected = _selectedFilter == value;
    final activeBg = isSelected
        ? (color ?? context.color.primary)
        : context.color.surfaceContainer;
    final activeText = isSelected
        ? Colors.white
        : context.color.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : context.color.outline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: activeText),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: activeText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: context.color.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.color.outline),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 32, color: context.color.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty && _selectedFilter == 'semua'
                  ? 'Belum ada transaksi kas'
                  : 'Transaksi tidak ditemukan',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.color.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtrl.text.isEmpty && _selectedFilter == 'semua'
                  ? 'Gunakan tombol di bawah untuk mencatat kas masuk/keluar manual.'
                  : 'Coba kata kunci atau filter yang berbeda',
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

  Widget _buildLedgerCard(
      BuildContext context, KasTransaction tx, NumberFormat fmt) {
    final isMasuk = tx.tipe == 'masuk';
    final sign = isMasuk ? '+' : '-';
    final color = isMasuk ? AppTheme.success : AppTheme.error;
    final timeStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.color.outline),
      ),
      child: Row(
        children: [
          // 1. Icon Indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Info Detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx.kategoriLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.color.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${tx.userName}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: context.color.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (tx.keterangan != null && tx.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.keterangan!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: context.color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Amount
          Text(
            '$sign ${fmt.format(tx.jumlah)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showManualEntryForm(context),
      backgroundColor: const Color(0xFF0D9488), // Teal color matching kas theme
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Catat Kas Manual',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showManualEntryForm(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final jumlahCtrl = TextEditingController();
    final keteranganCtrl = TextEditingController();
    String selectedTipe = 'masuk'; // 'masuk' | 'keluar'
    String selectedKategori = 'modal'; // 'modal' | 'tarik' | 'lainnya'
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: context.color.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.color.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pencatatan Kas Manual',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tipe Toggle Row
                    Text(
                      'Aliran Dana',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() {
                              selectedTipe = 'masuk';
                              selectedKategori = 'modal';
                            }),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedTipe == 'masuk'
                                    ? AppTheme.success
                                    : context.color.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedTipe == 'masuk'
                                      ? Colors.transparent
                                      : context.color.outline,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward_rounded,
                                      size: 14,
                                      color: selectedTipe == 'masuk'
                                          ? Colors.white
                                          : context.color.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kas Masuk',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selectedTipe == 'masuk'
                                          ? Colors.white
                                          : context.color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() {
                              selectedTipe = 'keluar';
                              selectedKategori = 'tarik';
                            }),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedTipe == 'keluar'
                                    ? AppTheme.error
                                    : context.color.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedTipe == 'keluar'
                                      ? Colors.transparent
                                      : context.color.outline,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward_rounded,
                                      size: 14,
                                      color: selectedTipe == 'keluar'
                                          ? Colors.white
                                          : context.color.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kas Keluar',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selectedTipe == 'keluar'
                                          ? Colors.white
                                          : context.color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kategori Dropdown
                    Text(
                      'Kategori Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.color.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.color.outline),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedKategori,
                          isExpanded: true,
                          dropdownColor: context.color.surfaceContainer,
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedKategori = val);
                            }
                          },
                          items: selectedTipe == 'masuk'
                              ? [
                                  const DropdownMenuItem(
                                      value: 'modal',
                                      child: Text('Setoran Modal Awal')),
                                  const DropdownMenuItem(
                                      value: 'lainnya',
                                      child: Text('Lain-lain')),
                                ]
                              : [
                                  const DropdownMenuItem(
                                      value: 'tarik',
                                      child: Text('Tarik Kas (Prive)')),
                                  const DropdownMenuItem(
                                      value: 'lainnya',
                                      child: Text('Lain-lain')),
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Jumlah Nominal Field
                    TextFormField(
                      controller: jumlahCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Jumlah nominal wajib diisi';
                        }
                        final num = int.tryParse(v);
                        if (num == null || num <= 0) {
                          return 'Jumlah nominal harus angka positif';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Jumlah Nominal (Rp)',
                        hintText: 'Contoh: 500000',
                        prefixIcon: Icon(Icons.attach_money_rounded,
                            color: context.color.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Keterangan Field
                    TextFormField(
                      controller: keteranganCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Keterangan Tambahan (opsional)',
                        hintText: 'Contoh: Tambahan kas awal laci toko',
                        prefixIcon: Icon(Icons.notes_rounded,
                            color: context.color.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);

                          final num = int.parse(jumlahCtrl.text.trim());
                          final success = await Provider.of<KasProvider>(context,
                                  listen: false)
                              .tambahTransaksiKas(
                            tipe: selectedTipe,
                            kategori: selectedKategori,
                            jumlah: num,
                            keterangan: keteranganCtrl.text.trim(),
                            userId: user?.id ?? '',
                            userName: user?.nama ?? 'Kasir',
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                Icon(
                                    success
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: Colors.white,
                                    size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  success
                                      ? 'Kas berhasil dicatat'
                                      : 'Gagal mencatat kas',
                                  style: GoogleFonts.inter(),
                                ),
                              ]),
                              backgroundColor:
                                  success ? AppTheme.success : AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                        child: Text(
                          'Simpan Pencatatan',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
