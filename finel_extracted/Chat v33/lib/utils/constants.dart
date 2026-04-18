class AppConstants {
  AppConstants._();

  // ✔ Admin access is controlled ONLY via Firestore user document (isAdminUser field)
  // Do NOT put any UIDs here — security risk
  static const List<String> adminUids = []; // Intentionally empty

  // Support Admin — managed via Firestore, not hardcoded
  static const String supportAdminUid = '';
  static bool isSupportAdmin(String uid) => false;

  // ─── Agora RTC ────────────────────────────────────────────
  // ⚠️ ضع هنا الـ App ID من Agora Console (https://console.agora.io)
  static const String agoraAppId = '98ff0070534d4fd2a6790c31d1d2b140';
  // Token ثابت من Agora Console (إذا كان لديك token ثابت)
  static const String agoraToken = '';
  // للإنتاج: اعمل Token Server وحط الـ URL هنا، وإلا خليه null
  static const String? agoraTokenServerUrl = null;

  // Cloudinary
  static const String cloudinaryCloudName = 'dx262huam';
  static const String cloudinaryUploadPreset = 'jordan-audio-forum';
  static const String cloudinaryBaseUrl = 'https://api.cloudinary.com/v1_1';
  static const String folderProfileImages = 'jordan_audio/profile_images';
  static const String folderRoomImages = 'jordan_audio/room_images';
  static const String transformAvatar =
      'c_fill,g_face,h_200,w_200,q_auto,f_auto';
  static const String transformRoomCover = 'c_fill,h_400,w_800,q_auto,f_auto';

  // Firestore Collections
  static const String colUsers = 'users';
  static const String colRooms = 'rooms';
  static const String colAppStatus = 'app_status';

  // Kill-Switch
  static const String killSwitchCollection = 'app_status';
  static const String killSwitchDocument = 'global_config';
  static const String killSwitchField = 'isLocked';
  static const String killSwitchMsgField = 'lockMessage';
  static const String killSwitchDefaultMsg =
      'التطبيق محجوب مؤقتاً للصيانة. سنعود قريباً.';

  // Room Roles (Lgana style)
  static const String roleMaster = 'master'; // ماستر - أحمر
  static const String roleSuperAdmin = 'superadmin'; // سوبر أدمن - أخضر
  static const String roleAdmin = 'admin'; // أدمن - أزرق
  static const String roleMember = 'member'; // ممبر - بنفسجي
  static const String roleGuest = 'guest'; // زائر - رمادي

  // Legacy aliases (used in older code)
  static const String roleHost = 'master';
  static const String roleModerator = 'superadmin';
  static const String roleSpeaker = 'admin';
  static const String roleListener = 'guest';

  // Role display names
  static String roleLabel(String role) {
    switch (role) {
      case roleMaster:
        return 'ماستر';
      case roleSuperAdmin:
        return 'سوبر أدمن';
      case roleAdmin:
        return 'أدمن';
      case roleMember:
        return 'ممبر';
      default:
        return 'زائر';
    }
  }

  // Permissions list (shown in add account dialog)
  static const List<Map<String, String>> permissionsList = [
    {'key': 'ban_device', 'label': 'حظر جهاز'},
    {'key': 'kick', 'label': 'ايقاف'},
    {'key': 'expel', 'label': 'طرد'},
    {'key': 'mic_turn', 'label': 'دور المايك'},
    {'key': 'clear_all_text', 'label': 'مسح النص للجميع'},
    {'key': 'broadcast', 'label': 'رسالة عامة'},
    {'key': 'unban', 'label': 'الغاء الحظر'},
    {'key': 'view_log', 'label': 'سجل الخروج'},
    {'key': 'manage_accounts', 'label': 'ادارة الحسابات'},
    {'key': 'manage_member', 'label': 'ادارة ممبر'},
    {'key': 'manage_admin', 'label': 'ادارة ادمن'},
    {'key': 'manage_superadmin', 'label': 'ادارة سوبر ادمن'},
    {'key': 'manage_master', 'label': 'ادارة ماستر'},
    {'key': 'room_settings', 'label': 'اعدادات الغرفة'},
    {'key': 'admin_reports', 'label': 'تقارير المشرفين'},
  ];

  // App Info
  static const String appName = 'Jordan Audio Forum';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@jordanaudioforum.com';

  // Countries (for room categorization — matches design images)
  static const List<Map<String, String>> countries = [
    {'id': 'featured', 'label': 'الغرف المميزة',          'flag': '⭐'},
    {'id': 'jordan',   'label': 'الأردن',                  'flag': '🇯🇴'},
    {'id': 'iraq',     'label': 'العراق',                  'flag': '🇮🇶'},
    {'id': 'egypt',    'label': 'مصر',                    'flag': '🇪🇬'},
    {'id': 'saudi',    'label': 'السعودية',               'flag': '🇸🇦'},
    {'id': 'syria',    'label': 'سوريا',                  'flag': '🇸🇾'},
    {'id': 'yemen',    'label': 'اليمن',                  'flag': '🇾🇪'},
    {'id': 'oman',     'label': 'سلطنة عمان',             'flag': '🇴🇲'},
    {'id': 'morocco',  'label': 'المغرب',                 'flag': '🇲🇦'},
    {'id': 'religion', 'label': 'الغرف الدينية والتعليمية','flag': '📚'},
    {'id': 'kuwait',   'label': 'الكويت',                 'flag': '🇰🇼'},
    {'id': 'uae',      'label': 'الإمارات',               'flag': '🇦🇪'},
    {'id': 'libya',    'label': 'ليبيا',                  'flag': '🇱🇾'},
    {'id': 'algeria',  'label': 'الجزائر',               'flag': '🇩🇿'},
    {'id': 'tunisia',  'label': 'تونس',                  'flag': '🇹🇳'},
    {'id': 'palestine','label': 'فلسطين',                 'flag': '🇵🇸'},
    {'id': 'bahrain',  'label': 'البحرين',               'flag': '🇧🇭'},
    {'id': 'qatar',    'label': 'قطر',                   'flag': '🇶🇦'},
    {'id': 'lebanon',  'label': 'لبنان',                 'flag': '🇱🇧'},
    {'id': 'sudan',    'label': 'السودان',               'flag': '🇸🇩'},
    {'id': 'other',    'label': 'أخرى',                  'flag': '🌍'},
  ];

  // Legacy room categories (kept for backward compat)
  static const List<Map<String, String>> roomCategories = [
    {'id': 'featured', 'label': 'الغرف المميزة',          'icon': '⭐'},
    {'id': 'jordan',   'label': 'الأردن',                  'icon': '🇯🇴'},
    {'id': 'iraq',     'label': 'العراق',                  'icon': '🇮🇶'},
    {'id': 'egypt',    'label': 'مصر',                    'icon': '🇪🇬'},
    {'id': 'saudi',    'label': 'السعودية',               'icon': '🇸🇦'},
    {'id': 'syria',    'label': 'سوريا',                  'icon': '🇸🇾'},
    {'id': 'yemen',    'label': 'اليمن',                  'icon': '🇾🇪'},
    {'id': 'oman',     'label': 'سلطنة عمان',             'icon': '🇴🇲'},
    {'id': 'morocco',  'label': 'المغرب',                 'icon': '🇲🇦'},
    {'id': 'religion', 'label': 'الغرف الدينية والتعليمية','icon': '📚'},
    {'id': 'kuwait',   'label': 'الكويت',                 'icon': '🇰🇼'},
    {'id': 'uae',      'label': 'الإمارات',               'icon': '🇦🇪'},
    {'id': 'other',    'label': 'أخرى',                  'icon': '🌍'},
  ];
}
