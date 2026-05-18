import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'stock_update_screen.dart';
import 'transaction_log_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

/// ============================================================
/// HALAMAN UTAMA (SHELL) - Navigasi Sidebar (Navigation Drawer)
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      productProvider.setTransactionProvider(transactionProvider);
      productProvider.startListening();

      final userId =
          authProvider.isAdmin ? null : authProvider.currentUser?.id;
      transactionProvider.startListening(userId: userId);

      _isInitialized = true;
    }
  }

  List<Widget> _getPages(bool isAdmin) {
    if (isAdmin) {
      return const [
        DashboardScreen(),
        ProductListScreen(),
        TransactionLogScreen(),
      ];
    } else {
      return const [
        DashboardScreen(),
        StockUpdateScreen(),
        TransactionLogScreen(),
      ];
    }
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    Navigator.pop(context);
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;
    final pages = _getPages(isAdmin);
    final user = auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, isAdmin, user),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isAdmin, user) {
    final isDark = context.isDarkMode;

    return Drawer(
      width: 280,
      backgroundColor: isDark ? const Color(0xFF0F1E35) : const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ====== BRAND HEADER ======
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Retail',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Inventory System',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider tipis
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // ====== PROFILE CARD ======
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar dengan initial
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAdmin
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF22C55E), const Color(0xFF15803D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          (user?.nama ?? 'U').substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nama ?? 'User',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                                  : const Color(0xFF22C55E).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAdmin
                                    ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                                    : const Color(0xFF22C55E).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              user?.roleLabel ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isAdmin
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF86EFAC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====== SECTION LABEL ======
            _drawerSectionLabel('MENU UTAMA'),
            const SizedBox(height: 4),

            // ====== MENU NAVIGASI ======
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _drawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      index: 0,
                      description: 'Ringkasan & statistik',
                    ),
                    if (isAdmin)
                      _drawerItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'Master Barang',
                        index: 1,
                        description: 'Kelola produk',
                      )
                    else
                      _drawerItem(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Update Stok',
                        index: 1,
                        description: 'Scan & update stok',
                      ),
                    _drawerItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Log Transaksi',
                      index: 2,
                      description: 'Riwayat perubahan',
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      _drawerSectionLabel('FITUR LAINNYA'),
                      const SizedBox(height: 4),
                      _drawerItemNav(
                        icon: Icons.warning_amber_rounded,
                        label: 'Mendekati Kedaluwarsa',
                        description: 'Monitor tanggal expired',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fitur segera hadir!',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF1E293B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ====== TOGGLE DARK / LIGHT ======
            Consumer<ThemeProvider>(
              builder: (ctx, themeProv, _) {
                final dark = themeProv.isDarkMode;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.09)),
                    ),
                    child: Row(
                      children: [
                        // Icon beranimasi
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            key: ValueKey(dark),
                            color: dark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFFFBBF24),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dark ? 'Mode Gelap' : 'Mode Terang',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                dark
                                    ? 'Ketuk untuk mode terang'
                                    : 'Ketuk untuk mode gelap',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle switch
                        GestureDetector(
                          onTap: () => themeProv.toggleTheme(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: dark
                                      ? const Color(0xFF3B82F6)
                                          .withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              alignment: dark
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ====== VERSI APP ======
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'v1.0.0 • Smart Retail Inventory',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),

            // ====== TOMBOL LOGOUT ======
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.red.shade700.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Keluar dari Akun',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required int index,
    String? description,
  }) {
    final isActive = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _navigateTo(index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? const Color(0xFF93C5FD)
                      : Colors.white.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    if (description != null)
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
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

  Widget _drawerItemNav({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? description,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: color.withValues(alpha: 0.7), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    if (description != null)
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
