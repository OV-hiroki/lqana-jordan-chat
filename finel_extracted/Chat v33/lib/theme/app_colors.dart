import 'package:flutter/material.dart';

/// نظام الألوان الموحد - وردي (Pink) وأبيض (White)
/// Unified Color System - Pink & White Theme
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  // PRIMARY & ACCENT (وردي رئيسي / Pink Palette)
  // ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE91E63); // Hot pink - اللون الرئيسي
  static const Color primaryLight = Color(0xFFF06292); // Light pink
  static const Color primaryDark = Color(0xFFC2185B); // Dark pink
  static const Color primaryExtraDark = Color(0xFF880E4F); // Extra dark pink
  
  // Muted/Alpha versions
  static const Color primaryMuted = Color(0x26E91E63); // مخفّف (15% opacity)
  static const Color primaryLight20 = Color(0x33F06292); // 20% opacity

  // ─────────────────────────────────────────────────────────
  // BACKGROUNDS (الخلفيات / White & Light Gray)
  // ─────────────────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFFFFFFFF); // White - الخلفية الرئيسية
  static const Color bgSecondary = Color(0xFFFAFAFA); // Very light gray
  static const Color bgTertiary = Color(0xFFF5F5F5); // Light gray
  static const Color bgLight = Color(0xFFF9F9F9); // Almost white
  static const Color bgHeader = Color(0xFFE91E63); // Pink - للرأس
  
  // Overlay & Modal backgrounds
  static const Color bgOverlay = Color(0x66000000); // Semi-transparent black
  static const Color bgModal = Color(0xFFFEFEFE); // Modal background

  // ─────────────────────────────────────────────────────────
  // TEXT COLORS (ألوان النص)
  // ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121); // Dark text
  static const Color textSecondary = Color(0xFF616161); // Medium gray text
  static const Color textMuted = Color(0xFF9E9E9E); // Light gray text
  static const Color textWhite = Color(0xFFFFFFFF); // White text
  static const Color textAccent = Color(0xFFE91E63); // Pink accent text

  // ─────────────────────────────────────────────────────────
  // BORDERS & DIVIDERS
  // ─────────────────────────────────────────────────────────
  static const Color borderDefault = Color(0xFFE0E0E0); // Light border
  static const Color borderFocused = Color(0xFFE91E63); // Pink border (focused)
  static const Color borderMuted = Color(0xFFEBEBEB); // Very light border
  static const Color borderDark = Color(0xFFBDBDBD); // Medium gray border

  // ─────────────────────────────────────────────────────────
  // STATUS COLORS (الحالات / Semantic Colors)
  // ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50); // Green - نجاح
  static const Color successMuted = Color(0x264CAF50);
  
  static const Color warning = Color(0xFFFFA726); // Orange - تحذير
  static const Color warningMuted = Color(0x26FFA726);
  
  static const Color error = Color(0xFFF44336); // Red - خطأ
  static const Color errorMuted = Color(0x26F44336);
  
  static const Color info = Color(0xFF29B6F6); // Blue - معلومة
  static const Color infoMuted = Color(0x2629B6F6);

  // ─────────────────────────────────────────────────────────
  // AUDIO/ROOM COLORS (أصوات وحالات الغرفة)
  // ─────────────────────────────────────────────────────────
  static const Color speaking = Color(0xFF4CAF50); // Green - يتحدث
  static const Color speakingGlow = Color(0x4D4CAF50); // Glow effect
  
  static const Color mutedMic = Color(0xFFF44336); // Red - مايك معطل
  static const Color mutedMicLight = Color(0xFFE57373); // Light red
  
  static const Color raisedHand = Color(0xFFFFA726); // Orange - يد مرفوعة
  static const Color hostColor = Color(0xFFE91E63); // Pink - مضيف الغرفة
  static const Color moderator = Color(0xFF9C27B0); // Purple - مشرف

  // ─────────────────────────────────────────────────────────
  // ROLE COLORS (ألوان الأدوار / User Roles)
  // ─────────────────────────────────────────────────────────
  static const Color colorMaster = Color(0xFFCC0000); // Red - Master
  static const Color colorSuperAdmin = Color(0xFF00AA00); // Green - Super Admin
  static const Color colorAdmin = Color(0xFF0000CC); // Blue - Admin
  static const Color colorMember = Color(0xFF8B008B); // Purple - Member
  static const Color colorGuest = Color(0xFF666666); // Gray - Guest

  // ─────────────────────────────────────────────────────────
  // UTILITY COLORS
  // ─────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray900 = Color(0xFF212121);

  // ─────────────────────────────────────────────────────────
  // CHAT BUBBLE & MESSAGE COLORS
  // ─────────────────────────────────────────────────────────
  static const Color chatBgOther = Color(0xFFF5F5F5); // Light gray - chat bg
  static const Color chatBgMe = Color(0xFFE91E63); // Pink - my messages
  static const Color chatBubbleOther = Color(0xFFFFFFFF); // White - other bubble
  static const Color chatBubbleMe = Color(0xFFFFFFFF); // White text bubble
  static const Color chatTimestamp = Color(0xFFBDBDBD); // Gray timestamp
  static const Color chatToolbar = Color(0xFFE91E63); // Pink toolbar

  // ─────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────
  
  /// الحصول على لون الدور بناءً على قيمة الدور
  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'master':
        return colorMaster;
      case 'superadmin':
        return colorSuperAdmin;
      case 'admin':
        return colorAdmin;
      case 'member':
        return colorMember;
      default:
        return colorGuest;
    }
  }

  /// لون ناعم مع opacity - يُستخدم للخلفيات الفاتحة
  static Color withAlpha(Color color, int alpha) {
    return color.withValues(alpha: alpha / 255.0);
  }

  /// تدرج وردي بسيط
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
  );

  /// تدرج وردي فاتح
  static const LinearGradient pinkLightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF06292), Color(0xFFE91E63)],
  );
}
