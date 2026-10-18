# CLAUDE.md — Konteks Projek

Fail ini untuk Claude Code. Baca dahulu sebelum ubah apa-apa.

---

## Apa ini

**Dyno Project OS** — sistem projek, deposit & pembayaran untuk **kontraktor dan pemaju
pembinaan** di Malaysia. Produk yang dijual kepada banyak pelanggan; setiap pelanggan
dapat salinan sendiri dengan jenama sendiri.

Asal-usul: dibina dahulu untuk Fine Cabinetry.Co (repo `Dynopos/FCmanagement`, kini
pelanggan pertama). Repo ini ialah versi generik — **tiada data atau jenama mana-mana
pelanggan boleh dicommit di sini.**

**Stack:** satu fail HTML statik + Supabase (Postgres) + GitHub Pages + PWA.
Tiada build step. Tiada npm. Tiada framework. Vanilla JS sahaja.

**Bahasa antara muka: Bahasa Melayu.** Semua teks UI, nama pembolehubah dan
nama fungsi dalam BM (`projek`, `bayaran`, `muatData`, `jadualProjek`).
Kekalkan konvensyen ini.

---

## Susunan fail

```
index.html          ← SELURUH aplikasi (HTML + CSS + JS dalam satu fail)
config.js           ← SATU-SATUNYA fail yang berbeza antara pelanggan (jenama, kunci, peringkat)
supabase.sql        ← skema DB, dijalankan sekali dalam Supabase SQL Editor
data.json           ← data contoh REKAAN untuk mod demo (bukan pelanggan sebenar)
manifest.json       ← PWA
sw.js               ← service worker (naikkan VERSI bila index.html berubah!)
supabase.min.js     ← @supabase/supabase-js v2 UMD (vendored, jangan edit)
xlsx.min.js         ← SheetJS 0.18.5 (vendored, jangan edit)
icon-*.png          ← ikon PWA (logo Dyno — jenama produk, bukan pelanggan)
README.md           ← panduan pengguna (BM)
```

**Tiada CDN luar.** Semua pustaka dibundle supaya PWA berfungsi offline.

---

## Tetapan pelanggan — `config.js`

| Medan | Kegunaan |
|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Projek Supabase pelanggan. Kosong = mod demo. |
| `SYARIKAT`, `SUFIKS`, `JABATAN` | Jenama di sidebar & skrin log masuk; juga `document.title`. |
| `LOGO` | 1–3 huruf dalam kotak logo. Kosong = `inisial(SYARIKAT)`. |
| `KOD_AWALAN` | Awalan kod projek (`kodSeterusnya()`, `huraiFlow()`). Lalai `PRJ-`. |
| `PERINGKAT` | `[[kunci,label],…]` — kotak semak borang projek & carta aliran. Tiada = `PERINGKAT_LALAI`. |

**Jenama produk vs jenama pelanggan.** Logo Dyno (ikon PWA, favicon, `<title>` lalai)
ialah jenama produk. Nama di sidebar ialah jenama pelanggan, dari `config.js`.
Jangan campurkan — jangan tulis nama pelanggan terus dalam `index.html`.

**Kunci `PERINGKAT` disimpan dalam `projek.aliran`.** Menukar label selamat; menukar
kunci selepas data wujud menyembunyikan kemajuan sedia ada (data tak hilang, cuma
tak dipapar).

## Model penyewaan (BELUM diputuskan)

Sekarang: **satu projek Supabase + satu deploy GitHub Pages setiap pelanggan.**
Mudah, terasing sepenuhnya, tetapi setiap kemas kini kod perlu dideploy ke setiap
pelanggan. Alternatif: satu Supabase berkongsi dengan `syarikat_id` pada setiap jadual
dan RLS ikut keahlian. Jangan mula ke arah itu tanpa keputusan pemilik — RLS yang
tersilap bermakna pelanggan nampak data pelanggan lain.

## Dua mod operasi

`index.html` menyemak `window.TETAPAN` dari `config.js`:

| Keadaan | Mod | Kelakuan |
|---|---|---|
| `SUPABASE_URL` + `SUPABASE_ANON_KEY` diisi | **Supabase** | Skrin log masuk, CRUD penuh, realtime, log aktiviti |
| Kedua-duanya kosong | **Demo** | Baca `data.json`, butang tambah/edit disembunyikan |

