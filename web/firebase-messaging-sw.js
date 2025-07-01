// Import the functions you need from the SDKs you need
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
firebase.initializeApp({
    apiKey: "AIzaSyBZmTuB7UejW9oGNkR5-HeGNBY1a93fq9o",
    authDomain: "ping-5657e.firebaseapp.com",
    projectId: "ping-5657e",
    storageBucket: "ping-5657e.firebasestorage.app",
    messagingSenderId: "565573250233",
    appId: "1:565573250233:web:8902c48665d3d66c72ff68"
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((payload) => {
    console.log("onBackgroundMessage", payload);
    const notificationTitle = payload.data?.title || 'Notification';
      const notificationOptions = {
        body: payload.data?.body || payload.data?.message || "",
        icon: "/icons/Icon-192.png",
        data: {
          ...payload.data, // Pass entire data object
          click_action: payload.data?.click_action || self.location.origin,
        },
      };
      self.registration.showNotification(notificationTitle, notificationOptions);
});

function playCustomSound() {
  const audio = new Audio('assets/sound/beep_sound.mp3');
  audio.play().catch((error) => console.log('Autoplay prevented:', error));
}



 //Show notification manually
//self.addEventListener('push', function(event) {
//  if (event.data) {
//    const payload = event.data.json();
//
//    const notificationTitle = payload.data.title || 'Notification';
//    const notificationOptions = {
//      body: payload.data.body || '',
//      icon: payload.data.icon || '/icons/Icon-192.png',
//      data: {
//        click_action: payload.data.click_action || 'https://your-default-url.com'
//      }
//    };
//
//    event.waitUntil(
//      self.registration.showNotification(notificationTitle, notificationOptions)
//    );
//  }
//});



// Handle notification click
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const notificationData = event.notification.data;
  const targetUrl = new URL(event.notification.data.click_action);
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clientList => {
      for (let client of clientList) {
        const clientUrl = new URL(client.url);
        // Reuse existing tab if it's from the same origin
        if (clientUrl.origin === targetUrl.origin) {
          // Send message to existing tab with query params
          client.postMessage({
            type: 'showDialogFromNotification',
            data: notificationData
          });
          return client.focus();
        }
      }
      // If no existing tab, open new one
      if (clients.openWindow) {
        return clients.openWindow(event.notification.data.click_action);
      }
    })
  );
});

