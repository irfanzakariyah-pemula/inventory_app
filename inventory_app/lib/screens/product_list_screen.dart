import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import 'product_form_screen.dart';

/// ============================================================
/// HALAMAN DAFTAR BARANG - Master Data Produk (Admin only)
/// ============================================================
/// Fitur: Search (nama/SKU/barcode/kategori), Filter, Tambah,
///        Edit, Hapus, dan tampilan chip Expired/Kritis.
/// ============================================================
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(
      BuildContext context, String productId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Barang',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.inter(color: context.color.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProductProvider>(context, listen: false)
                  .deleteProduct(productId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('"$name" berhasil dihapus',
                    style: GoogleFonts.inter()),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hapus', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
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
        title: Consumer<ProductProvider>(
          builder: (_, pp, x) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Master Barang',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.color.onSurface)),
              Text('${pp.totalBarang} produk',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: context.color.onSurfaceVariant)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ====== SEARCH BAR ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    setState(() => _searchQuery = val),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Cari nama, SKU, barcode, kategori...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.color.onSurfaceVariant.withValues(alpha: 0.7), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              size: 18, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ====== DAFTAR PRODUK ======
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: context.color.primary));
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 56, color: context.color.outline),
                          const SizedBox(height: 12),
                          Text('Gagal memuat data',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: context.color.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  final products =
                      provider.searchProducts(_searchQuery);

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: context.color.outline),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada barang yang cocok'
                                : 'Belum ada barang',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                color: context.color.onSurfaceVariant),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Tap tombol + untuk menambahkan',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: context.color.onSurfaceVariant.withValues(alpha: 0.7))),
                          ],
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: context.color.primary,
                    onRefresh: () => provider.fetchProducts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        final p = products[i];
                        return _buildProductCard(context, p);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const ProductFormScreen())),
        backgroundColor: context.color.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah Barang',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductFormScreen(product: product)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Thumbnail / Icon Produk
              _buildProductThumbnail(context, product),
              const SizedBox(width: 12),

              // Info Produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(product.nama,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.color.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        // Status chips
                        if (product.isSudahExpired)
                          _chip('Expired', Colors.red.shade700,
                              Colors.red.shade50)
                        else if (product.isMendekatiExpired)
                          _chip('Exp ${product.sisaHariExpired}h',
                              Colors.orange.shade700,
                              Colors.orange.shade50)
                        else if (product.isStokKritis)
                          _chip('Kritis', Colors.red.shade600,
                              Colors.red.shade50),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.sku}  •  ${product.kategori}  •  ${product.rakLokasi}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: context.color.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Stok
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: product.isStokKritis
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Stok: ${product.stok} ${product.satuan}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: product.isStokKritis
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Harga Jual
                        if (product.hargaJual > 0)
                          Text(
                            'Rp ${_formatRupiah(product.hargaJual)}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.color.primary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Tombol Aksi
              Column(
                children: [
                  _actionBtn(
                    icon: Icons.edit_rounded,
                    color: context.color.secondary,
                    bgColor: context.color.secondary.withValues(alpha: 0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductFormScreen(product: product)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _actionBtn(
                    icon: Icons.delete_rounded,
                    color: Colors.red.shade500,
                    bgColor: Colors.red.shade50,
                    onTap: () =>
                        _showDeleteDialog(context, product.id, product.nama),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(BuildContext context, Product product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: product.isStokKritis
              ? Colors.red.shade50
              : context.color.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.inventory_2_rounded,
          color: product.isStokKritis
              ? Colors.red.shade400
              : context.color.secondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, Color bg) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration:
            BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  String _formatRupiah(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
