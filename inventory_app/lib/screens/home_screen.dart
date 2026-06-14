import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/sales_provider.dart';

// Import Screens
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'report_screen.dart';
import 'transaction_log_screen.dart';
import 'profile_screen.dart';

/// ============================================================
/// HALAMAN UTAMA (SHELL) - Menggunakan Bottom Navigation Bar
/// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);

      productProvider.setTransactionProvider(transactionProvider);
      productProvider.startListening();

      final userId = authProvider.isAdmin ? null : authProvider.currentUser?.id;
      transactionProvider.startListening(userId: userId);

      // Fetch data MVP baru
      salesProvider.fetchSales();

      _isInitialized = true;
    }
  }

  // 4 Tab Utama: Beranda, Kasir, Data (Laporan/Log), Profil
  List<Widget> _getPages(bool isAdmin) {
    return [
      const DashboardScreen(),
      const PosScreen(),
      isAdmin ? const ReportScreen() : const TransactionLogScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;
    final pages = _getPages(isAdmin);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.color.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  index: 0,
                  isActive: _currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Kasir',
                  index: 1,
                  isActive: _currentIndex == 1,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Data',
                  index: 2,
                  isActive: _currentIndex == 2,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  index: 3,
                  isActive: _currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    final activeColor = context.color.primary; // Warna merah (sesuai tema)
    final inactiveColor = context.color.onSurfaceVariant.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
