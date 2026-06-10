import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

/// Widget kartu reusable untuk menampilkan info produk di daftar barang.
/// Menampilkan foto produk (jika ada), nama, SKU, kategori, stok, dan lokasi rak.
/// Warna indikator berubah merah jika stok kritis.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;   // Callback saat tombol edit ditekan
  final VoidCallback? onDelete; // Callback saat tombol hapus ditekan
  final bool showActions;       // Tampilkan tombol aksi (admin only)

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Thumbnail produk — gambar URL atau ikon fallback
                _buildThumbnail(context),
                const SizedBox(width: 12),
                // Nama dan SKU
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nama,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: context.color.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(product.sku,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.color.onSurfaceVariant)),
                    ],
                  ),
                ),
                // Badge stok
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: product.isStokKritis
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stok: ${product.stok}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: product.isStokKritis
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info bawah: kategori & lokasi rak
            Row(
              children: [
                _infoChip(context, Icons.category_outlined, product.kategori),
                const SizedBox(width: 12),
                _infoChip(context, Icons.location_on_outlined,
                    'Rak ${product.rakLokasi}'),
                const Spacer(),
                // Tombol aksi (hanya untuk admin)
                if (showActions) ...[
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined,
                          size: 20, color: context.color.secondary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Thumbnail produk: tampilkan foto jika ada, fallback ke ikon kategori.
  Widget _buildThumbnail(BuildContext context) {
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: product.isStokKritis
              ? Colors.red.shade50
              : context.color.primary.withValues(alpha: 0.08),
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
                      color: context.color.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                errorWidget: (ctx, url, err) => Center(
                  child: Icon(
                    _getCategoryIcon(product.kategori),
                    size: 24,
                    color: product.isStokKritis
                        ? Colors.red.shade400
                        : context.color.secondary,
                  ),
                ),
              )
            : Center(
                child: Icon(
                  _getCategoryIcon(product.kategori),
                  size: 24,
                  color: product.isStokKritis
                      ? Colors.red.shade400
                      : context.color.secondary,
                ),
              ),
      ),
    );
  }

  /// Widget chip kecil untuk info kategori dan lokasi
  Widget _infoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.color.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: context.color.onSurfaceVariant)),
      ],
    );
  }

  /// Menentukan ikon berdasarkan kategori produk
  IconData _getCategoryIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'elektronik':
        return Icons.devices_outlined;
      case 'atk':
        return Icons.edit_note_outlined;
      case 'furnitur':
        return Icons.chair_outlined;
      case 'minuman':
        return Icons.local_drink_outlined;
      case 'makanan':
        return Icons.restaurant_outlined;
      case 'snack':
        return Icons.cookie_outlined;
      case 'susu & dairy':
        return Icons.egg_outlined;
      case 'sembako':
        return Icons.shopping_basket_outlined;
      case 'kebersihan':
        return Icons.clean_hands_outlined;
      case 'kosmetik':
        return Icons.face_outlined;
      case 'rokok':
        return Icons.smoking_rooms_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
