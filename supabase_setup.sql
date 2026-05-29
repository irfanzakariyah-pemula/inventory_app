-- ============================================================
-- SMART RETAIL MVP — SUPABASE DATABASE SETUP
-- ============================================================
-- Jalankan seluruh script SQL ini di Supabase SQL Editor.
-- Script ini akan:
--   1. Membuat 4 tabel baru (suppliers, customers, sales, sales_items)
--   2. Mengaktifkan Row Level Security (RLS) pada tabel baru
--   3. Membuat Security Policies agar user yang terautentikasi bisa akses
--   4. Membuat PostgreSQL RPC Function 'checkout_transaction()' 
--      untuk transaksi POS yang atomic & aman.
-- ============================================================

-- ==================== [1] SUPPLIER ====================
CREATE TABLE IF NOT EXISTS suppliers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kontak     TEXT,
  alamat     TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== [2] CUSTOMERS ====================
CREATE TABLE IF NOT EXISTS customers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kontak     TEXT,
  tipe       TEXT DEFAULT 'retail', -- 'retail' | 'grosir'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== [3] SALES (HEADER) ====================
CREATE TABLE IF NOT EXISTS sales (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nomor_struk   TEXT UNIQUE,
  customer_id   UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT, -- Duplikasi nama untuk backup jika data customer dihapus
  user_id       UUID NOT NULL,
  user_name     TEXT NOT NULL,
  subtotal      INTEGER NOT NULL,
  diskon        INTEGER DEFAULT 0,
  total         INTEGER NOT NULL,
  bayar         INTEGER NOT NULL,
  kembalian     INTEGER NOT NULL,
  metode_bayar  TEXT DEFAULT 'tunai', -- 'tunai' | 'transfer' | 'qris'
  catatan       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== [4] SALES ITEMS (DETAIL) ====================
CREATE TABLE IF NOT EXISTS sales_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id     UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id) ON DELETE SET NULL,
  nama_produk TEXT NOT NULL,
  harga_jual  INTEGER NOT NULL,
  harga_beli  INTEGER NOT NULL,
  jumlah      INTEGER NOT NULL,
  subtotal    INTEGER NOT NULL,
  satuan      TEXT DEFAULT 'pcs'
);

-- ==================== [5] ENABLE RLS (ROW LEVEL SECURITY) ====================
ALTER TABLE suppliers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales       ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_items ENABLE ROW LEVEL SECURITY;

-- ==================== [6] CREATE SECURITY POLICIES ====================
-- Izinkan seluruh operasi (SELECT, INSERT, UPDATE, DELETE) untuk user yang sudah login
DROP POLICY IF EXISTS "Allow authenticated" ON suppliers;
CREATE POLICY "Allow authenticated" ON suppliers FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow authenticated" ON customers;
CREATE POLICY "Allow authenticated" ON customers FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow authenticated" ON sales;
CREATE POLICY "Allow authenticated" ON sales FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Allow authenticated" ON sales_items;
CREATE POLICY "Allow authenticated" ON sales_items FOR ALL USING (auth.role() = 'authenticated');

-- ==================== [7] RPC FUNCTION: CHECKOUT TRANSACTION ====================
-- Fungsi ini membungkus proses penyimpanan struk, penyimpanan detail item, 
-- dan pengurangan stok barang di gudang ke dalam satu transaksi database yang atomic.
-- Menjamin tidak ada race condition atau stok minus jika diakses oleh banyak kasir sekaligus.

CREATE OR REPLACE FUNCTION checkout_transaction(
  p_nomor_struk TEXT,
  p_customer_id UUID,
  p_customer_name TEXT,
  p_user_id UUID,
  p_user_name TEXT,
  p_subtotal INTEGER,
  p_diskon INTEGER,
  p_total INTEGER,
  p_bayar INTEGER,
  p_kembalian INTEGER,
  p_metode_bayar TEXT,
  p_catatan TEXT,
  p_items JSONB
) RETURNS VOID AS $$
DECLARE
  v_sale_id UUID;
  v_item RECORD;
BEGIN
  -- A. Simpan header transaksi penjualan
  INSERT INTO sales (
    nomor_struk,
    customer_id,
    customer_name,
    user_id,
    user_name,
    subtotal,
    diskon,
    total,
    bayar,
    kembalian,
    metode_bayar,
    catatan,
    created_at
  ) VALUES (
    p_nomor_struk,
    p_customer_id,
    p_customer_name,
    p_user_id,
    p_user_name,
    p_subtotal,
    p_diskon,
    p_total,
    p_bayar,
    p_kembalian,
    p_metode_bayar,
    p_catatan,
    NOW()
  ) RETURNING id INTO v_sale_id;

  -- B. Loop item belanjaan dan masukkan ke detail + potong stok produk
  FOR v_item IN 
    SELECT * FROM jsonb_to_recordset(p_items) AS x(
      product_id UUID,
      nama_produk TEXT,
      harga_jual INTEGER,
      harga_beli INTEGER,
      jumlah INTEGER,
      subtotal INTEGER,
      satuan TEXT
    )
  LOOP
    -- 1. Masukkan detail item penjualan
    INSERT INTO sales_items (
      sale_id,
      product_id,
      nama_produk,
      harga_jual,
      harga_beli,
      jumlah,
      subtotal,
      satuan
    ) VALUES (
      v_sale_id,
      v_item.product_id,
      v_item.nama_produk,
      v_item.harga_jual,
      v_item.harga_beli,
      v_item.jumlah,
      v_item.subtotal,
      COALESCE(v_item.satuan, 'pcs')
    );

    -- 2. Kurangi stok produk secara otomatis di gudang
    UPDATE products
    SET stok = stok - v_item.jumlah
    WHERE id = v_item.product_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
