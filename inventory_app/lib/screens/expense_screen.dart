// ============================================================
// SCREEN BIAYA OPERASIONAL (EXPENSES)
// ============================================================
// Halaman untuk mencatat pengeluaran operasional toko,
// melihat distribusi biaya berdasarkan kategori belanja,
// serta memantau riwayat pengeluaran secara terorganisir.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../models/expense_model.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'semua'; // 'semua' | 'hari' | 'minggu' | 'bulan'

  @override
  void initState() {
    super.initState();
    // Ambil data pengeluaran saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expProv = Provider.of<ExpenseProvider>(context);

    // Ambil daftar pengeluaran terfilter periode
    List<Expense> expenses = expProv.getExpensesByPeriodString(_selectedFilter);

    // Filter pencarian
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      expenses = expenses.where((exp) {
        return exp.kategoriLabel.toLowerCase().contains(q) ||
            (exp.keterangan?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Hitung total pengeluaran terfilter
    final int totalBiayaFilter = expenses.fold(0, (sum, exp) => sum + exp.jumlah);

    // Hitung distribusi biaya per kategori
    final Map<String, int> biayaPerKategori = {};
    for (final exp in expenses) {
      biayaPerKategori[exp.kategori] = (biayaPerKategori[exp.kategori] ?? 0) + exp.jumlah;
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context),
      body: expProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: expProv.fetchExpenses,
              color: context.color.primary,
              child: CustomScrollView(
                slivers: [
                  // 1. TOTAL BIAYA CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildTotalCard(context, totalBiayaFilter, currencyFmt),
                    ),
                  ),

                  // 2. VISUALISASI KATEGORI (BREAKDOWN CHART)
                  if (expenses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildCategoryBreakdown(context, totalBiayaFilter, biayaPerKategori, currencyFmt),
                      ),
                    ),

                  // 3. SEARCH & PERIOD FILTERS
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildFilters(context),
                    ),
                  ),

                  // 4. LIST RIWAYAT BIAYA
                  expenses.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(context),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildExpenseCard(context, expenses[index], currencyFmt);
                              },
                              childCount: expenses.length,
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
                colors: [Color(0xFFE11D48), Color(0xFFF43F5E)], // Rose gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Biaya Operasional',
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

  Widget _buildTotalCard(BuildContext context, int total, NumberFormat fmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFBE123C), // Deep Rose
            Color(0xFFE11D48), // Rose
            Color(0xFFFB7185), // Light Rose
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: context.isDarkMode ? 0.3 : 0.25),
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
                'TOTAL PENGELUARAN BIAYA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                _selectedFilter == 'semua'
                    ? 'Semua Waktu'
                    : (_selectedFilter == 'hari'
                        ? 'Hari Ini'
                        : (_selectedFilter == 'minggu' ? 'Minggu Ini' : 'Bulan Ini')),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(total),
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
            'Mencatat biaya operasional akan mengurangkan saldo kas toko secara otomatis.',
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

  Widget _buildCategoryBreakdown(BuildContext context, int total,
      Map<String, int> categories, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.color.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Biaya Operasional',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.entries.map((entry) {
            final double percent = total > 0 ? entry.value / total : 0;
            final catLabel = _getKategoriLabel(entry.key);
            final catColor = _getKategoriColor(entry.key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            catLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.color.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${fmt.format(entry.value)} (${(percent * 100).toStringAsFixed(1)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.color.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: context.color.outline.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      minHeight: 8,
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

  Widget _buildFilters(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari kategori atau keterangan biaya...',
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
            _filterChip(context, label: 'Semua', value: 'semua'),
            const SizedBox(width: 6),
            _filterChip(context, label: 'Hari Ini', value: 'hari'),
            const SizedBox(width: 6),
            _filterChip(context, label: 'Minggu Ini', value: 'minggu'),
            const SizedBox(width: 6),
            _filterChip(context, label: 'Bulan Ini', value: 'bulan'),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context,
      {required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    final activeBg = isSelected
        ? context.color.primary
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
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: activeText,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              child: Icon(Icons.receipt_outlined,
                  size: 32, color: context.color.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Belum ada pencatatan biaya'
                  : 'Biaya tidak ditemukan',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.color.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Gunakan tombol di bawah untuk mencatat pengeluaran operasional baru.'
                  : 'Coba kata kunci atau filter periode yang berbeda',
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

  Widget _buildExpenseCard(
      BuildContext context, Expense exp, NumberFormat fmt) {
    final catColor = _getKategoriColor(exp.kategori);
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(exp.tanggal);

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
          // Indicator Left Border Color
          Container(
            width: 5,
            height: 38,
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exp.kategoriLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.color.onSurface,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (exp.keterangan != null && exp.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    exp.keterangan!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Amount
          Text(
            fmt.format(exp.jumlah),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.color.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddExpenseForm(context),
      backgroundColor: const Color(0xFFE11D48), // Rose pink matching expenses
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Catat Biaya Baru',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showAddExpenseForm(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final jumlahCtrl = TextEditingController();
    final keteranganCtrl = TextEditingController();
    String selectedKategori = 'operasional';
    DateTime selectedDate = DateTime.now();
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
                      'Pencatatan Biaya Baru',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.color.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kategori Biaya
                    Text(
                      'Kategori Biaya',
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
                          items: const [
                            DropdownMenuItem(
                                value: 'listrik',
                                child: Text('Listrik & Air')),
                            DropdownMenuItem(
                                value: 'gaji',
                                child: Text('Gaji Karyawan')),
                            DropdownMenuItem(
                                value: 'sewa',
                                child: Text('Sewa Tempat')),
                            DropdownMenuItem(
                                value: 'transportasi',
                                child: Text('Transportasi / Bensin')),
                            DropdownMenuItem(
                                value: 'operasional',
                                child: Text('Operasional Toko')),
                            DropdownMenuItem(
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
                        hintText: 'Contoh: 150000',
                        prefixIcon: Icon(Icons.attach_money_rounded,
                            color: context.color.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Biaya
                    Text(
                      'Tanggal Pembayaran',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                      primary: const Color(0xFFE11D48),
                                    ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: context.color.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.color.outline),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate),
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Icon(Icons.calendar_month_rounded,
                                color: context.color.onSurfaceVariant, size: 20),
                          ],
                        ),
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
                        hintText: 'Contoh: Bayar air PAM bulan Mei',
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
                          final success = await Provider.of<ExpenseProvider>(context,
                                  listen: false)
                              .tambahPengeluaran(
                            kategori: selectedKategori,
                            jumlah: num,
                            keterangan: keteranganCtrl.text.trim(),
                            tanggal: selectedDate,
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
                                      ? 'Biaya berhasil dicatat dan kas terpotong'
                                      : 'Gagal mencatat pengeluaran',
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
                          backgroundColor: const Color(0xFFE11D48),
                        ),
                        child: Text(
                          'Simpan Pengeluaran',
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

  // ==================== HELPERS ====================

  String _getKategoriLabel(String key) {
    switch (key) {
      case 'listrik':
        return 'Listrik & Air';
      case 'gaji':
        return 'Gaji Karyawan';
      case 'sewa':
        return 'Sewa Tempat';
      case 'transportasi':
        return 'Transportasi / Bensin';
      case 'operasional':
        return 'Operasional Toko';
      case 'lainnya':
      default:
        return 'Lain-lain';
    }
  }

  Color _getKategoriColor(String key) {
    switch (key) {
      case 'listrik':
        return const Color(0xFFF59E0B); // Amber
      case 'gaji':
        return const Color(0xFF8B5CF6); // Violet
      case 'sewa':
        return const Color(0xFF3B82F6); // Blue
      case 'transportasi':
        return const Color(0xFF10B981); // Emerald
      case 'operasional':
        return const Color(0xFF06B6D4); // Cyan
      case 'lainnya':
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