Pemeriksa: `ADA_SB`, `bolehTulis()`. Sentiasa kekalkan mod demo berfungsi —
ia ialah alat jualan: bakal pelanggan nampak sistem penuh tanpa sebarang setup.

---

## Model data

### `projek`
`id` (uuid) · `kod` (unik, cth `PRJ-01`) · `nama` · `klien` · `lokasi` · `telefon` ·
`inv` · `status` · `nilai` (numeric — nilai kontrak) · `mula` (date) · `nota` ·
`aliran` (jsonb) · `dicipta_oleh` · `diubah_oleh` · `created_at` · `updated_at`

### `bayaran`
`id` (uuid) · `projek_id` (FK cascade) · `kod` (FK ke `projek.kod`,
`on update cascade` + `on delete cascade`) · `jenis` · `amaun` · `tarikh` ·
`kaedah` · `ruj` · `status` (`Diterima` / `Menunggu`) · `dicipta_oleh`

**`kod` ialah rujukan sebenar.** `terima(kod)` memadan bayaran dengan projek
melalui medan teks ini, bukan `projek_id`. Menukar kod projek dikendalikan pada
dua peringkat: `simpanProjek()` meminta pengesahan dan melakukan cascade
`update bayaran set kod` melalui `projek_id`, dan constraint FK dalam
`supabase.sql` menangkap apa-apa yang terlepas (baris `projek_id` null,
suntingan terus melalui Table Editor).

### `log_aktiviti`
`id` · `pengguna` · `tindakan` · `butiran` · `created_at` — **insert & select sahaja**,
tiada update/delete (dikuatkuasakan oleh RLS).

### `aliran` (jsonb)
`{ kunci: boolean }` — kunci ditakrif oleh `TETAPAN.PERINGKAT` (lalai: `sebutHarga`,
`deposit`, `lukisan`, `bahan`, `tapak`, `pemeriksaan`, `serahan`, `baki`).
Dipapar sebagai kotak semak dalam borang dan carta "Aliran kerja projek".
`huraiFlow()` menulis kunci format asal Fine Cabinetry (`gambarSblm`, `pasang`…);
kunci yang tiada dalam `PERINGKAT` disimpan tetapi tidak dipapar.

---

## Peraturan pengiraan (JANGAN ubah tanpa sebab kukuh)

```
diterima(kod)   = jumlah bayaran WHERE kod = ? AND status != 'Menunggu'
baki            = nilai − diterima
Total Payment   = Σ nilai (semua projek)
Total Received  = Σ diterima
Pending Payment = Total Payment − Total Received
Deposit Payment = Σ bayaran WHERE jenis ~ /deposit|pendahuluan|advance/i AND status != 'Menunggu'
```

Invarian: **Total Payment = Total Received + Pending Payment**.

### Kategori status — `jenisStatus(s)`
Padanan regex, terima BM **dan** Inggeris:

- `siap` ← `siap|selesai|complete|completed|ended|done|closed|delivered|handover`
- `jalan` ← `progres|progress|ongoing|running|berjalan|jalan|aktif|active|wip|dalam`
- `pending` ← selebihnya

Digunakan oleh kotak Dashboard (Ended / Running / Pending Project) **dan** logik arkib.

---

## Arkib

Projek dengan `jenisStatus(status) === "siap"` **dikecualikan** dari `jadualProjek()`
dan dipaparkan dalam `jadualArkib()` (tab "Projek Siap").
Sebab: senarai utama kekal pendek bila projek dah beratus.

Lencana sidebar: `bg-projek` = kiraan aktif, `bg-arkib` = kiraan siap.
Kotak Dashboard "Ended Project" melompat ke `pergi('arkib')`.

---

## Import Excel — `huraiFlow()` (pilihan) dan `importSekarang()` (lalai)

Untuk kebanyakan pelanggan, **penghurai generik** (`pilihSheet()` → `importSekarang()`,
padanan lajur ikut `KAMUS`) ialah laluan utama. `huraiFlow()` ialah penghurai khas
untuk format "PROJECT FLOW" — format Excel pelanggan pertama — dan dicuba dahulu
kerana ia tidak akan tersalah padan dengan fail lain (ia perlukan tajuk `No.` dan
`Total Project`).

Format PROJECT FLOW (fail asal: `PROJECT LISTING 2026 FCI.xls`, helaian `PROJECT FLOW 2026`
— fail itu **data pelanggan dan TIDAK boleh dicommit ke repo ini**).
**Format ini bukan satu-baris-satu-rekod.** Setiap projek memakan 2–3 baris:

