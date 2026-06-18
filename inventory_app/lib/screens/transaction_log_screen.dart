import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'stock_update_screen.dart';

/// ============================================================
/// HALAMAN LOG TRANSAKSI - Riwayat perubahan stok (Admin only)
/// ============================================================
/// Menampilkan daftar semua transaksi stok yang pernah terjadi.
/// Setiap item menunjukkan:
/// - Nama barang, jenis (masuk/keluar), jumlah
/// - Siapa yang melakukan dan kapan
/// - Badge warna hijau (masuk) / merah (keluar)
/// ============================================================
class TransactionLogScreen extends StatelessWidget {
  const TransactionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: AppBar(
        backgroundColor: context.color.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Transaksi',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface)),
            Text(
              isAdmin
                  ? 'Riwayat semua perubahan stok'
                  : 'Riwayat perubahan stok Anda',
              style: GoogleFonts.inter(
                  fontSize: 11, color: context.color.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Daftar Log
            Expanded(
              child: Consumer<TransactionProvider>(
                builder: (ctx, provider, _) {
                  // Tampilkan loading saat pertama kali memuat dari Firestore
                  if (provider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.color.primary,
                      ),
                    );
                  }

                  // Tampilkan error jika ada
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
                                  fontSize: 14, color: context.color.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(provider.errorMessage!,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  // Admin: lihat semua log | Petugas: data sudah difilter via stream
                  final logs = provider.allLogs;

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: context.color.outline),
                          const SizedBox(height: 16),
                          Text('Belum ada transaksi',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: context.color.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('Transaksi akan muncul saat stok diubah',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.color.onSurfaceVariant.withValues(alpha: 0.7))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) => _buildLogItem(ctx, logs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StockUpdateScreen()),
          );
        },
        backgroundColor: context.color.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(
          'Update Stok',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Widget item log transaksi
  Widget _buildLogItem(BuildContext context, TransactionLog log) {
    final isMasuk = log.type == TransactionType.masuk;
    final color = isMasuk ? AppTheme.success : AppTheme.error;
    final icon = isMasuk
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    // Format waktu: "23 Apr 2026, 14:30"
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    String formattedDate;
    try {
      formattedDate = dateFormat.format(log.waktu);
    } catch (_) {
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(log.waktu);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ikon transaksi
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Info transaksi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama barang + badge tipe
                  Row(
                    children: [
                      Expanded(
                        child: Text(log.productName,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: context.color.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(log.typeLabel,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Detail: stok sebelum → sesudah
                  Text(
                    '${log.stokSebelum} → ${log.stokSesudah} '
                    '(${isMasuk ? '+' : '-'}${log.jumlah})',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: context.color.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  // Siapa & kapan
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(log.userName,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: context.color.onSurfaceVariant)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 13, color: context.color.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: context.color.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
