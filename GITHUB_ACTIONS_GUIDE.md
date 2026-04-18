# دليل بناء APK باستخدام GitHub Actions

## الخطوات:

1. **إنشاء مستودع جديد على GitHub**
   - اذهب إلى https://github.com/new
   - أنشئ مستودع جديد (مثلاً: lqana-jordan-chat)

2. **رفع المشروع على GitHub**
   ```powershell
   cd "d:\Chat vois app\fllater\src\lqana_flutter"
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/USERNAME/lqana-jordan-chat.git
   git push -u origin main
   ```
   (استبدل USERNAME باسم المستخدم الخاص بك على GitHub)

3. **تفعيل GitHub Actions**
   - بعد الرفع، اذهب إلى المستودع على GitHub
   - اضغط على "Actions" في القائمة الجانبية
   - ستجد workflow "Build APK" يعمل تلقائياً

4. **تحميل APK**
   - بعد اكتمال البناء (يستغرق 5-10 دقائق)
   - اضغط على workflow المنتهي
   - في قسم "Artifacts"، اضغط على "app-release"
   - سيتم تحميل ملف APK

## ملاحظات:
- سيتم بناء APK تلقائياً عند كل push إلى الفرع main
- يمكنك أيضاً تشغيل البناء يدوياً من صفحة Actions
- APK سيكون جاهز للتثبيت على أي جهاز Android
