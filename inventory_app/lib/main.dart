// ============================================================
// MAIN.DART - Entry point aplikasi Smart Retail Inventory
// ============================================================
// 1. Inisialisasi Supabase sebelum runApp
// 2. Setup MultiProvider (state management global)
//    - AuthProvider, ProductProvider, TransactionProvider
//    - SupplierProvider, CustomerProvider, SalesProvider  ← MVP baru
//    - ThemeProvider (dark/light mode)
// 3. Konfigurasi tema Material 3 via AppTheme (light & dark)
// 4. Halaman awal: Login
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import theme
import 'theme/app_theme.dart';

// Import semua provider
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/sales_provider.dart';

// Import halaman awal
import 'screens/login_screen.dart';

/// Fungsi utama — entry point aplikasi Flutter.
void main() async {
  // Flutter binding harus diinisialisasi sebelum async call
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal lokal (untuk bahasa Indonesia / id_ID)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase sebelum menjalankan app
  await Supabase.initialize(
    url: 'https://rpczhekymdntopgzielj.supabase.co',
    anonKey: 'sb_publishable_zpXLrTjuj7XjtyGxOI9ILg_2POUFKsL',
  );

  runApp(const MyApp());
}

/// Shortcut global untuk mengakses Supabase client dari mana saja.
/// Contoh penggunaan: supabase.from('products').select()
final supabase = Supabase.instance.client;

/// Widget root aplikasi.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider harus paling atas agar bisa diakses dari mana saja
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        // MVP Smart Retail — provider baru
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Smart Retail Inventory',
            debugShowCheckedModeBanner: false,

            // Gunakan AppTheme yang sudah terdefinisi di app_theme.dart
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