```
Baris A: No | Nama Klien | Alamat | Tarikh Inv | Inv No | DONE… | Total Project(RM)
Baris B:    |            | Telefon|            | RM2,000| RM1,500 …amaun bertaburan…
Baris C:    |            |        |            |        | 10/08/26  ← tarikh bayaran
Baris D: (kosong, pemisah)
```

Peraturan penting:

1. **Lajur "Total Payment By Client(RM)" ialah rujukan muktamad** untuk jumlah diterima.
   Amaun individu dikutip dari baris butiran, kemudian **direkonsiliasi** dengan lajur ini.
2. Amaun **pendua** berlaku (nilai sama muncul dalam dua lajur). Dinyahduplikasi
   dengan membundarkan ke RM terdekat.
3. Tarikh dalam fail ialah **M/D/YY (locale US)**, bukan D/M/Y. Lihat `tkhFC()`.
4. Sel tarikh boleh berada dalam lajur wang — `wangFC()` menolak apa-apa yang
   sepadan corak tarikh.
5. **No. invois berulang** dalam fail pelanggan (`INV09004/2026` dipakai 2 kali).
   Sebab itu `kod` dijana `${KOD_AWALAN}01…NN`, dan `inv` disimpan berasingan.

### Ujian regresi — WAJIB lulus bila `huraiFlow()`/`wangFC()`/`tkhFC()` diubah

Terhadap fail pelanggan pertama (dapatkan dari pemilik; jangan commit):

```
Jumlah nilai kontrak  = RM184,193.00
Jumlah diterima       = RM 83,861.00
Projek                = 10
Bayaran               = 16
```

Kedua-dua jumlah **padan tepat** dengan baris TOTAL dalam Excel pelanggan.
Kalau anda ubah `huraiFlow()`, `wangFC()` atau `tkhFC()`, sahkan semula angka ini.

`importSekarang()` ialah penghurai generik (padanan lajur) untuk fail lain —
`huraiFlow()` dicuba **dahulu**, generik jadi sandaran.

Bila bersambung ke Supabase, kedua-dua laluan import memanggil `keSupabase()`
yang buat `upsert` pada `kod` (ganti, bukan duplikasi).

---

## Reka bentuk

Jenama produk: **hitam & emas**, padan logo Dyno. Pelanggan yang mahu warna lain
hanya perlu menukar pembolehubah dalam `:root` — semua komponen dan carta membacanya.

Warna ditakrif sebagai pembolehubah CSS pada `:root` (gelap, lalai) dan
`:root[data-t="light"]`. **Jangan tulis hex terus dalam CSS atau JS carta** —
gunakan `cv("--nama")` dalam JS SVG.

Warna carta disahkan terhadap semakan kontras/CVD:

- Gelap: `--brand: #b58c24` di atas permukaan `#141310`
- Cerah: `--brand: #9a7213` di atas `#ffffff`

Emas terang (`#d4a437`) hanya untuk **krom UI** (logo, butang, sempadan),
bukan untuk tanda carta — ia gagal jalur kecerahan mod gelap.

Carta ialah SVG buatan tangan (`cartaBar`, `cartaBaris`, `gauge`) —
satu siri, satu warna, corak *hatch* untuk "tiada data". Tiada pustaka carta.

---

## Perkara mudah tersalah

- **Naikkan `VERSI` dalam `sw.js`** setiap kali `index.html` diubah, jika tidak
  pengguna sedia ada terus dapat versi cache lama.
- Semua laluan **relatif** (`./sw.js`, `./manifest.json`) — GitHub Pages
  menghidangkan dari sub-laluan `/nama-repo/`.
- `sw.js` **mesti** langkau hos `*.supabase.co` (jangan cache panggilan API).
- `data.json` **dan `config.js`** guna *network-first*; aset lain *cache-first*.
  `config.js` mesti network-first kerana kunci Supabase diisi selepas deploy —
  kalau di-precache, pengguna sedia ada terperangkap dalam mod demo.
- **Jangan sesekali** letak nilai dalam rentetan JS di dalam atribut HTML
  (`onclick="f('${...}')"`) menggunakan `esc()` sahaja. Entiti HTML seperti
  `&#39;` dinyahkod oleh parser **sebelum** JS diparse, jadi petik tunggal
  tetap menamatkan rentetan dan mematikan butang. Guna `escJS()`.
