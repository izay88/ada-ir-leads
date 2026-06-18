self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('ada-ir-leads').then((cache) => {
      return cache.addAll([
        '/ada-ir-leads/',
        '/ada-ir-leads/index.html',
        '/ada-ir-leads/manifest.json',
        '/ada-ir-leads/icon-192.svg',
      ]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then((cached) => {
      const fetchPromise = fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const responseClone = networkResponse.clone();
          caches.open('ada-ir-leads').then((cache) => cache.put(event.request, responseClone));
        }
        return networkResponse;
      }).catch(() => cached);
      return cached || fetchPromise;
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes('/ada-ir-leads/') && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/ada-ir-leads/');
      }
    })
  );
});