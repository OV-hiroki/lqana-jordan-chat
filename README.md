# لقانا الأردن شات - Flutter 🇯🇴👑

تحويل كامل من React/Capacitor إلى Flutter Native

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                     ← نقطة البداية
├── firebase_options.dart         ← إعدادات Firebase
├── theme.dart                    ← الألوان والـ Theme
│
├── models/
│   ├── user_model.dart           ← نموذج المستخدم + UserRole
│   └── room_model.dart           ← نماذج الغرفة / الرسائل / الـ State
│
├── services/
│   └── firebase_service.dart     ← كل عمليات Firestore + Auth
│
├── screens/
│   ├── splash_screen.dart        ← شاشة التحميل
│   ├── lobby_screen.dart         ← اللوبي الرئيسي (الغرف + المتواجدون)
│   ├── login_modal.dart          ← نافذة الدخول (زائر / مسجل)
│   ├── chat_screen.dart          ← شاشة الغرفة الكاملة
│   ├── profile_screen.dart       ← الملف الشخصي
│   ├── private_chat_screen.dart  ← الرسائل الخاصة
│   └── settings_screen.dart      ← الإعدادات
│
└── widgets/
    ├── user_avatar.dart          ← الأفاتار مع الإطارات والشارات
    ├── user_name_text.dart       ← الأسماء المتحركة (gold, fire, bounce...)
    ├── message_bubble.dart       ← فقاعة الرسالة كاملة
    └── toast.dart                ← إشعارات Toast + Mixin
```

---

## 🚀 خطوات التشغيل

### 1. المتطلبات
```
Flutter SDK >= 3.0.0
Dart SDK >= 3.0.0
Android Studio / VS Code
```

### 2. تثبيت الـ Packages
```bash
flutter pub get
```

### 3. إعداد Firebase 🔥

#### أ. أنشئ مشروع Firebase جديد أو استخدم المشروع الموجود:
- Project ID: `lqana-jordan-chat`

#### ب. فعّل Authentication:
- Anonymous Sign-in ✅

#### ج. أنشئ Firestore Database وضع هذه القواعد:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /artifacts/{appId}/public/data/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### د. حمّل `google-services.json`:
- Firebase Console → Project Settings → Android
- Package name: `com.lqana.jordan.chat`
- ضع الملف في: `android/app/google-services.json`

#### هـ. حدّث `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.lqana.jordan.chat"
        minSdkVersion 21
        targetSdkVersion 34
        compileSdkVersion 34
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

#### و. حدّث `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.1'
    }
}
```

#### ز. حدّث `android/app/build.gradle` (أسفله):
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 4. إضافة خطوط Cairo
```bash
# حمّل خطوط Cairo من Google Fonts ثم ضعها في:
assets/fonts/Cairo-Regular.ttf
assets/fonts/Cairo-Bold.ttf
assets/fonts/Cairo-ExtraBold.ttf
```

أو استخدم `google_fonts` مباشرة (موجود في pubspec.yaml).

### 5. تشغيل التطبيق
```bash
flutter run
```

---

## ✨ المميزات المحوّلة

| الميزة | الحالة |
|---|---|
| اللوبي الرئيسي مع الأقسام والغرف | ✅ |
| الدخول كزائر أو مسجل | ✅ |
| شاشة الغرفة الكاملة مع الرسائل | ✅ |
| نظام الأدوار (guest → root) | ✅ |
| الأفاتار مع الإطارات والشارات | ✅ |
| الأسماء المتحركة (gold, fire, bounce...) | ✅ |
| فقاعات الرسائل مع الردود والتفاعلات | ✅ |
| قائمة الأعضاء في الغرفة | ✅ |
| نظام الميك (طلب/قبول/رفض) | ✅ |
| لوحة إدارة الغرفة (قفل الشات/الميك/الصور) | ✅ |
| طرد وكتم وحظر المستخدمين | ✅ |
| الرسائل الخاصة (DM) | ✅ |
| الملف الشخصي مع البيو والمعرض | ✅ |
| شريط الأخبار المتحرك (Ticker) | ✅ |
| الإعدادات (إشعارات / حجم خط / لغة) | ✅ |
| نظام الـ Toast للإشعارات | ✅ |
| RTL عربي كامل | ✅ |
| Firebase Firestore real-time | ✅ |

---

## 📦 Firestore Structure

```
artifacts/
  {appId}/
    public/
      data/
        sections/          ← أقسام الغرف
        room_members/      ← المتواجدون في الغرف
        messages_{roomId}/ ← رسائل كل غرفة
        room_state_{id}/   ← حالة الغرفة (قفل/ميك/...)
        room_accounts_{id}/← حسابات الإدارة لكل غرفة
        saved_members/     ← المستخدمون المسجلون
        private_chats/     ← المحادثات الخاصة
        sys_config/        ← إعدادات النظام
        audit_logs/        ← سجل الإدارة
        reports/           ← التقارير
```

---

## 🔧 تخصيص إضافي

### رفع الصور (Cloudinary)
في `chat_screen.dart` → دالة `_sendImage()`:
```dart
// استبدل TODO بـ:
final cloudinary = CloudinaryService();
final url = await cloudinary.upload(picked.path);
await _svc.sendMessage(widget.room.id, {
  ...data,
  'imageUrl': url,
});
```

### نظام الصوت (Agora RTC)
أضف `agora_rtc_engine` للـ pubspec.yaml وربطه في `chat_screen.dart`.

---

## 📞 التواصل
- GitHub: OV-hiroki
- Bugcrowd: kiro_404
