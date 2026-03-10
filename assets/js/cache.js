---
layout: null
permalink: /cache.js
---

const CACHE_VERSION = 1;
const CACHE_NAME = "assets-cache-" + CACHE_VERSION;

self.addEventListener("install", (event) => {
  self.skipWaiting();
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  const url = new URL(request.url);

  const hash = url.searchParams.get("hash");
  if (hash === null) return;

  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(request).then((cached) => {
        if (cached === undefined) {
          return cache.delete(request, { ignoreSearch: true }).then(() => {
            return fetch(request).then((response) => {
              if (response && response.status === 200) {
                cache.put(request, response.clone());
              }
              return response;
            });
          })
        }
        return cached;
      });
    })
  );
});
