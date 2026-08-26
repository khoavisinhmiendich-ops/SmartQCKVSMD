const CACHE='smart-qc-pwa-v2';
const ASSETS=['./','./index.html','./manifest.webmanifest','./icons/icon-192.png','./icons/icon-512.png','./icons/icon-180.png','./config.js'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener('activate',event=>event.waitUntil(self.clients.claim()));
self.addEventListener('fetch',event=>{
  if(event.request.method!=='GET') return;
  event.respondWith(fetch(event.request).then(res=>{
    if(res && res.ok && new URL(event.request.url).origin===location.origin){ const copy=res.clone(); caches.open(CACHE).then(c=>c.put(event.request,copy)); }
    return res;
  }).catch(()=>caches.match(event.request).then(r=>r||caches.match('./index.html'))));
});
