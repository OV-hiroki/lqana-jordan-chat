// ============================================================
// Jordan Audio Forum — Firebase Config
// ============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError('هذه المنصة غير مدعومة حالياً.');
  }

  // إعدادات الويب
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyARKNYSpoSVZB8789YxjxgValR9o5pRxks',
    appId:             '1:837211758188:web:d631e16b25279287738249',
    messagingSenderId: '837211758188',
    projectId:         'jordan-audio-final',
    storageBucket:     'jordan-audio-final.firebasestorage.app',
  );

  // إعدادات Android مجهزة بالبيانات الخاصة بمشروعك
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyARKNYSpoSVZB8789YxjxgValR9o5pRxks',
    appId:             '1:837211758188:android:d631e16b25279287738249', // استبدل X بالرقم من google-services.json
    messagingSenderId: '837211758188',
    projectId:         'jordan-audio-final',
    storageBucket:     'jordan-audio-final.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'YOUR_IOS_API_KEY', // قم بتحديثها لاحقاً إذا قمت بتصدير التطبيق لـ iOS
    appId:             'YOUR_IOS_APP_ID',
    messagingSenderId: '837211758188',
    projectId:         'jordan-audio-final',
    storageBucket:     'jordan-audio-final.firebasestorage.app',
    iosBundleId:       'com.jordanaudioforumx.app',
  );
}