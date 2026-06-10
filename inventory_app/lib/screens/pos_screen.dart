// ============================================================
// SCREEN POS / KASIR
// ============================================================
// Halaman kasir untuk proses penjualan.
//
// Layout:
//   [AppBar]  — judul + total keranjang + tombol kosongkan
//   [Body]    — search produk + grid/list produk (bisa diklik)
//   [Bottom]  — DraggableScrollableSheet keranjang belanja
//
// Flow:
//   1. Kasir ketuk produk → masuk keranjang
//   2. Di keranjang: swipe hapus, +/- qty
//   3. Isi nominal bayar → kembalian otomatis
//   4. Pilih metode bayar → tekan BAYAR
//   5. Dialog sukses dengan info struk
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/customer_provider.dart';
import '../models/product_model.dart';
import '../models/sales_model.dart';
import '../models/customer_model.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen>
    with SingleTickerProviderStateMixin {
  // ─── State Keranjang ────────────────────────────────────────
  final List<SalesItem> _cart = [];

  // ─── State Form Pembayaran ──────────────────────────────────
  String _metodeBayar = 'tunai';
  int _diskon = 0;
  Customer? _selectedCustomer;
  final TextEditingController _bayarCtrl = TextEditingController();
  final TextEditingController _diskonCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();

  // ─── Number Formatter ───────────────────────────────────────
  final _fmt = NumberFormat('#,###', 'id_ID');

  // ─── Sheet Controller ───────────────────────────────────────
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  @override
  void dispose() {
    _bayarCtrl.dispose();
    _diskonCtrl.dispose();
    _searchCtrl.dispose();
    _catatanCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  // ==================== GETTER KALKULASI ====================

  int get _subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get _total => (_subtotal - _diskon).clamp(0, double.maxFinite.toInt());
  int get _bayar => int.tryParse(_bayarCtrl.text.replaceAll('.', '')) ?? 0;
  int get _kembalian => (_bayar - _total).clamp(0, double.maxFinite.toInt());
  int get _totalItem => _cart.fold(0, (sum, item) => sum + item.jumlah);

  // ==================== CART OPERATIONS ====================

  void _addToCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.productId == product.id);
      if (idx >= 0) {
        // Sudah ada — naikkan qty
        if (_cart[idx].jumlah < product.stok) {
          _cart[idx].jumlah++;
        } else {
          _showToast('Stok tidak mencukupi!', isError: true);
        }
      } else {
        // Belum ada — tambahkan baru
        if (product.stok > 0) {
          _cart.add(SalesItem(
            productId: product.id,
            namaProduk: product.nama,
            hargaJual: product.hargaJual,
            hargaBeli: product.hargaBeli,
            jumlah: 1,
            satuan: product.satuan,
          ));
          // Expand sheet sedikit
          if (_sheetCtrl.isAttached && _sheetCtrl.size < 0.45) {
            _sheetCtrl.animateTo(
              0.45,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else {
          _showToast('Stok habis!', isError: true);
        }
      }
    });
  }

  void _incrementQty(int index) {
    final item = _cart[index];
    final product = Provider.of<ProductProvider>(context, listen: false)
        .getProductById(item.productId ?? '');
    setState(() {
      if (product == null || item.jumlah < product.stok) {
        _cart[index].jumlah++;
      } else {
        _showToast('Stok tidak mencukupi!', isError: true);
      }
    });
  }

  void _decrementQty(int index) {
    setState(() {
      if (_cart[index].jumlah > 1) {
        _cart[index].jumlah--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _bayarCtrl.clear();
      _diskonCtrl.clear();
      _catatanCtrl.clear();
      _diskon = 0;
      _selectedCustomer = null;
      _metodeBayar = 'tunai';
    });
  }

  // ==================== CHECKOUT ====================

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      _showToast('Keranjang masih kosong!', isError: true);
      return;
    }
    if (_bayar < _total) {
      _showToast('Nominal bayar kurang dari total!', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final salesProv = Provider.of<SalesProvider>(context, listen: false);

    final nomorStruk = await salesProv.createSale(
      items: List.from(_cart),
      userId: auth.currentUser?.id ?? '',
      userName: auth.currentUser?.nama ?? 'Kasir',
      bayar: _bayar,
      metodeBayar: _metodeBayar,
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.nama,
      diskon: _diskon,
      catatan: _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
    );

    if (!mounted) return;

    if (nomorStruk != null) {
      _showSuccessDialog(nomorStruk);
    } else {
      _showToast(salesProv.errorMessage ?? 'Transaksi gagal', isError: true);
    }
  }

  void _showSuccessDialog(String nomorStruk) {
    final cartSnapshot = List<SalesItem>.from(_cart);
    final totalSnapshot = _total;
    final bayarSnapshot = _bayar;
    final kembalianSnapshot = _kembalian;
    final metodeSnapshot = _metodeBayar;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon sukses dengan animasi
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      size: 48, color: AppTheme.success),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaksi Berhasil! 🎉',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Struk ringkas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.color.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.color.outline),
                ),
                child: Column(
                  children: [
                    _receiptRow('Nomor Struk', nomorStruk,
                        valueStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.color.primary)),
                    const SizedBox(height: 6),
                    _receiptRow('Produk',
                        '${cartSnapshot.length} jenis (${cartSnapshot.fold(0, (s, i) => s + i.jumlah)} item)'),
                    const SizedBox(height: 6),
                    _receiptRow('Metode',
                        metodeSnapshot[0].toUpperCase() + metodeSnapshot.substring(1)),
                    const Divider(height: 16),
                    _receiptRow('Total',
                        'Rp ${_fmt.format(totalSnapshot)}',
                        isBold: true),
                    const SizedBox(height: 4),
                    _receiptRow('Bayar',
                        'Rp ${_fmt.format(bayarSnapshot)}'),
                    const SizedBox(height: 4),
                    _receiptRow(
                      'Kembalian',
                      'Rp ${_fmt.format(kembalianSnapshot)}',
                      valueStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearCart();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Tutup',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.color.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Transaksi Baru',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {bool isBold = false, TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: context.color.onSurfaceVariant)),
        Text(
          value,
          style: valueStyle ??
              GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: context.color.onSurface,
              ),
        ),
      ],
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ── Bagian atas: Daftar produk ──
          _buildProductSection(context),
          // ── Bagian bawah: Keranjang (DraggableScrollableSheet) ──
          _buildCartSheet(context),
        ],
      ),
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
              gradient: LinearGradient(
                colors: [context.color.primary, context.color.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Kasir / POS',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // Total keranjang di AppBar
        if (_cart.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.color.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: context.color.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_rounded,
                    size: 14, color: context.color.primary),
                const SizedBox(width: 4),
                Text(
                  'Rp ${_fmt.format(_total)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.color.primary,
                  ),
                ),
              ],
            ),
          ),
        // Tombol kosongkan
        if (_cart.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            color: AppTheme.error,
            tooltip: 'Kosongkan keranjang',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Kosongkan Keranjang?',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  content: Text('Semua item akan dihapus dari keranjang.',
                      style: GoogleFonts.inter(fontSize: 14)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal',
                          style: GoogleFonts.inter(
                              color: context.color.onSurfaceVariant)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error),
                      onPressed: () {
                        Navigator.pop(context);
                        _clearCart();
                      },
                      child: Text('Kosongkan',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── PRODUCT SECTION ───────────────────────────────────────

  Widget _buildProductSection(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProv, _) {
        return Column(
          children: [
            // Search bar produk
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari produk (nama, SKU, barcode)...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.color.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.color.onSurfaceVariant),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 18,
                              color: context.color.onSurfaceVariant),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            // Daftar produk
            Expanded(
              child: _buildProductGrid(context, productProv),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductGrid(
      BuildContext context, ProductProvider productProv) {
    final products = _searchCtrl.text.isEmpty
        ? productProv.allProducts
        : productProv.searchProducts(_searchCtrl.text);

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48,
                color: context.color.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Belum ada produk'
                  : 'Produk tidak ditemukan',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.color.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Bottom padding supaya produk tidak tertutup sheet
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 320),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _buildProductTile(context, products[index]),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product) {
    final inCart = _cart.firstWhere(
      (i) => i.productId == product.id,
      orElse: () => SalesItem(
          namaProduk: '', hargaJual: 0, hargaBeli: 0),
    );
    final cartQty = inCart.productId == product.id ? inCart.jumlah : 0;
    final isOutOfStock = product.stok <= 0;

    return GestureDetector(
      onTap: isOutOfStock ? null : () => _addToCart(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cartQty > 0
              ? context.color.primary.withValues(alpha: 0.06)
              : context.color.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cartQty > 0
                ? context.color.primary.withValues(alpha: 0.35)
                : context.color.outline,
            width: cartQty > 0 ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Gambar / placeholder produk
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? context.color.outline
                    : context.color.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.color.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        errorWidget: (ctx, url, err) => Icon(
                          Icons.inventory_2_rounded,
                          size: 22,
                          color: isOutOfStock
                              ? context.color.onSurfaceVariant.withValues(alpha: 0.4)
                              : context.color.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_rounded,
                      size: 24,
                      color: isOutOfStock
                          ? context.color.onSurfaceVariant.withValues(alpha: 0.4)
                          : context.color.primary.withValues(alpha: 0.6),
                    ),
            ),
            const SizedBox(width: 12),
            // Info produk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOutOfStock
                          ? context.color.onSurfaceVariant
                          : context.color.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Rp ${_fmt.format(product.hargaJual)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isOutOfStock
                          ? context.color.onSurfaceVariant
                          : context.color.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? AppTheme.error.withValues(alpha: 0.1)
                              : product.isStokKritis
                                  ? AppTheme.warning.withValues(alpha: 0.1)
                                  : AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOutOfStock
                              ? 'Stok Habis'
                              : 'Stok: ${product.stok} ${product.satuan}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOutOfStock
                                ? AppTheme.error
                                : product.isStokKritis
                                    ? AppTheme.warning
                                    : AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Badge qty / tombol tambah
            if (cartQty > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cartQty',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              )
            else if (!isOutOfStock)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.color.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_rounded,
                    color: context.color.primary, size: 20),
              )
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.color.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.remove_circle_outline_rounded,
                    color: context.color.onSurfaceVariant, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  // ── CART SHEET ─────────────────────────────────────────────

  Widget _buildCartSheet(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.12, 0.45, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.surfaceContainer,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle bar + header
                _buildSheetHeader(context),
                // Konten sheet
                if (_cart.isEmpty)
                  _buildEmptyCart(context)
                else ...[
                  _buildCartItems(context),
                  _buildPaymentForm(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          // Handle
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart_rounded,
                      color: context.color.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Keranjang',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.color.onSurface),
                  ),
                  if (_cart.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.color.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_totalItem item',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              if (_cart.isNotEmpty)
                Text(
                  'Rp ${_fmt.format(_total)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.color.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(Icons.add_shopping_cart_rounded,
              size: 40,
              color: context.color.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            'Ketuk produk di atas untuk menambahkan',
            style: GoogleFonts.inter(
                fontSize: 12, color: context.color.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Dismissible(
          key: Key(item.productId ?? item.namaProduk),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(Icons.delete_rounded, color: AppTheme.error, size: 22),
          ),
          onDismissed: (direction) => _removeItem(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.color.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaProduk,
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
                        'Rp ${_fmt.format(item.hargaJual)} × ${item.jumlah} ${item.satuan}',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp ${_fmt.format(item.subtotal)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                // Qty stepper
                Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove_rounded,
                      onTap: () => _decrementQty(index),
                    ),
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Text(
                        '${item.jumlah}',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add_rounded,
                      onTap: () => _incrementQty(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.color.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: context.color.primary),
      ),
    );
  }

  Widget _buildPaymentForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),

          // ── Ringkasan Harga ──
          _summaryRow('Subtotal', 'Rp ${_fmt.format(_subtotal)}'),
          if (_diskon > 0) ...[
            const SizedBox(height: 4),
            _summaryRow(
              'Diskon',
              '- Rp ${_fmt.format(_diskon)}',
              color: AppTheme.error,
            ),
          ],
          const SizedBox(height: 6),
          _summaryRow(
            'TOTAL',
            'Rp ${_fmt.format(_total)}',
            isBold: true,
            fontSize: 18,
          ),

          const SizedBox(height: 16),

          // ── Metode Bayar ──
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.color.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['tunai', 'transfer', 'qris']
                .map((m) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: m != 'qris' ? 8 : 0,
                        ),
                        child: _metodeBtn(m),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 14),

          // ── Diskon (opsional) ──
          TextField(
            controller: _diskonCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(fontSize: 14),
            onChanged: (v) {
              setState(() => _diskon = int.tryParse(v) ?? 0);
            },
            decoration: InputDecoration(
              labelText: 'Diskon (Rp) — opsional',
              prefixText: 'Rp ',
              prefixIcon: const Icon(Icons.discount_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 12),

          // ── Pelanggan (opsional) ──
          _buildCustomerSelector(context),

          const SizedBox(height: 12),

          // ── Nominal Bayar ──
          TextField(
            controller: _bayarCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(fontSize: 14),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nominal Bayar *',
              prefixText: 'Rp ',
              prefixIcon: const Icon(Icons.payments_rounded, size: 18),
            ),
          ),

          // ── Kembalian ──
          if (_bayar > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kembalian >= 0
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _kembalian >= 0
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _kembalian >= 0 ? 'Kembalian' : 'Kurang Bayar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kembalian >= 0
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                  Text(
                    'Rp ${_fmt.format(_kembalian.abs())}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kembalian >= 0
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Catatan (opsional) ──
          TextField(
            controller: _catatanCtrl,
            maxLines: 1,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon:
                  const Icon(Icons.note_rounded, size: 18),
            ),
          ),

          const SizedBox(height: 20),

          // ── Tombol BAYAR ──
          Consumer<SalesProvider>(
            builder: (context, salesProv, child) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: salesProv.isSubmitting
                    ? null
                    : (_cart.isEmpty || _bayar < _total ? null : _checkout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.color.primary,
                  disabledBackgroundColor:
                      context.color.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: salesProv.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                label: Text(
                  salesProv.isSubmitting
                      ? 'Memproses...'
                      : 'BAYAR SEKARANG',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metodeBtn(String metode) {
    final labels = {
      'tunai': 'Tunai',
      'transfer': 'Transfer',
      'qris': 'QRIS',
    };
    final icons = {
      'tunai': Icons.payments_rounded,
      'transfer': Icons.account_balance_rounded,
      'qris': Icons.qr_code_rounded,
    };
    final isSelected = _metodeBayar == metode;

    return GestureDetector(
      onTap: () => setState(() => _metodeBayar = metode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.color.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? context.color.primary
                : context.color.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icons[metode]!,
              size: 18,
              color: isSelected
                  ? context.color.primary
                  : context.color.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              labels[metode]!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? context.color.primary
                    : context.color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, custProv, child) {
        return GestureDetector(
          onTap: () => _showCustomerPicker(context, custProv),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: context.color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCustomer != null
                    ? context.color.primary.withValues(alpha: 0.5)
                    : context.color.outline,
                width: _selectedCustomer != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 18,
                    color: _selectedCustomer != null
                        ? context.color.primary
                        : context.color.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedCustomer?.nama ??
                        'Pilih Pelanggan (opsional)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _selectedCustomer != null
                          ? context.color.onSurface
                          : context.color.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_selectedCustomer != null)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCustomer = null),
                    child: Icon(Icons.clear_rounded,
                        size: 18,
                        color: context.color.onSurfaceVariant),
                  )
                else
                  Icon(Icons.arrow_drop_down_rounded,
                      color: context.color.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomerPicker(
      BuildContext context, CustomerProvider custProv) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: context.color.surfaceContainer,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: context.color.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Pilih Pelanggan',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (v) => setModal(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari pelanggan...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Opsi tanpa pelanggan
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.color.outline,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.person_off_rounded,
                            size: 20,
                            color: context.color.onSurfaceVariant),
                      ),
                      title: Text('Tanpa Pelanggan (Umum)',
                          style: GoogleFonts.inter(fontSize: 13)),
                      onTap: () {
                        setState(() => _selectedCustomer = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 8),
                    ...custProv.searchCustomers(searchCtrl.text).map(
                          (c) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    context.color.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  c.nama.substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: context.color.primary),
                                ),
                              ),
                            ),
                            title: Text(c.nama,
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(c.kontak ?? c.tipeLabel,
                                style: GoogleFonts.inter(fontSize: 11)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (c.tipe == 'grosir'
                                        ? AppTheme.warning
                                        : AppTheme.info)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(c.tipeLabel,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: c.tipe == 'grosir'
                                          ? AppTheme.warning
                                          : AppTheme.info)),
                            ),
                            onTap: () {
                              setState(() => _selectedCustomer = c);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? context.color.onSurfaceVariant,
            )),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (isBold ? context.color.onSurface : context.color.onSurface),
            )),
      ],
    );
  }

  // ==================== HELPERS ====================

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }
}
