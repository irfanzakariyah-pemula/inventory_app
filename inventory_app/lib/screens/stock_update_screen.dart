import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

/// ============================================================
/// HALAMAN UPDATE STOK - Stok Masuk & Keluar (Petugas & Admin)
/// ============================================================
/// Fitur:
///  - Cari & pilih produk (search bar + dropdown)
///  - Preview info produk yang dipilih (stok, lokasi, harga)
///  - Pilih tipe: Stok Masuk atau Stok Keluar
///  - Input jumlah dengan validasi stok tidak negatif
///  - Catat catatan/keterangan transaksi (opsional)
///  - Otomatis mencatat log transaksi ke Supabase
/// ============================================================
class StockUpdateScreen extends StatefulWidget {
  const StockUpdateScreen({super.key});

  @override
  State<StockUpdateScreen> createState() => _StockUpdateScreenState();
}

class _StockUpdateScreenState extends State<StockUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  Product? _selectedProduct;
  TransactionType _transType = TransactionType.masuk;
  bool _isUpdating = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _catatanCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_isUpdating) return;
    if (_selectedProduct == null) {
      _showSnackBar('Pilih barang terlebih dahulu', Colors.orange.shade600);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final jumlah = int.parse(_jumlahCtrl.text.trim());

    // Cek validasi stok keluar tidak negatif secara lokal dulu
    if (_transType == TransactionType.keluar &&
        _selectedProduct!.stok - jumlah < 0) {
      setState(() => _isUpdating = false);
      _showSnackBar(
          'Gagal! Stok saat ini (${_selectedProduct!.stok}) tidak cukup.',
          Colors.red.shade600);
      return;
    }

    final success = await productProv.updateStock(
      productId: _selectedProduct!.id,
      jumlah: jumlah,
      type: _transType,
      userId: auth.currentUser!.id,
      userName: auth.currentUser!.nama,
      catatan: _catatanCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      // Reset form
      _jumlahCtrl.clear();
      _catatanCtrl.clear();
      setState(() => _selectedProduct = null);
      _showSnackBar('Stok berhasil diperbarui! ✅', AppTheme.success);
    } else {
      _showSnackBar('Gagal memperbarui stok. Coba lagi.', Colors.red.shade600);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: AppBar(
        backgroundColor: context.color.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: context.color.onSurface),
            onPressed: () =>
                ctx.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Stok',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface)),
            Text('Catat perubahan stok masuk / keluar',
                style: GoogleFonts.inter(
                    fontSize: 11, color: context.color.onSurfaceVariant)),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ====== PILIH TIPE TRANSAKSI ======
                _sectionLabel(context, 'Jenis Transaksi'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _typeButton(context,
                      label: 'Stok Masuk',
                      icon: Icons.add_circle_rounded,
                      isSelected: _transType == TransactionType.masuk,
                      color: AppTheme.success,
                      onTap: () =>
                          setState(() => _transType = TransactionType.masuk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _typeButton(context,
                      label: 'Stok Keluar',
                      icon: Icons.remove_circle_rounded,
                      isSelected: _transType == TransactionType.keluar,
                      color: AppTheme.error,
                      onTap: () =>
                          setState(() => _transType = TransactionType.keluar),
                    ),
                  ),
                ]),
                const SizedBox(height: 22),

                // ====== CARI & PILIH BARANG ======
                _sectionLabel(context, 'Pilih Barang'),
                const SizedBox(height: 10),
                Consumer<ProductProvider>(
                  builder: (ctx, provider, _) {
                    final filtered = provider.searchProducts(_searchQuery);
                    return Column(children: [
                      // Search bar
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, SKU, atau barcode...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: context.color.onSurfaceVariant.withValues(alpha: 0.7), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      size: 18, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: context.color.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      // Dropdown produk
                      if (_searchQuery.isNotEmpty || _selectedProduct != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: context.color.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: context.color.secondary, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedProduct?.id,
                              hint: Text('-- Pilih dari hasil pencarian --',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: context.color.onSurfaceVariant.withValues(alpha: 0.7))),
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: context.color.onSurface),
                              items: filtered.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    '${p.nama}  (Stok: ${p.stok} ${p.satuan})',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() {
                                _selectedProduct =
                                    provider.getProductById(val ?? '');
                              }),
                            ),
                          ),
                        ),
                    ]);
                  },
                ),
                const SizedBox(height: 16),

                // ====== PREVIEW PRODUK TERPILIH ======
                if (_selectedProduct != null) ...[
                  _buildProductPreview(context, _selectedProduct!),
                  const SizedBox(height: 22),
                ],

                // ====== INPUT JUMLAH ======
                _sectionLabel(context, 'Jumlah'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _jumlahCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.color.outline),
                    prefixIcon: GestureDetector(
                      onTap: () {
                        final val = int.tryParse(_jumlahCtrl.text) ?? 0;
                        if (val > 1) _jumlahCtrl.text = '${val - 1}';
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.color.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.remove_rounded, size: 20),
                      ),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        final val = int.tryParse(_jumlahCtrl.text) ?? 0;
                        _jumlahCtrl.text = '${val + 1}';
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.color.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_rounded,
                            size: 20, color: context.color.primary),
                      ),
                    ),
                    filled: true,
                    fillColor: context.color.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: context.color.secondary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Jumlah wajib diisi';
                    }
                    final n = int.tryParse(val.trim());
                    if (n == null || n <= 0) return 'Harus angka lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ====== CATATAN (OPSIONAL) ======
                _sectionLabel(context, 'Catatan (Opsional)'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _catatanCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Contoh: Barang diterima dari supplier PT. Maju',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, top: 14),
                      child: Icon(Icons.notes_rounded,
                          color: context.color.onSurfaceVariant.withValues(alpha: 0.7), size: 20),
                    ),
                    filled: true,
                    fillColor: context.color.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: context.color.secondary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(50, 14, 16, 14),
                  ),
                ),
                const SizedBox(height: 28),

                // ====== TOMBOL SUBMIT ======
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _handleUpdate,
                    icon: _isUpdating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: context.color.surfaceContainer))
                        : Icon(
                            _transType == TransactionType.masuk
                                ? Icons.add_circle_rounded
                                : Icons.remove_circle_rounded,
                          ),
                    label: Text(
                      _isUpdating
                          ? 'Menyimpan...'
                          : _transType == TransactionType.masuk
                              ? 'Catat Stok Masuk'
                              : 'Catat Stok Keluar',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _transType == TransactionType.masuk
                          ? AppTheme.success
                          : AppTheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.color.onSurface));
  }

  Widget _typeButton(BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : context.color.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : context.color.outline.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? Colors.white : context.color.onSurfaceVariant.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : context.color.onSurfaceVariant.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPreview(BuildContext context, Product product) {
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: context.color.secondary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Thumbnail produk — gambar atau ikon fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.color.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.color.secondary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          errorWidget: (ctx, url, err) => Icon(
                            Icons.inventory_2_rounded,
                            color: context.color.secondary,
                            size: 26,
                          ),
                        )
                      : Icon(Icons.inventory_2_rounded,
                          color: context.color.secondary, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.nama,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.color.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        '${product.sku}  •  ${product.rakLokasi}  •  ${product.kategori}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: context.color.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _previewStat(context,
                label: 'Stok Sekarang',
                value: '${product.stok} ${product.satuan}',
                color: product.isStokKritis
                    ? Colors.red.shade600
                    : AppTheme.success,
              ),
              _previewStat(context,
                label: 'Stok Minimum',
                value: '${product.stokMinimum}',
                color: context.color.onSurfaceVariant,
              ),
              _previewStat(context,
                label: 'Harga Jual',
                value: product.hargaJual > 0
                    ? 'Rp ${_fmt(product.hargaJual)}'
                    : '-',
                color: context.color.primary,
              ),
            ],
          ),
          if (product.isMendekatiExpired || product.isSudahExpired) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: product.isSudahExpired
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16,
                    color: product.isSudahExpired
                        ? Colors.red.shade600
                        : Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  product.isSudahExpired
                      ? '⚠️ Barang ini sudah EXPIRED!'
                      : '⏰ Expire dalam ${product.sisaHariExpired} hari lagi',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: product.isSudahExpired
                          ? Colors.red.shade700
                          : Colors.orange.shade800),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewStat(BuildContext context, 
      {required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 10, color: context.color.onSurfaceVariant)),
      ],
    );
  }

  String _fmt(int value) {
    final str = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}
