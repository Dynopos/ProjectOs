# Dyno Project OS

Sistem projek, deposit dan pembayaran untuk **kontraktor dan pemaju pembinaan**.
Semua nilai kontrak, kutipan dan baki dikira automatik. Boleh dipasang sebagai app
di telefon, berfungsi offline, dan setiap perubahan direkod dalam log yang tak boleh dipadam.

**Tiada server untuk diselenggara.** Satu fail statik di GitHub Pages + pangkalan data
Supabase. Kos hosting: percuma untuk kebanyakan syarikat.

---

## Apa yang pelanggan dapat

| | |
|---|---|
| **Dashboard** | 8 kotak: Total / Ended / Running / Pending Project · Total / Deposit / Pending / Received Payment — setiap satu boleh diklik |
| **Carta** | Kutipan bulanan, tolok kemajuan, baki tertinggi, status, aliran kerja |
| **Projek & arkib** | Projek siap keluar automatik ke tab berasingan — senarai utama kekal pendek |
| **Pembayaran** | Deposit, progres, baki akhir; status *Menunggu* untuk cek belum jelas |
| **Klien** | Ringkasan setiap klien — nilai, kutipan, baki |
| **Perbelanjaan** | Material, upah, subkon, pengangkutan, peralatan — dengan gambar resit terus dari kamera telefon dan nama staf yang merekod |
| **Baki terkini** | Angka besar di atas Dashboard: duit masuk − perbelanjaan, keseluruhan atau ikut projek |
| **Aliran kerja** | Peringkat kerja sendiri (sebut harga → serahan), boleh ditetapkan setiap syarikat |
| **Import Excel** | Padanan lajur automatik — masukkan data lama sekali gus |
| **Eksport CSV** | Projek, arkib, klien |
| **Log aktiviti** | Siapa, bila, apa — tak boleh diubah atau dipadam |
| **Realtime** | Staf key-in di tapak, pengurusan nampak dalam beberapa saat |
| **PWA** | Ikon di skrin utama iPhone & Android, buka tanpa browser, boleh baca offline |

---

## Pasang untuk pelanggan baharu (~20 minit)

Setiap pelanggan dapat salinan sendiri — data mereka terasing sepenuhnya.

### 1. Salin repo

GitHub → **Use this template** (atau fork) → nama cth `syarikat-abc-projek` → Public.

### 2. Supabase

1. [supabase.com](https://supabase.com) → **New project** → region **Southeast Asia (Singapore)**
2. **SQL Editor** → **New query** → tampal seluruh `supabase.sql` → **Run** → mesti keluar *Success*
   (skrip ini juga mencipta storan peribadi `resit` untuk gambar resit — tiada langkah tambahan)
3. **Authentication → Providers → Email** → **biarkan provider hidup**, matikan **Enable sign ups** sahaja
4. **Authentication → Users → Add user** untuk setiap staf, tanda **Auto Confirm User**

### 3. `config.js` — satu-satunya fail yang diubah

```js
SUPABASE_URL:      "https://xxxx.supabase.co",
SUPABASE_ANON_KEY: "eyJhbGciOi…",          // anon / publishable — BUKAN service_role
SYARIKAT:   "SYARIKAT ABC",
SUFIKS:     " SDN BHD",
JABATAN:    "Jabatan Projek",
KOD_AWALAN: "ABC-",
PERINGKAT: [ ["sebutHarga","Sebut harga"], ["deposit","Deposit"], … ]
```

`PERINGKAT` ialah aliran kerja syarikat itu. Label boleh ditukar bila-bila masa;
**kunci jangan ditukar** selepas data dimasukkan.

### 4. GitHub Pages

**Settings → Pages** → Deploy from a branch → `main` / `(root)`.

Domain sendiri (pilihan): rekod DNS `CNAME  projek  →  <akaun-github>.github.io`,
tunggu ia merebak, **baru** tambah domain dalam Settings → Pages dan tandakan
*Enforce HTTPS*. Menambah domain sebelum DNS sedia menjadikan tapak nampak rosak.

### 5. Data lama

Log masuk → **Import Excel** → muat naik → semak pratonton → **Import**.

---

## Mod demo

Biarkan kunci Supabase kosong dalam `config.js` — sistem membaca `data.json`
(projek pembinaan rekaan) dan menyembunyikan butang tulis. Sesuai untuk tunjuk
kepada bakal pelanggan tanpa sebarang setup.

## Kemas kini kod

Setiap kali `index.html` berubah, naikkan `VERSI` dalam `sw.js` — jika tidak, pengguna
yang sudah pasang app terus nampak versi lama.

## Pasang app di telefon

- **iPhone:** Safari (bukan Chrome) → Kongsi ⬆️ → *Add to Home Screen*
- **Android:** butang **⤓ Pasang App** muncul sendiri di bar atas

## Data peribadi (PDPA)

Sistem menyimpan nama, telefon dan alamat klien pelanggan anda. Data itu tinggal dalam
projek Supabase pelanggan — **jangan sesekali** letak data sebenar dalam `data.json`
atau mana-mana fail dalam repo public.
