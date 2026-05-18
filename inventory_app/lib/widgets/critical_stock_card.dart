import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';

/// Widget kartu untuk menampilkan item stok kritis di dashboard.
class CriticalStockCard extends StatelessWidget {
  final Product product;
  const CriticalStockCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final percentage = product.stokMinimum > 0
        ? (product.stok / product.stokMinimum).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ikon peringatan
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade700, size: 28),
            ),
            const SizedBox(width: 14),
            // Info produk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.nama,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF1A1A2E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${product.sku} • Rak ${product.rakLokasi}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.red.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage < 0.3
                            ? Colors.red.shade600
                            : Colors.orange.shade600,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Angka stok
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${product.stok}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.red.shade700)),
                Text('min: ${product.stokMinimum}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
