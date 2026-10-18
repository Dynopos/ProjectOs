-- =====================================================================
--  DYNO PROJECT OS — Skema Database Supabase (satu projek Supabase setiap pelanggan)
--  Cara guna: buka Supabase → SQL Editor → New query → tampal SEMUA ini
--             → tekan RUN. Selamat dijalankan berulang kali.
-- =====================================================================

-- ---------- 1. JADUAL PROJEK ----------
create table if not exists public.projek (
  id          uuid primary key default gen_random_uuid(),
  kod         text not null unique,
  nama        text not null,
  klien       text,
  lokasi      text,
  telefon     text,
  inv         text,
  status      text not null default 'Baru',
  nilai       numeric(12,2) not null default 0,
  mula        date,
  nota        text,
  aliran      jsonb not null default '{}'::jsonb,
  dicipta_oleh text,
  diubah_oleh  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------- 2. JADUAL BAYARAN ----------
create table if not exists public.bayaran (
  id          uuid primary key default gen_random_uuid(),
  projek_id   uuid references public.projek(id) on delete cascade,
  kod         text not null,
  jenis       text not null default 'Deposit',
  amaun       numeric(12,2) not null default 0,
  tarikh      date,
  kaedah      text,
  ruj         text,
  status      text not null default 'Diterima',
  dicipta_oleh text,
  created_at  timestamptz not null default now()
);

-- ---------- 3. LOG AKTIVITI ----------
create table if not exists public.log_aktiviti (
  id         bigserial primary key,
  pengguna   text not null default auth.email(),
  tindakan   text,
  butiran    text,
  created_at timestamptz not null default now()
);

-- ---------- 4. INDEKS ----------
create index if not exists idx_bayaran_kod    on public.bayaran(kod);
create index if not exists idx_bayaran_projek on public.bayaran(projek_id);
create index if not exists idx_projek_status  on public.projek(status);
create index if not exists idx_log_masa       on public.log_aktiviti(created_at desc);

-- ---------- 5. AUTO updated_at ----------
create or replace function public.sentuh_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_projek_updated on public.projek;
create trigger trg_projek_updated before update on public.projek
  for each row execute function public.sentuh_updated_at();

-- ---------- 6. KEAMANAN (RLS) ----------
-- Sesiapa yang BERJAYA LOG MASUK boleh baca & tulis.
-- Orang luar tanpa akaun tak boleh sentuh apa-apa.
alter table public.projek       enable row level security;
alter table public.bayaran      enable row level security;
alter table public.log_aktiviti enable row level security;

drop policy if exists "pengguna sah - projek"  on public.projek;
create policy "pengguna sah - projek"  on public.projek
  for all to authenticated using (true) with check (true);

drop policy if exists "pengguna sah - bayaran" on public.bayaran;
create policy "pengguna sah - bayaran" on public.bayaran
  for all to authenticated using (true) with check (true);

-- Log: semua boleh baca & tambah, TIADA sesiapa boleh padam atau ubah.
-- `pengguna` diisi oleh pelayan dari auth.email() dan polisi menolak nilai lain,
-- jadi pengguna tak boleh merekod log atas nama orang lain melalui konsol browser.
drop policy if exists "log - baca"    on public.log_aktiviti;
create policy "log - baca"    on public.log_aktiviti
  for select to authenticated using (true);

drop policy if exists "log - tambah"  on public.log_aktiviti;
create policy "log - tambah"  on public.log_aktiviti
  for insert to authenticated with check (pengguna = auth.email());

-- Pastikan default terpakai walaupun jadual sudah wujud dari versi lama
alter table public.log_aktiviti alter column pengguna set default auth.email();

-- ---------- 6a. KEBENARAN JADUAL (eksplisit, jangan bergantung pada default) ----------
-- Supabase biasanya beri GRANT ini secara automatik, tetapi menyatakannya di sini
-- menjadikan skema lengkap sendiri dan tidak pecah jika default projek diubah.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.projek  to authenticated;
grant select, insert, update, delete on public.bayaran to authenticated;

-- Log aktiviti: HANYA baca & tambah. Tiada UPDATE, tiada DELETE — untuk sesiapa.
-- Ini lapisan kedua di atas RLS: walaupun polisi tersilap tulis, log tetap kekal.
grant select, insert on public.log_aktiviti to authenticated;
grant usage, select on sequence public.log_aktiviti_id_seq to authenticated;
revoke update, delete on public.log_aktiviti from authenticated, anon;

-- ---------- 6b. PEMBAIKAN DATA (selamat, boleh diulang) ----------
-- Ikat semula sebarang bayaran yang projek_id-nya kosong tetapi kodnya padan.
-- Baris begini boleh wujud dari import versi awal, dan ia yang paling mudah
-- jadi yatim bila kod projek ditukar.
update public.bayaran b
   set projek_id = p.id
  from public.projek p
 where b.projek_id is null
   and b.kod = p.kod;

-- Laporan: bayaran yang TIADA projek sepadan langsung (perlu perhatian manual)
do $$
declare n int;
begin
  select count(*) into n from public.bayaran b
   where not exists (select 1 from public.projek p where p.kod = b.kod);
  if n > 0 then
    raise notice 'AMARAN: % rekod bayaran tiada projek sepadan. Semak jadual Pembayaran.', n;
  end if;
end $$;

-- ---------- 6c. IKAT BAYARAN PADA KOD PROJEK ----------
-- simpanProjek() sudah melakukan cascade `update bayaran set kod` ikut kod lama.
-- Constraint ini ialah lapisan kedua: ia menangkap suntingan yang tidak melalui
-- aplikasi — contohnya Table Editor dalam Supabase — dan menjadikan keadaan
-- yatim mustahil, bukan sekadar tidak dijangka.
--   on update cascade  → tukar kod projek, bayaran ikut serentak
--   on delete cascade  → padam projek, bayaran turut dipadam
-- Dijalankan SELEPAS 6b supaya projek_id yang kosong sudah diisi dahulu.
-- Kalau masih ada bayaran tanpa projek sepadan, constraint DILANGKAU dan skrip
-- beritahu — rekod kewangan tidak sekali-kali dipadam secara automatik di sini.
do $$
declare n int;
begin
  select count(*) into n from public.bayaran b
   where not exists (select 1 from public.projek p where p.kod = b.kod);
  if n > 0 then
    raise notice 'Constraint bayaran_kod_fkey DILANGKAU: % rekod bayaran tiada projek sepadan. Betulkan dalam tab Pembayaran, kemudian jalankan skrip ini semula.', n;
    return;
  end if;

  alter table public.bayaran
    add constraint bayaran_kod_fkey
    foreign key (kod) references public.projek(kod)
    on update cascade on delete cascade;
exception when duplicate_object then null; end $$;

-- ---------- 7. REALTIME (semua nampak perubahan serta-merta) ----------
-- Tangkap SEMUA ralat di sini: kalau projek anda tiada publication realtime,
-- sistem tetap berfungsi (cuma perlu tekan butang muat semula untuk lihat
-- perubahan orang lain). Jangan biarkan ia menggagalkan keseluruhan skrip.
do $$ begin
  alter publication supabase_realtime add table public.projek;
exception when others then raise notice 'Realtime dilangkau untuk projek: %', sqlerrm; end $$;
do $$ begin
  alter publication supabase_realtime add table public.bayaran;
exception when others then raise notice 'Realtime dilangkau untuk bayaran: %', sqlerrm; end $$;

-- =====================================================================
--  SELESAI.
--
--  LANGKAH SETERUSNYA — cipta akaun untuk pasukan anda:
--  Authentication → Users → "Add user" → "Create new user"
--  Isi emel + kata laluan, TANDA "Auto Confirm User".
--  Ulang untuk setiap staf & top management.
--
--  PENTING: Authentication → Providers → Email →
--           MATIKAN "Enable sign ups"
--           supaya orang luar tak boleh daftar sendiri.
-- =====================================================================