- Lencana status projek dapat dua kelas: `k-${jenisStatus(s)}` (jaring kategori)
  diikuti `t-${slug(s)}` (padanan tepat). Kelas `k-*` diisytihar **sebelum**
  `t-*` dalam CSS supaya padanan tepat menang; ia wujud supaya status bebas
  seperti `Aktif` atau `WIP` tak jadi lencana tanpa warna. Status **bayaran**
  kekal `slug()` sahaja.
- `_JUM` (cache `terima()`) dibina semula pada permulaan setiap `render()`.
  Kalau anda panggil `terima()` dari laluan yang tak melalui `render()`,
  panggil `binaJumlah()` dahulu.
- `baca()` mencuba `huraiFlow()` dahulu, kemudian jatuh ke `pilihSheet()` →
  `importSekarang()` untuk fail lain. Ketiga-tiga **mesti** wujud serentak —
  buang salah satu dan setiap Excel bukan-PROJECT-FLOW mati senyap.
- Sandaran offline hanya untuk permintaan `navigate` — jika tidak, permintaan
  skrip dapat HTML dan meletup dengan `SyntaxError: Unexpected token '<'`.
- RLS: hanya peranan `authenticated`. Kunci `anon` selamat dalam repo public.
  **Jangan sesekali** commit kunci `service_role`.
- Elakkan menambah kebergantungan npm — projek ini sengaja tiada build step.
- **Tiada data pelanggan dalam repo ini.** Bukan dalam `data.json`, bukan dalam fail
  ujian, bukan dalam mesej commit. PDPA 2010 (Akta 709). Pelajaran dari FCmanagement:
  `data.json` di sana pernah memegang nama, telefon dan alamat klien sebenar dalam
  repo public.
- Jangan commit `CNAME` di sini — domain milik deploy pelanggan, bukan produk.

---

## Keadaan semasa

Siap dan diuji:

- [x] Dashboard — 8 kotak (Total/Ended/Running/Pending Project · Total/Deposit/Pending/Received Payment), boleh klik
- [x] Carta — kutipan bulanan, tolok kemajuan, baki tertinggi, status, aliran kerja
- [x] Projek (aktif) · Projek Siap (arkib) · Pembayaran · Klien
- [x] CRUD penuh + pengesahan padam + cascade
- [x] Log aktiviti tak boleh dipadam
- [x] Realtime — semua klien segar semula bila data berubah
- [x] Import Excel (format pelanggan + generik) → Supabase
- [x] Eksport CSV (projek, arkib, klien)
- [x] PWA — boleh pasang, offline, pintasan
- [x] Tema gelap/cerah
- [x] Mod demo bila Supabase belum disambung
- [x] Jenama pelanggan, awalan kod & peringkat kerja dari `config.js`
- [x] Navigasi mudah alih (laci menu + butang back), kawasan selamat iOS

Belum dibuat / idea seterusnya:

- [ ] Model penyewaan: deploy-setiap-pelanggan vs Supabase berkongsi (lihat atas)
- [ ] Peranan (staf vs management) — sekarang semua pengguna sah boleh edit
- [ ] Sokongan pemaju: unit / blok / fasa di bawah satu projek
- [ ] Bayaran progres ikut peratusan kerja (claim / interim certificate)
- [ ] Jana invois PDF
- [ ] Notifikasi WhatsApp bila deposit masuk
- [ ] Muat naik gambar sebelum/selepas (Supabase Storage)
- [ ] Laporan bulanan / eksport untuk cukai
- [ ] Ringkasan jualan bulanan (helaian Excel asal ada blok `SALES JANUARY =>` yang belum digunakan)

---

## Ujian

Tiada rangka kerja ujian. Pengesahan dibuat dengan Playwright secara ad-hoc.
Bila mengubah logik pengiraan atau import, sekurang-kurangnya sahkan:

1. Import fail PROJECT FLOW (jika `huraiFlow()` diubah) → jumlah masih RM184,193 / RM83,861
2. Tambah projek → kod auto bertambah, deposit awal terhasil sebagai rekod bayaran
3. Tukar status ke Siap → projek berpindah dari senarai utama ke arkib
4. Padam projek → bayaran berkaitan turut dipadam
5. Mod demo (config kosong) → tiada ralat konsol, butang tulis tersembunyi
6. Tukar `SYARIKAT`, `KOD_AWALAN`, `PERINGKAT` dalam config → sidebar, kod baharu
   dan kotak semak semuanya ikut
