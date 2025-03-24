// Import the functions you need from the SDKs you need
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
firebase.initializeApp({
    apiKey: "AIzaSyDcfFrP7s861I78UTBKX6EsBCExDAOCuZ0",
    authDomain: "pingapp-94e13.firebaseapp.com",
    projectId: "pingapp-94e13",
    storageBucket: "pingapp-94e13.firebasestorage.app",
    messagingSenderId: "607056826389",
    appId: "1:607056826389:web:423f1ad4674d8c5ba6be1c",
    measurementId: "G-3FMTLXTTL8"
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
  playCustomSound();
});
function playCustomSound() {
  const audio = new Audio('assets/sound/beep_sound.mp3');
  audio.play().catch((error) => console.log('Autoplay prevented:', error));
}