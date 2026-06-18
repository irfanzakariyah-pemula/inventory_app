import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ExpiredListScreen extends StatefulWidget {
  const ExpiredListScreen({super.key});

  @override
  State<ExpiredListScreen> createState() => _ExpiredListScreenState();
}

class _ExpiredListScreenState extends State<ExpiredListScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: AppBar(
        backgroundColor: context.color.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Mendekati Kedaluwarsa',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.color.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: context.color.onSurface),
            onPressed: () {},
          )
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProv, child) {
          final allExpired = productProv.allProducts.where((p) => p.isMendekatiExpired || p.isSudahExpired).toList();
          
          final day0_7 = allExpired.where((p) => p.sisaHariExpired != null && p.sisaHariExpired! <= 7).toList();
          final day8_15 = allExpired.where((p) => p.sisaHariExpired != null && p.sisaHariExpired! > 7 && p.sisaHariExpired! <= 15).toList();
          final day16_30 = allExpired.where((p) => p.sisaHariExpired != null && p.sisaHariExpired! > 15 && p.sisaHariExpired! <= 30).toList();

          List<Product> displayedList;
          if (_selectedFilter == '0-7 hari') {
            displayedList = day0_7;
          } else if (_selectedFilter == '8-15 hari') {
            displayedList = day8_15;
          } else if (_selectedFilter == '16-30 hari') {
            displayedList = day16_30;
          } else {
            displayedList = allExpired;
          }

          displayedList.sort((a, b) => (a.sisaHariExpired ?? 999).compareTo(b.sisaHariExpired ?? 999));

          return Column(
            children: [
              // ── SUMMARY BOX ──
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${allExpired.length} barang akan expired',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'dalam 30 hari ke depan',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── FILTER CHIPS ──
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _filterChip('Semua', allExpired.length),
                    const SizedBox(width: 8),
                    _filterChip('0-7 hari', day0_7.length),
                    const SizedBox(width: 8),
                    _filterChip('8-15 hari', day8_15.length),
                    const SizedBox(width: 8),
                    _filterChip('16-30 hari', day16_30.length),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),

              // ── LIST ITEMS ──
              Expanded(
                child: displayedList.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada produk di kategori ini.',
                          style: GoogleFonts.inter(fontSize: 13, color: context.color.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: displayedList.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final p = displayedList[index];
                          return _buildExpiredItem(context, p);
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String title, int count) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(
            '$title ($count)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredItem(BuildContext context, Product p) {
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    final isExpired = p.isSudahExpired;
    final sisaHari = p.sisaHariExpired ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: context.color.surfaceContainerLow,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: p.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => Icon(Icons.inventory_2_rounded, color: context.color.outline),
                    )
                  : Icon(Icons.inventory_2_rounded, color: context.color.outline),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: context.color.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'EAN ${p.barcode} • Rak ${p.rakLokasi}',
                  style: GoogleFonts.inter(fontSize: 11, color: context.color.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  isExpired 
                    ? 'EXPIRED: ${DateFormat('dd MMM yyyy').format(p.expiredDate!)}'
                    : 'Expired: ${DateFormat('dd MMM yyyy').format(p.expiredDate!)}',
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    fontWeight: isExpired ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExpired ? 'EXPIRED' : sisaHari.toString(),
                style: GoogleFonts.inter(
                  fontSize: isExpired ? 16 : 22, 
                  fontWeight: FontWeight.w800, 
                  color: const Color(0xFFEF4444)
                ),
              ),
              if (!isExpired)
                Text(
                  'hari lagi',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFDC2626)),
                ),
            ],
          )
        ],
      ),
    );
  }
}
