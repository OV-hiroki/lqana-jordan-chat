# رفع المشروع على FlutLab.io

## ما داخل الـ ZIP

- مشروع Flutter كامل (`lib/`, `android/`, `ios/`, `pubspec.yaml`, …).
- لا يوجد مجلد `assets/fonts` — الخط **Cairo** يُحمَّل من الإنترنت عبر حزمة `google_fonts` (أقل أخطاء «ملف ناقص»).
- تم توليد مجلدات **Android / iOS** كاملة (`flutter create .`) + `google-services.json` مبدئي يطابق `firebase_options.dart` واسم الحزمة `com.jordanaudioforumx.lqana_jordan_chat`.

## خطوات FlutLab

1. ارفع ملف **`lqana_jordan_chat_flutlab.zip`** (يُنشأ بجانب المشروع بعد تشغيل سكربت الضغط).
2. اختر **Flutter** ونسخة SDK قريبة من `>=3.0` (يفضّل 3.24+ إن توفرت).
3. **Build target:** Android APK أو App Bundle.

## لو ظهر خطأ Gradle

- تأكد أن المشروع **جذر الأرشيف** يحتوي مباشرة على `pubspec.yaml` (بعد فك الضغط: `.../lqana_jordan_chat/pubspec.yaml` وليس مجلد داخل مجلد).
- `local.properties`: FlutLab يولّده تلقائياً؛ لا ترفع نسخة من جهازك في الأرشيف النهائي إن كان يسبب تعارضاً (تم استبعاده من سكربت الـ ZIP إن وُجد).

## استبدال Firebase (مهم للإنتاج)

الملف `android/app/google-services.json` مُنشأ ليطابق الإعدادات الحالية. إذا غيّرت **package name** في Firebase Console، نزّل `google-services.json` الجديد من لوحة Firebase وضعه مكان الملف الحالي.

## package name الحالي

`com.jordanaudioforumx.lqana_jordan_chat`

---

## موقع ملف الـ ZIP

`D:\Chat vois app\fllater\Chat v33\home\kali\Desktop\app\src\lqana_jordan_chat_flutlab.zip`

**مهم:** محتويات الأرشيف في **الجذر مباشرة** (`pubspec.yaml`، `lib/`، `android/`، …) **بدون** مجلد وسيط اسمه `lqana_flutter`.  
بهذا الشكل FlutLab يجد `pubspec.yaml` بعد فك الضغط أو عند تعيين مجلد المشروع.

إذا رفعت نسخة قديمة كانت تضع كل الملفات داخل `lqana_flutter/` فقط، سيظهر خطأ «pubspec غير موجود» لأن الجذر المختار لا يحتوي الملف.

## بناء محلي على ويندوز

إذا ظهر `JAVA_HOME is not set`، ثبّت JDK 17 وحدّد متغير البيئة `JAVA_HOME` ثم أعد `flutter build apk --debug`.

على FlutLab عادة لا تحتاج ذلك لأن البيئة مُجهّزة على السيرفر.
