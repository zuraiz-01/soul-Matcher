
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Fuchsia is not supported by Firebase.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXKZfqhFTSXQpTJHl7Kk-dZyJPrQ5UmYc',
    appId: '1:174540205338:web:2c73cfa410d946e56410a3',
    messagingSenderId: '174540205338',
    projectId: 'soulmatcher-6222a',
    authDomain: 'soulmatcher-6222a.firebaseapp.com',
    storageBucket: 'soulmatcher-6222a.firebasestorage.app',
    measurementId: 'G-KPGZNWNHW3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAA1IbsVdiUvK8bCXwCN6xevzpGxyHkeh8',
    appId: '1:174540205338:android:adc2a9b68699ed936410a3',
    messagingSenderId: '174540205338',
    projectId: 'soulmatcher-6222a',
    storageBucket: 'soulmatcher-6222a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAfdIy8nhWxcrfrY4vm7ua6yZyP0utLAdo',
    appId: '1:174540205338:ios:79cbc9c440e129b76410a3',
    messagingSenderId: '174540205338',
    projectId: 'soulmatcher-6222a',
    storageBucket: 'soulmatcher-6222a.firebasestorage.app',
    iosBundleId: 'com.example.soulMatcher',
    iosClientId:
        '174540205338-dqt12punhdae79gjhu3ggfp907hatq9q.apps.googleusercontent.com',
  );
}
