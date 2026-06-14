import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

/// ============================================================
/// HALAMAN FORM PRODUK - Tambah & Edit barang (Admin only)
/// ============================================================
/// Mode tambah baru  : [product] null
/// Mode edit existing: [product] berisi data produk
///
/// Field yang disederhanakan:
///   - Nama, SKU, Kategori
///   - Stok Awal, Lokasi Rak, Satuan
///   - Harga Beli, Harga Jual (preview margin otomatis)
/// ============================================================
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─── Controllers ────────────────────────────────────────────
  late final TextEditingController _namaCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _kategoriCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _rakCtrl;
  late final TextEditingController _hargaBeliCtrl;
  late final TextEditingController _hargaJualCtrl;
  late final TextEditingController _satuanCtrl;

  // ─── State ──────────────────────────────────────────────────
  bool _isSaving = false;
  int _marginProfit = 0;
  double _persenMargin = 0;

  bool get isEditMode => widget.product != null;

  // Daftar kategori cepat (chip suggestion)
  final List<String> _kategoriSuggestions = [
    'Minuman', 'Makanan', 'Snack', 'Susu & Dairy',
    'Sembako', 'Kebersihan', 'Kosmetik', 'Rokok', 'Lainnya',
  ];

  // Daftar satuan cepat (chip suggestion)
  final List<String> _satuanSuggestions = [
    'pcs', 'kg', 'gr', 'pack', 'dus', 'botol', 'liter',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _namaCtrl      = TextEditingController(text: p?.nama ?? '');
    _skuCtrl       = TextEditingController(text: p?.sku ?? '');
    _kategoriCtrl  = TextEditingController(text: p?.kategori ?? '');
    _stokCtrl      = TextEditingController(text: p != null ? '${p.stok}' : '0');
    _rakCtrl       = TextEditingController(text: p?.rakLokasi ?? '');
    _hargaBeliCtrl = TextEditingController(text: p != null ? '${p.hargaBeli}' : '0');
    _hargaJualCtrl = TextEditingController(text: p != null ? '${p.hargaJual}' : '0');
    _satuanCtrl    = TextEditingController(text: p?.satuan ?? 'pcs');

    _updateMargin();
    _hargaBeliCtrl.addListener(_updateMargin);
    _hargaJualCtrl.addListener(_updateMargin);
  }

  void _updateMargin() {
    final beli = int.tryParse(_hargaBeliCtrl.text) ?? 0;
    final jual = int.tryParse(_hargaJualCtrl.text) ?? 0;
    setState(() {
      _marginProfit = jual - beli;
      _persenMargin = beli > 0 ? (_marginProfit / beli) * 100 : 0;
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _skuCtrl.dispose();
    _kategoriCtrl.dispose();
    _stokCtrl.dispose();
    _rakCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _hargaJualCtrl.dispose();
    _satuanCtrl.dispose();
    super.dispose();
  }

  // ─── Save ─────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        nama: _namaCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        barcode: _skuCtrl.text.trim(),
        kategori: _kategoriCtrl.text.trim(),
        stok: int.tryParse(_stokCtrl.text.trim()) ?? 0,
        stokMinimum: 0,
        rakLokasi: _rakCtrl.text.trim(),
        hargaBeli: int.tryParse(_hargaBeliCtrl.text.trim()) ?? 0,
        hargaJual: int.tryParse(_hargaJualCtrl.text.trim()) ?? 0,
        satuan: _satuanCtrl.text.trim().isEmpty ? 'pcs' : _satuanCtrl.text.trim(),
        expiredDate: null,
        imageUrl: null,
      );

      if (isEditMode) {
        await provider.updateProduct(
          product,
          userId: auth.currentUser?.id,
          userName: auth.currentUser?.nama,
        );
      } else {
        await provider.addProductAndGetId(
          product,
          userId: auth.currentUser?.id,
          userName: auth.currentUser?.nama,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isEditMode
              ? '"${product.nama}" berhasil diperbarui'
              : '"${product.nama}" berhasil ditambahkan',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e', style: GoogleFonts.inter()),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ─── Delete ───────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Barang',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
            'Apakah Anda yakin ingin menghapus barang ini? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child:
                Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      try {
        await provider.deleteProduct(widget.product!.id);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Barang berhasil dihapus', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menghapus barang: $e',
              style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Barang' : 'Tambah Barang',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: context.color.surfaceContainer,
        foregroundColor: context.color.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (isEditMode)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _confirmDelete,
              tooltip: 'Hapus Barang',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ====== SEKSI 1: INFO BARANG ======
              _sectionCard(
                title: 'Informasi Barang',
                icon: Icons.inventory_2_rounded,
                children: [
                  _buildField(
                    controller: _namaCtrl,
                    label: 'Nama Barang *',
                    hint: 'Contoh: Susu Ultra Milk 1L',
                    icon: Icons.label_rounded,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _skuCtrl,
                    label: 'SKU (Kode Internal) *',
                    hint: 'MNM-UML-001',
                    icon: Icons.qr_code_2_rounded,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _kategoriCtrl,
                    label: 'Kategori *',
                    hint: 'Pilih atau ketik kategori',
                    icon: Icons.category_rounded,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _kategoriSuggestions.map((kat) {
                      final isSelected = _kategoriCtrl.text == kat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _kategoriCtrl.text = isSelected ? '' : kat;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.color.primary
                                : context.color.outline.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(kat,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : context.color.onSurfaceVariant)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ====== SEKSI 2: STOK ======
              _sectionCard(
                title: 'Data Stok',
                icon: Icons.inventory_rounded,
                children: [
                  _buildField(
                    controller: _stokCtrl,
                    label: isEditMode ? 'Stok Saat Ini' : 'Stok Awal *',
                    hint: '0',
                    icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _numberValidator,
                    readOnly: isEditMode,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _rakCtrl,
                    label: 'Lokasi Rak *',
                    hint: 'Contoh: C2-03',
                    icon: Icons.location_on_rounded,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _satuanCtrl,
                    label: 'Satuan Barang *',
                    hint: 'Contoh: pcs, kg, pack, dus',
                    icon: Icons.unfold_more_rounded,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _satuanSuggestions.map((sat) {
                      final isSelected = _satuanCtrl.text == sat;
                      return GestureDetector(
                        onTap: () => setState(() => _satuanCtrl.text = sat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.color.primary
                                : context.color.outline.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(sat,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : context.color.onSurfaceVariant)),
                        ),
                      );
                    }).toList(),
                  ),
                  if (isEditMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Untuk mengubah jumlah stok, gunakan menu "Update Stok".',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.blue.shade700),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ====== SEKSI 3: HARGA ======
              _sectionCard(
                title: 'Harga & Profit',
                icon: Icons.attach_money_rounded,
                children: [
                  Row(children: [
                    Expanded(
                      child: _buildField(
                        controller: _hargaBeliCtrl,
                        label: 'Harga Beli (Modal) *',
                        hint: '0',
                        icon: Icons.arrow_downward_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _numberValidator,
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _hargaJualCtrl,
                        label: 'Harga Jual *',
                        hint: '0',
                        icon: Icons.arrow_upward_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _numberValidator,
                        prefixText: 'Rp ',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _marginProfit >= 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _marginProfit >= 0
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Margin Profit:',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${_formatRupiah(_marginProfit)}',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _marginProfit >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700),
                            ),
                            Text(
                              '${_persenMargin.toStringAsFixed(1)}% margin',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _marginProfit >= 0
                                      ? Colors.green.shade600
                                      : Colors.red.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ====== TOMBOL SIMPAN ======
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.color.surfaceContainer))
                      : Icon(isEditMode
                          ? Icons.save_rounded
                          : Icons.add_rounded),
                  label: Text(
                    isEditMode ? 'Simpan Perubahan' : 'Tambah Barang',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.color.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.color.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: context.color.primary, size: 17),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface)),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 14),
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon,
            size: 18,
            color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
        labelStyle: GoogleFonts.inter(
            fontSize: 12, color: context.color.onSurfaceVariant),
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: context.color.outline),
        filled: true,
        fillColor: readOnly
            ? context.color.outline.withValues(alpha: 0.2)
            : context.color.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.color.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Field ini wajib diisi';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Field ini wajib diisi';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Harus berupa angka';
    if (n < 0) return 'Tidak boleh negatif';
    return null;
  }

  String _formatRupiah(int value) {
    final str = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }
}
