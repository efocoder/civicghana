const CACHE_NAME = "civicroute-public-v2";
const STATIC_ASSETS = [
  "/",
  "/offline.html",
  "/manifest.json",
  "/icon.png",
  "/icon.svg"
];

self.addEventListener("install", function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener("activate", function(event) {
  event.waitUntil(
    caches.keys().then(function(names) {
      return Promise.all(
        names.filter(function(name) { return name !== CACHE_NAME; })
             .map(function(name) { return caches.delete(name); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener("fetch", function(event) {
  var url = new URL(event.request.url);

  if (event.request.method !== "GET") return;

  if (url.origin !== self.location.origin || event.request.method !== "GET") return;

  if (url.pathname.startsWith("/cases") || url.pathname.startsWith("/assistant") || url.pathname.startsWith("/case_actions") || url.pathname.startsWith("/observations") || url.pathname.startsWith("/admin") || url.pathname.startsWith("/saved")) {
    return;
  }

  if (url.pathname.match(/\.(css|js|png|svg|ico|woff|woff2)$/)) {
    event.respondWith(
      caches.match(event.request).then(function(cached) {
        return cached || fetch(event.request).then(function(response) {
          var clone = response.clone();
          caches.open(CACHE_NAME).then(function(cache) { cache.put(event.request, clone); });
          return response;
        });
      })
    );
    return;
  }

  const isPublicGuide = event.request.mode === "navigate" && (url.pathname === "/" || url.pathname.startsWith("/public_services/"));
  if (!isPublicGuide) return;

  event.respondWith(
    fetch(event.request).then(function(response) {
      if (response.ok) {
        var clone = response.clone();
        caches.open(CACHE_NAME).then(function(cache) { cache.put(event.request, clone); });
      }
      return response;
    }).catch(function() {
      return caches.match(event.request).then(function(cached) {
        return cached || caches.match("/offline.html");
      });
    })
  );
});
