// ============================================================
// SCREEN KONTAK — Tab Supplier & Pelanggan
// ============================================================
// Satu screen dengan 2 tab:
//   Tab 1: Daftar Supplier (vendor/pemasok barang)
//   Tab 2: Daftar Pelanggan (konsumen)
//
// Setiap tab memiliki:
//   - Search bar
//   - ListView card dengan info + tombol edit/hapus
//   - FAB → BottomSheet form tambah/edit (tanpa screen terpisah)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/supplier_provider.dart';
import '../providers/customer_provider.dart';
import '../models/supplier_model.dart';
import '../models/customer_model.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _supplierSearch = TextEditingController();
  final TextEditingController _customerSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch data saat screen dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupplierProvider>(context, listen: false).fetchSuppliers();
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supplierSearch.dispose();
    _customerSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.surface,
      appBar: _buildAppBar(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupplierTab(context),
          _buildCustomerTab(context),
        ],
      ),
      floatingActionButton: _buildFAB(context),
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
            child: const Icon(Icons.contacts_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Kontak',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: context.color.primary,
        unselectedLabelColor: context.color.onSurfaceVariant,
        indicatorColor: context.color.primary,
        indicatorWeight: 2,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(icon: Icon(Icons.local_shipping_rounded, size: 18), text: 'Supplier'),
          Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Pelanggan'),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        if (_tabController.index == 0) {
          _showSupplierForm(context);
        } else {
          _showCustomerForm(context);
        }
      },
      backgroundColor: context.color.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        _tabController.index == 0 ? 'Tambah Supplier' : 'Tambah Pelanggan',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ============================================================
  // TAB SUPPLIER
  // ============================================================

  Widget _buildSupplierTab(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSearchBar(
              controller: _supplierSearch,
              hint: 'Cari supplier...',
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: _buildSupplierList(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierList(BuildContext context, SupplierProvider provider) {
    final results = provider.searchSuppliers(_supplierSearch.text);

    if (results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        title: _supplierSearch.text.isEmpty
            ? 'Belum ada supplier'
            : 'Supplier tidak ditemukan',
        subtitle: _supplierSearch.text.isEmpty
            ? 'Tambah supplier pertama Anda dengan tombol di bawah'
            : 'Coba kata kunci lain',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchSuppliers,
      color: context.color.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: results.length,
        itemBuilder: (context, index) =>
            _buildSupplierCard(context, results[index], provider),
      ),
    );
  }

  Widget _buildSupplierCard(
      BuildContext context, Supplier supplier, SupplierProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.color.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.color.primary.withValues(alpha: 0.8),
                  context.color.secondary
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                supplier.nama.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.nama,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.color.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (supplier.kontak != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 12, color: context.color.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        supplier.kontak!,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
                if (supplier.alamat != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 12, color: context.color.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier.alamat!,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: context.color.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              _iconBtn(
                icon: Icons.edit_rounded,
                color: context.color.primary,
                onTap: () => _showSupplierForm(context, supplier: supplier),
              ),
              const SizedBox(width: 4),
              _iconBtn(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.error,
                onTap: () => _confirmDelete(
                  context,
                  label: supplier.nama,
                  onConfirm: () => provider.deleteSupplier(supplier.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB PELANGGAN
  // ============================================================

  Widget _buildCustomerTab(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSearchBar(
              controller: _customerSearch,
              hint: 'Cari pelanggan...',
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: _buildCustomerList(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerList(BuildContext context, CustomerProvider provider) {
    final results = provider.searchCustomers(_customerSearch.text);

    if (results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_outline_rounded,
        title: _customerSearch.text.isEmpty
            ? 'Belum ada pelanggan'
            : 'Pelanggan tidak ditemukan',
        subtitle: _customerSearch.text.isEmpty
            ? 'Tambah pelanggan pertama Anda dengan tombol di bawah'
            : 'Coba kata kunci lain',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchCustomers,
      color: context.color.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: results.length,
        itemBuilder: (context, index) =>
            _buildCustomerCard(context, results[index], provider),
      ),
    );
  }

  Widget _buildCustomerCard(
      BuildContext context, Customer customer, CustomerProvider provider) {
    final isGrosir = customer.tipe == 'grosir';
    final badgeColor = isGrosir ? AppTheme.warning : AppTheme.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.color.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isGrosir
                    ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                    : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                customer.nama.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.nama,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.color.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        customer.tipeLabel,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor),
                      ),
                    ),
                  ],
                ),
                if (customer.kontak != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 12, color: context.color.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        customer.kontak!,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              _iconBtn(
                icon: Icons.edit_rounded,
                color: context.color.primary,
                onTap: () => _showCustomerForm(context, customer: customer),
              ),
              const SizedBox(width: 4),
              _iconBtn(
                icon: Icons.delete_outline_rounded,
                color: AppTheme.error,
                onTap: () => _confirmDelete(
                  context,
                  label: customer.nama,
                  onConfirm: () => provider.deleteCustomer(customer.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET FORMS
  // ============================================================

  void _showSupplierForm(BuildContext context, {Supplier? supplier}) {
    final isEdit = supplier != null;
    final namaCtrl = TextEditingController(text: supplier?.nama);
    final kontakCtrl = TextEditingController(text: supplier?.kontak);
    final alamatCtrl = TextEditingController(text: supplier?.alamat);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFormSheet(
        title: isEdit ? 'Edit Supplier' : 'Tambah Supplier',
        formKey: formKey,
        fields: [
          _formField(
            controller: namaCtrl,
            label: 'Nama Supplier',
            hint: 'Contoh: PT Maju Bersama',
            icon: Icons.business_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: kontakCtrl,
            label: 'No. Kontak (opsional)',
            hint: 'Contoh: 0812-3456-7890',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _formField(
            controller: alamatCtrl,
            label: 'Alamat (opsional)',
            hint: 'Contoh: Jl. Raya No. 123, Jakarta',
            icon: Icons.location_on_rounded,
            maxLines: 2,
          ),
        ],
        onSave: () async {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(context);
          final prov =
              Provider.of<SupplierProvider>(context, listen: false);
          final data = Supplier(
            id: supplier?.id ?? '',
            nama: namaCtrl.text.trim(),
            kontak: kontakCtrl.text.trim().isEmpty
                ? null
                : kontakCtrl.text.trim(),
            alamat: alamatCtrl.text.trim().isEmpty
                ? null
                : alamatCtrl.text.trim(),
            createdAt: supplier?.createdAt ?? DateTime.now(),
          );
          final success = isEdit
              ? await prov.updateSupplier(data)
              : await prov.addSupplier(data);
          if (context.mounted) {
            _showSnackbar(
              context,
              success
                  ? (isEdit
                      ? 'Supplier berhasil diperbarui'
                      : 'Supplier berhasil ditambahkan')
                  : (prov.errorMessage ?? 'Terjadi kesalahan'),
              isError: !success,
            );
          }
        },
      ),
    );
  }

  void _showCustomerForm(BuildContext context, {Customer? customer}) {
    final isEdit = customer != null;
    final namaCtrl = TextEditingController(text: customer?.nama);
    final kontakCtrl = TextEditingController(text: customer?.kontak);
    String selectedTipe = customer?.tipe ?? 'retail';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => _buildFormSheet(
          title: isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
          formKey: formKey,
          fields: [
            _formField(
              controller: namaCtrl,
              label: 'Nama Pelanggan',
              hint: 'Contoh: Budi Santoso',
              icon: Icons.person_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            _formField(
              controller: kontakCtrl,
              label: 'No. Kontak (opsional)',
              hint: 'Contoh: 0812-3456-7890',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            // Tipe Pelanggan Toggle
            Text(
              'Tipe Pelanggan',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.color.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _tipeButton(
                    ctx,
                    label: 'Retail',
                    icon: Icons.person_rounded,
                    isSelected: selectedTipe == 'retail',
                    color: AppTheme.info,
                    onTap: () => setModalState(() => selectedTipe = 'retail'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tipeButton(
                    ctx,
                    label: 'Grosir',
                    icon: Icons.store_rounded,
                    isSelected: selectedTipe == 'grosir',
                    color: AppTheme.warning,
                    onTap: () => setModalState(() => selectedTipe = 'grosir'),
                  ),
                ),
              ],
            ),
          ],
          onSave: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(context);
            final prov =
                Provider.of<CustomerProvider>(context, listen: false);
            final data = Customer(
              id: customer?.id ?? '',
              nama: namaCtrl.text.trim(),
              kontak: kontakCtrl.text.trim().isEmpty
                  ? null
                  : kontakCtrl.text.trim(),
              tipe: selectedTipe,
              createdAt: customer?.createdAt ?? DateTime.now(),
            );
            final success = isEdit
                ? await prov.updateCustomer(data)
                : await prov.addCustomer(data);
            if (context.mounted) {
              _showSnackbar(
                context,
                success
                    ? (isEdit
                        ? 'Pelanggan berhasil diperbarui'
                        : 'Pelanggan berhasil ditambahkan')
                    : (prov.errorMessage ?? 'Terjadi kesalahan'),
                isError: !success,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFormSheet({
    required String title,
    required GlobalKey<FormState> formKey,
    required List<Widget> fields,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.color.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                ...fields,
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onSave,
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 14, color: context.color.onSurfaceVariant),
          prefixIcon:
              Icon(Icons.search_rounded, color: context.color.onSurfaceVariant),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: 18, color: context.color.onSurfaceVariant),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.color.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 40, color: context.color.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.color.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _tipeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.color.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : context.color.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? color : context.color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  void _confirmDelete(BuildContext context,
      {required String label, required Future<bool> Function() onConfirm}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus Data?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Anda yakin ingin menghapus "$label"?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: context.color.onSurfaceVariant)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await onConfirm();
              if (context.mounted) {
                _showSnackbar(
                  context,
                  success ? 'Data berhasil dihapus' : 'Gagal menghapus data',
                  isError: !success,
                );
              }
            },
            child: Text('Hapus',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
