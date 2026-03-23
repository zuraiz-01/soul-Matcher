importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyCXKZfqhFTSXQpTJHl7Kk-dZyJPrQ5UmYc',
  authDomain: 'soulmatcher-6222a.firebaseapp.com',
  projectId: 'soulmatcher-6222a',
  storageBucket: 'soulmatcher-6222a.firebasestorage.app',
  messagingSenderId: '174540205338',
  appId: '1:174540205338:web:2c73cfa410d946e56410a3',
});

firebase.messaging();
