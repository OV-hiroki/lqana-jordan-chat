# 🚀 دليل تشغيل Jordan Audio Forum — Flutter

## الخطوة 1: تثبيت Flutter

```bash
# Windows
winget install Flutter.Flutter

# أو من الموقع الرسمي
# https://docs.flutter.dev/get-started/install
```

تحقق من التثبيت:
```bash
flutter doctor
```
> يجب أن يكون كل شيء ✅ ما عدا Chrome وXcode لو بتشتغل على Android فقط

---

## الخطوة 2: إعداد Firebase

1. اذهب إلى [console.firebase.google.com](https://console.firebase.google.com)
2. أنشئ مشروع جديد (أو استخدم مشروعك القديم)
3. فعّل **Authentication** → Email/Password
4. فعّل **Firestore Database** → Start in test mode
5. أضف تطبيق **Android** و**iOS**
6. حمّل `google-services.json` وضعه في `android/app/`
7. حمّل `GoogleService-Info.plist` وضعه في `ios/Runner/`

### أضف بيانات Firebase في `lib/firebase_options.dart`:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey:            'AIza...',       // من Project Settings
  appId:             '1:...',
  messagingSenderId: '...',
  projectId:         'your-project-id',
  storageBucket:     'your-project-id.appspot.com',
);
```

---

## الخطوة 3: إعداد Cloudinary

1. أنشئ حساب مجاني على [cloudinary.com](https://cloudinary.com)
2. من Dashboard انسخ **Cloud Name**
3. اذهب إلى Settings → Upload → Add upload preset
   - اختر **Unsigned** للنوع
4. افتح `lib/utils/constants.dart` وغيّر:

```dart
static const String cloudinaryCloudName    = 'your-cloud-name';
static const String cloudinaryUploadPreset = 'your-preset-name';
```

---

## الخطوة 4: إضافة UID الأدمن

بعد تسجيل حسابك في التطبيق، اذهب إلى Firebase Console → Authentication وانسخ الـ UID، ثم افتح `lib/utils/constants.dart`:

```dart
static const List<String> adminUids = [
  'YOUR_UID_HERE',   // UID الخاص بك
];
```

---

## الخطوة 5: إنشاء Document الـ Kill-Switch في Firestore

في Firestore Console، أنشئ يدوياً:
```
Collection: app_status
Document:   global_config
Fields:
  isLocked             → false  (Boolean)
  lockMessage          → ""     (String)
  isRegistrationOpen   → true   (Boolean)
```

---

## الخطوة 6: تشغيل التطبيق

```bash
# تثبيت الحزم
flutter pub get

# تشغيل على Android Emulator أو جهاز حقيقي
flutter run

# بناء APK للتجربة
flutter build apk --debug

# بناء APK للإنتاج
flutter build apk --release
```

---

## هيكل الملفات

```
lib/
├── main.dart                          نقطة الدخول
├── firebase_options.dart              إعدادات Firebase
├── theme/
│   ├── app_colors.dart                نظام الألوان
│   └── app_theme.dart                 ThemeData الكامل
├── utils/
│   └── constants.dart                 الثوابت + ADMIN_UIDS + Cloudinary
├── models/
│   ├── user_model.dart
│   └── room_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── cloudinary_service.dart
├── providers/
│   ├── auth_provider.dart             حالة المصادقة
│   └── app_provider.dart              Kill-Switch
├── navigation/
│   └── app_router.dart                GoRouter
├── widgets/
│   └── shared_widgets.dart            Button, Input, Avatar, RoomCard...
└── screens/
    ├── lock_screen.dart
    ├── main_shell.dart
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   └── create_room_sheet.dart
    ├── room/
    │   └── room_screen.dart
    ├── profile/
    │   └── profile_screen.dart
    └── admin/
        └── admin_screen.dart
```

---

## ⚠️ البث الصوتي الحقيقي

الـ UI مكتمل بالكامل لكن الصوت الحقيقي يحتاج مكتبة خارجية.

الخيار الموصى به: **Agora Flutter SDK**

```yaml
# أضف في pubspec.yaml
agora_rtc_engine: ^6.3.0
```

```dart
// في room_screen.dart، أضف عند الدخول:
await RtcEngine.create(appId);
await RtcEngine.joinChannel(token, roomId, null, uid);

// عند الكتم:
await RtcEngine.muteLocalAudioStream(isMuted);

// عند الخروج:
await RtcEngine.leaveChannel();
```

احصل على App ID من [agora.io](https://agora.io) — مجاني حتى 10,000 دقيقة/شهر.

---

## Firebase Security Rules (مهم للأمان)

في Firestore Console → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /rooms/{roomId} {
      allow read, write: if request.auth != null;
    }
    match /app_status/{doc} {
      allow read: if true;
      allow write: if false; // من Firebase Console فقط
    }
  }
}
```
