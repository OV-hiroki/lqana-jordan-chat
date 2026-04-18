// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // الألوان الأساسية من الصور
  static const Color teal        = Color(0xFF26C6DA);  // اللون الرئيسي
  static const Color tealLight   = Color(0xFF4DD0E1);
  static const Color tealDark    = Color(0xFF00ACC1);
  static const Color navyDark    = Color(0xFF0D1B2A);  // خلفية شاشة الاتصال
  static const Color navyMid     = Color(0xFF1A2B3C);

  // ألوان الأزرار
  static const Color btnSend     = Color(0xFF26C6DA);  // زر الإرسال
  static const Color btnMic      = Color(0xFFE53935);  // زر الميك (أحمر)
  static const Color btnMicOn    = Color(0xFF43A047);  // ميك شغال (أخضر)
  static const Color btnPlus     = Color(0xFF43A047);  // زر +
  static const Color btnMenu     = Color(0xFF1565C0);  // الهامبرجر (أزرق)
  static const Color btnChat     = Color(0xFFFFA000);  // أيقونة الشات (أصفر/عنبري)

  // ألوان الحالة
  static const Color online      = Color(0xFF43A047);
  static const Color offline     = Color(0xFF9E9E9E);
  static const Color busy        = Color(0xFFE53935);
  static const Color away        = Color(0xFFFFA000);

  // إحصائيات البروفايل
  static const Color stat1       = Color(0xFFB07D1E);  // الزوار
  static const Color stat2       = Color(0xFF43A047);  // التواجد
  static const Color stat3       = Color(0xFF1E6EA6);  // مدة التحدث
  static const Color stat4       = Color(0xFF8B2222);  // الحظر

  // الألعاب
  static const Color gameUno     = Color(0xFFD32F2F);  // أحمر
  static const Color gameLudo    = Color(0xFF2E7D32);  // أخضر
  static const Color gameRPS     = Color(0xFFF57C00);  // برتقالي

  // خلفية اللوبي (هيكل الصفحة)
  static const Color lobbyBg     = Color(0xFFFFFFFF);

  /// خلفية قائمة الدول/الغرف كما في src/img (فيروزي صلب)
  static const Color lobbyListTeal = Color(0xFF26C6DA);

  /// بطاقة الدولة المحددة (ذهبي/أصفر)
  static const Color countrySelected = Color(0xFFFFD54F);

  // top bar الغرفة
  static const Color chatTopBar  = Color(0xFFE8E8E8);
}

/// تدرج إعدادات (مرجع img)
class AppSettingsGradients {
  static const LinearGradient settingsBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00897B), Color(0xFF4DB6AC), Color(0xFFB2DFDB)],
  );
}

class AppTheme {
  static ThemeData get theme {
    final cairo = GoogleFonts.cairoTextTheme();
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
      scaffoldBackgroundColor: AppColors.lobbyBg,
      textTheme: cairo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        brightness: Brightness.light,
      ),
    );
  }
}
