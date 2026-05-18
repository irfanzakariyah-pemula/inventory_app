import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';

/// Widget kartu reusable untuk menampilkan info produk di daftar barang.
/// Menampilkan nama, SKU, kategori, stok, dan lokasi rak.
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
        color: Colors.white,
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
                // Ikon kategori
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2A4A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getCategoryIcon(product.kategori),
                      color: const Color(0xFF1B2A4A), size: 24),
                ),
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
                              color: const Color(0xFF1A1A2E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(product.sku,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade500)),
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
                _infoChip(Icons.category_outlined, product.kategori),
                const SizedBox(width: 12),
                _infoChip(Icons.location_on_outlined, 'Rak ${product.rakLokasi}'),
                const Spacer(),
                // Tombol aksi (hanya untuk admin)
                if (showActions) ...[
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined,
                          size: 20, color: const Color(0xFF4A6FA5)),
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

  /// Widget chip kecil untuk info kategori dan lokasi
  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
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
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
