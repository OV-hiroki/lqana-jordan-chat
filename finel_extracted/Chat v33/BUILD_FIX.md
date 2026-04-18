# 🔧 دليل إصلاح مشاكل البيلد — Jordan Audio Forum (Flutter)

## المشاكل التي تم إصلاحها تلقائياً ✅

| المشكلة | الحل |
|---------|------|
| ملف `assets/images/` مفقود | تم إنشاؤه |
| ملفات خط Cairo مفقودة | تم التحويل لـ `google_fonts` package (لا يحتاج ملفات) |
| `android/build.gradle.kts` بدون `google-services` | تم إضافة الـ classpath |
| `android/app/build.gradle.kts` بدون Firebase plugin | تم إضافة `id("com.google.gms.google-services")` |
| `minSdk` منخفض جداً | تم رفعه لـ 21 (Firebase يتطلب ذلك) |
| `AndroidManifest.xml` بدون permissions | تم إضافة INTERNET, RECORD_AUDIO, CAMERA, etc. |

---

## ما تحتاج تعمله يدوياً (إلزامي) ⚠️

### الخطوة 1: استبدل `google-services.json`

الملف الموجود هو template فارغ.
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك → Project Settings → تبويب "Your apps"
3. أضف Android App بـ package name: `com.jordanaudioforumx.app`
4. حمّل `google-services.json` الحقيقي
5. **استبدل** الملف الموجود في `android/app/google-services.json`

### الخطوة 2: حدّث `lib/firebase_options.dart`

استبدل القيم الـ placeholder بالبيانات الحقيقية من Firebase Console:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey:            'AIzaSy...',      // Project Settings → General
  appId:             '1:123456:android:abc',
  messagingSenderId: '123456789',
  projectId:         'your-project-id',
  storageBucket:     'your-project-id.appspot.com',
);
```

### الخطوة 3: حدّث `lib/utils/constants.dart`

```dart
static const String cloudinaryCloudName   = 'YOUR_CLOUD_NAME';    // من Cloudinary Dashboard
static const String cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET'; // من Settings → Upload
```

### الخطوة 4: `local.properties` — يُنشأ تلقائياً

لا تعدّل الملف يدوياً. بمجرد تشغيل:
```bash
flutter pub get
```
Flutter سيعيد إنشاءه بمسار الـ SDK الصحيح على جهازك.

---

## أوامر البيلد

```bash
# من مجلد المشروع الرئيسي
flutter pub get

# بيلد debug APK للاختبار
flutter build apk --debug

# بيلد release APK
flutter build apk --release

# الـ APK يكون في:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## أخطاء شائعة وحلولها

**`flutter.sdk not set in local.properties`**
→ شغّل `flutter pub get` من مجلد المشروع

**`google-services.json` file is missing**
→ نفّذ الخطوة 1 أعلاه

**`Firebase: No Firebase App has been created`**
→ نفّذ الخطوة 2 وتأكد من القيم الصحيحة في `firebase_options.dart`

**`Minimum supported Gradle version is X`**
→ حدّث `gradle-wrapper.properties` أو شغّل `flutter pub get`

**`INSTALL_FAILED_UPDATE_INCOMPATIBLE`**
→ احذف التطبيق القديم من الجهاز وأعد التثبيت
