import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

/// ============================================================
/// HALAMAN FORM PRODUK - Tambah & Edit barang (Admin only)
/// ============================================================
/// Mode tambah baru  : [product] null
/// Mode edit existing: [product] berisi data produk
///
/// Field lengkap versi Minimarket:
///   - Nama, SKU, Barcode, Kategori
///   - Stok Awal, Stok Minimum, Lokasi Rak
///   - Harga Beli, Harga Jual (preview margin otomatis)
///   - Tanggal Expired (Date Picker, opsional)
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
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _kategoriCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _stokMinCtrl;
  late final TextEditingController _rakCtrl;
  late final TextEditingController _hargaBeliCtrl;
  late final TextEditingController _hargaJualCtrl;
  late final TextEditingController _satuanCtrl;

  // ─── State ──────────────────────────────────────────────────
  DateTime? _expiredDate;
  bool _isSaving = false;
  int _marginProfit = 0;
  double _persenMargin = 0;
  File? _pickedImageFile;         // File gambar baru yang dipilih dari device
  String? _existingImageUrl;      // URL gambar lama (dari Supabase Storage)
  bool _isUploadingImage = false; // Loading indicator saat upload berlangsung

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
    _barcodeCtrl   = TextEditingController(text: p?.barcode ?? '');
    _kategoriCtrl  = TextEditingController(text: p?.kategori ?? '');
    _stokCtrl      = TextEditingController(text: p != null ? '${p.stok}' : '0');
    _stokMinCtrl   = TextEditingController(text: p != null ? '${p.stokMinimum}' : '5');
    _rakCtrl       = TextEditingController(text: p?.rakLokasi ?? '');
    _hargaBeliCtrl = TextEditingController(text: p != null ? '${p.hargaBeli}' : '0');
    _hargaJualCtrl = TextEditingController(text: p != null ? '${p.hargaJual}' : '0');
    _satuanCtrl    = TextEditingController(text: p?.satuan ?? 'pcs');
    _expiredDate   = p?.expiredDate;
    _existingImageUrl = p?.imageUrl; // simpan URL gambar yang sudah ada

    // Hitung margin awal jika mode edit
    _updateMargin();

    // Listener untuk update margin secara real-time
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
    _barcodeCtrl.dispose();
    _kategoriCtrl.dispose();
    _stokCtrl.dispose();
    _stokMinCtrl.dispose();
    _rakCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _hargaJualCtrl.dispose();
    _satuanCtrl.dispose();
    super.dispose();
  }

  // ─── Image Picker ─────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85, // Kompres agar ukuran file tidak terlalu besar
      );
      if (picked != null) {
        setState(() => _pickedImageFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal memilih gambar: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  /// Tampilkan bottom sheet untuk pilih sumber gambar (galeri / kamera)
  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.color.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pilih Sumber Gambar',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      color: context.color.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageSourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      color: context.color.secondary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              // Tombol hapus gambar (hanya tampil jika sudah ada gambar)
              if (_pickedImageFile != null || _existingImageUrl != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _pickedImageFile = null;
                        _existingImageUrl = null;
                      });
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade600, size: 18),
                    label: Text('Hapus Foto',
                        style: GoogleFonts.inter(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ─── Date Picker ─────────────────────────────────────────────
  Future<void> _pickExpiredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiredDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Pilih Tanggal Kedaluwarsa',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: context.color.primary,
            onSurface: context.color.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiredDate = picked);
  }

  // ─── Save ─────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // ── LANGKAH 1: Upload gambar dulu sebelum simpan produk ──────────
      // Ini memastikan ID produk (mode edit) atau kita pakai SKU sementara.
      // Untuk mode TAMBAH BARU: upload gambar dilakukan SETELAH produk tersimpan
      // dan ID-nya diambil dari response insert (bukan pencarian via SKU).

      String? finalImageUrl = _existingImageUrl;

      final product = Product(
        id: widget.product?.id ?? '',
        nama: _namaCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isNotEmpty
            ? _barcodeCtrl.text.trim()
            : _skuCtrl.text.trim(),
        kategori: _kategoriCtrl.text.trim(),
        stok: int.tryParse(_stokCtrl.text.trim()) ?? 0,
        stokMinimum: int.tryParse(_stokMinCtrl.text.trim()) ?? 0,
        rakLokasi: _rakCtrl.text.trim(),
        hargaBeli: int.tryParse(_hargaBeliCtrl.text.trim()) ?? 0,
        hargaJual: int.tryParse(_hargaJualCtrl.text.trim()) ?? 0,
        satuan: _satuanCtrl.text.trim().isEmpty ? 'pcs' : _satuanCtrl.text.trim(),
        expiredDate: _expiredDate,
        imageUrl: finalImageUrl,
      );

      // ── LANGKAH 2: Simpan data produk ke database ─────────────────────
      String savedProductId;

      if (isEditMode) {
        // Mode edit — ID sudah diketahui
        savedProductId = product.id;
        await provider.updateProduct(
          product,
          userId: auth.currentUser?.id,
          userName: auth.currentUser?.nama,
        );
      } else {
        // Mode tambah baru — ambil ID dari hasil insert via addProductAndGetId
        savedProductId = await provider.addProductAndGetId(
          product,
          userId: auth.currentUser?.id,
          userName: auth.currentUser?.nama,
        );
      }

      if (!mounted) return;

      // ── LANGKAH 3: Upload gambar jika ada file baru dipilih ───────────
      if (_pickedImageFile != null && savedProductId.isNotEmpty) {
        if (mounted) setState(() => _isUploadingImage = true);

        // Hapus gambar lama dari Storage jika mode edit dan ada gambar lama
        if (isEditMode && widget.product?.imageUrl != null) {
          await provider.deleteGambarProduk(widget.product!.imageUrl);
        }

        // Upload gambar baru ke Supabase Storage
        finalImageUrl = await provider.uploadGambarProduk(
          imageFile: _pickedImageFile!,
          productId: savedProductId,
        );

        if (!mounted) return;
        setState(() => _isUploadingImage = false);

        // Cek apakah upload berhasil
        if (finalImageUrl == null) {
          // Upload gagal — tampilkan error tapi produk tetap tersimpan
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              provider.errorMessage ?? 'Gagal upload gambar. Data barang tetap tersimpan.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        } else {
          // Upload berhasil — update image_url di database
          await provider.updateImageUrl(savedProductId, finalImageUrl);
        }
      } else if (_existingImageUrl == null && widget.product?.imageUrl != null) {
        // User menghapus gambar — hapus dari Storage dan database
        await provider.deleteGambarProduk(widget.product!.imageUrl);
        await provider.updateImageUrl(savedProductId, null);
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
      setState(() {
        _isSaving = false;
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e', style: GoogleFonts.inter()),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
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
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ====== SEKSI 0: FOTO PRODUK ======
                  _buildFotoSection(),
                  const SizedBox(height: 16),

                  // ====== SEKSI 1: INFO DASAR ======
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
                  Row(children: [
                    Expanded(
                      child: _buildField(
                        controller: _skuCtrl,
                        label: 'SKU (Kode Internal) *',
                        hint: 'MNM-UML-001',
                        icon: Icons.qr_code_2_rounded,
                        validator: _requiredValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _barcodeCtrl,
                        label: 'Barcode (EAN/UPC)',
                        hint: '8992761123456',
                        icon: Icons.barcode_reader,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _kategoriCtrl,
                    label: 'Kategori *',
                    hint: 'Pilih atau ketik kategori',
                    icon: Icons.category_rounded,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 10),
                  // Chip suggestion kategori
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _kategoriSuggestions.map((kat) {
                      final isSelected = _kategoriCtrl.text == kat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_kategoriCtrl.text == kat) {
                              _kategoriCtrl.text = '';
                            } else {
                              _kategoriCtrl.text = kat;
                            }
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
                      Row(children: [
                        Expanded(
                          child: _buildField(
                            controller: _stokCtrl,
                            label: isEditMode ? 'Stok Saat Ini' : 'Stok Awal *',
                            hint: '0',
                            icon: Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: _numberValidator,
                            readOnly: isEditMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _stokMinCtrl,
                            label: 'Stok Minimum *',
                            hint: '5',
                            icon: Icons.trending_down_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: _numberValidator,
                          ),
                        ),
                      ]),
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
                            onTap: () {
                              setState(() {
                                _satuanCtrl.text = sat;
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  const SizedBox(height: 16),

                  // ====== SEKSI 4: TANGGAL EXPIRED ======
                  _sectionCard(
                    title: 'Tanggal Kedaluwarsa',
                    icon: Icons.calendar_today_rounded,
                    children: [
                      GestureDetector(
                        onTap: _pickExpiredDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: context.color.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _expiredDate != null
                                    ? context.color.secondary
                                    : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Row(children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: _expiredDate != null
                                  ? context.color.secondary
                                  : context.color.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _expiredDate != null
                                    ? _formatDate(_expiredDate!)
                                    : 'Tap untuk memilih tanggal (opsional)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _expiredDate != null
                                      ? context.color.onSurface
                                      : context.color.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            if (_expiredDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _expiredDate = null),
                                child: Icon(Icons.close_rounded,
                                    size: 18,
                                    color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kosongkan jika barang tidak memiliki tanggal kedaluwarsa.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
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

          // ====== OVERLAY LOADING UPLOAD ======
          if (_isUploadingImage)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 22),
                  decoration: BoxDecoration(
                    color: context.color.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: context.color.primary),
                      const SizedBox(height: 14),
                      Text('Mengunggah foto...',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.color.onSurface)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Foto Produk Section ──────────────────────────────────────
  Widget _buildFotoSection() {
    final hasImage =
        _pickedImageFile != null || (_existingImageUrl?.isNotEmpty == true);

    return _sectionCard(
      title: 'Foto Produk',
      icon: Icons.photo_camera_rounded,
      children: [
        GestureDetector(
          onTap: _showImagePickerSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.transparent
                  : context.color.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage
                    ? context.color.primary.withValues(alpha: 0.3)
                    : context.color.outline.withValues(alpha: 0.3),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _buildImagePreview(hasImage),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasImage
              ? 'Tap foto untuk mengganti atau menghapus'
              : 'Tap untuk menambahkan foto produk (opsional)',
          style: GoogleFonts.inter(
              fontSize: 11,
              color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildImagePreview(bool hasImage) {
    // Prioritas 1: Ada file baru dipilih dari galeri/kamera
    if (_pickedImageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _pickedImageFile!,
            fit: BoxFit.cover,
          ),
          // Badge "Baru"
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.color.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Baru',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          // Overlay edit icon
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black.withValues(alpha: 0.35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Ganti Foto',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Prioritas 2: Ada URL gambar dari Supabase
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _existingImageUrl!,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(
              color: context.color.primary.withValues(alpha: 0.05),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: context.color.primary),
              ),
            ),
            errorWidget: (ctx, url, err) => _imagePlaceholder(),
          ),
          // Overlay edit icon
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black.withValues(alpha: 0.35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Ganti Foto',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Default: Belum ada gambar
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 40,
            color: context.color.primary.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('Tambah Foto',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.color.primary.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text('JPG, PNG, WEBP • Maks 1024px',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: context.color.onSurfaceVariant.withValues(alpha: 0.6))),
      ],
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
              child:
                  Icon(icon, color: context.color.primary, size: 17),
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
        prefixIcon: Icon(icon, size: 18, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
        labelStyle:
            GoogleFonts.inter(fontSize: 12, color: context.color.onSurfaceVariant),
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
          borderSide:
              BorderSide(color: context.color.secondary, width: 1.5),
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

  String _formatDate(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
