// lib/firebase_options.dart
// ============================================================
// Jordan Audio Forum — Firebase Config (مشروعك الخاص)
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  // إعدادات الويب — مشروع jordan-audio-final
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyARKNYSpoSVZB8789YxjxgValR9o5pRxks',
    appId:             '1:837211758188:web:d631e16b25279287738249',
    messagingSenderId: '837211758188',
    projectId:         'jordan-audio-final',
    storageBucket:     'jordan-audio-final.firebasestorage.app',
  );

  // إعدادات Android — مشروع jordan-audio-final
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyARKNYSpoSVZB8789YxjxgValR9o5pRxks',
    appId:             '1:837211758188:android:d631e16b25279287738249',
    messagingSenderId: '837211758188',
    projectId:         'jordan-audio-final',
    storageBucket:     'jordan-audio-final.firebasestorage.app',
  );

  // إعدادات iOS — مشروع jordan-audio-final
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyARKNYSpoSVZB8789YxjxgValR9o5pRxks',
    appId:             '1:837211758188:ios:d631e16b25279287738249',
    messagingSenderId: '837211758188',
    projectId:         'jordan-audio-final',
    storageBucket:     'jordan-audio-final.firebasestorage.app',
    iosBundleId:       'com.jordanaudioforumx.app',
  );
}
