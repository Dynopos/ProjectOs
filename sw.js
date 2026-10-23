/* Dyno Project OS — Service Worker
   Strategi:
   · data.json & config.js → NETWORK-FIRST  (sentiasa cuba ambil versi terbaru dari GitHub;
                                  guna salinan simpanan bila tiada internet)
   · lain-lain  → CACHE-FIRST    (buka pantas, boleh guna offline)
   Naikkan VERSI setiap kali index.html diubah supaya cache lama dibuang. */

const VERSI = "dyno-v5";
const TERAS = [
  "./",
  "./index.html",
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-maskable-512.png",
  "./apple-touch-icon.png",
  "./xlsx.min.js",
  "./supabase.min.js",
  "./config.js"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(VERSI)
      .then(c => Promise.allSettled(TERAS.map(u => c.add(u))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(k => Promise.all(k.filter(x => x !== VERSI).map(x => caches.delete(x))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;

  const url = new URL(req.url);

  // Panggilan API Supabase — sentiasa terus ke internet, jangan sentuh cache
  if (url.hostname.endsWith(".supabase.co")) return;

  // data.json & config.js — sentiasa cuba internet dahulu (kedua-duanya berubah selepas deploy)
  if (url.pathname.endsWith("data.json") || url.pathname.endsWith("config.js")) {
    e.respondWith(
      fetch(req, { cache: "no-store" })
        .then(res => {
          const salin = res.clone();
          caches.open(VERSI).then(c => c.put(req, salin));
          return res;
        })
        .catch(() => caches.match(req).then(r => r || Response.error()))
    );
    return;
  }

  // selebihnya — cache dahulu, kemudian internet
  e.respondWith(
    caches.match(req).then(r =>
      r || fetch(req).then(res => {
        if (res.ok && url.origin === location.origin) {
          const salin = res.clone();
          caches.open(VERSI).then(c => c.put(req, salin));
        }
        return res;
      }).catch(() => {
        // Hanya halaman (navigasi) jatuh balik ke index.html.
        // Skrip/imej TIDAK boleh dapat HTML — itu punca ralat sintaks.
        if (req.mode === "navigate") return caches.match("./index.html");
        return new Response("", { status: 504, statusText: "Tiada sambungan" });
      })
    )
  );
});

// Paksa kemas kini dari halaman
self.addEventListener("message", e => {
  if (e.data === "KEMASKINI") self.skipWaiting();
});
