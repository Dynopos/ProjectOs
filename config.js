/* =====================================================================
   DYNO PROJECT OS — Tetapan pelanggan
   ---------------------------------------------------------------------
   Satu fail ini sahaja yang berbeza antara setiap pelanggan.
   Isi, simpan, commit. Tiada fail lain perlu diubah.

   Kunci Supabase:  Supabase → Project Settings → API
     · "Project URL"              →  SUPABASE_URL
     · "anon public" / publishable →  SUPABASE_ANON_KEY

   Kunci anon selamat didedahkan dalam browser — RLS dalam supabase.sql hanya
   benarkan pengguna yang sudah log masuk. JANGAN sesekali letak kunci
   "service_role" / "secret" di sini.

   Biarkan kedua-dua kunci kosong untuk MOD DEMO (baca data.json sahaja).
   ===================================================================== */

window.TETAPAN = {
  SUPABASE_URL:      "",
  SUPABASE_ANON_KEY: "",

  // ---- Jenama pelanggan ----
  SYARIKAT:   "SYARIKAT ANDA",      // dipapar besar di sidebar & skrin log masuk
  SUFIKS:     "",                   // cth ".CO", " SDN BHD" — warna emas
  JABATAN:    "Jabatan Projek",
  LOGO:       "",                   // 1–3 huruf dalam kotak logo; kosong = huruf awal SYARIKAT

  // ---- Penomboran ----
  KOD_AWALAN: "PRJ-",               // projek baharu jadi PRJ-01, PRJ-02…

  // ---- Peringkat kerja (kotak semak dalam borang + carta "Aliran kerja") ----
  // [kunci, label]. Kunci disimpan dalam pangkalan data — JANGAN tukar kunci
  // selepas data sudah dimasukkan; label boleh ditukar bila-bila masa.
  PERINGKAT: [
    ["sebutHarga",  "Sebut harga"],
    ["deposit",     "Deposit"],
    ["lukisan",     "Lukisan / kelulusan"],
    ["bahan",       "Bahan dipesan"],
    ["tapak",       "Kerja tapak"],
    ["pemeriksaan", "Pemeriksaan"],
    ["serahan",     "Serahan"],
    ["baki",        "Bayaran akhir"]
  ],

  // ---- Kategori perbelanjaan (tab Perbelanjaan) ----
  KATEGORI_BELANJA: ["Material", "Upah pekerja", "Subkontraktor", "Pengangkutan", "Peralatan", "Lain-lain"]
};
