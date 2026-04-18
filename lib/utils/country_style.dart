// lib/utils/country_style.dart
// تنسيق بطاقات الدول كما في مرجع src/img

String flagEmojiForSectionName(String name) {
  final n = name.replaceAll(' ', '').toLowerCase();
  if (n.contains('أردن') || n.contains('اردن') || n.contains('jordan')) return '🇯🇴';
  if (n.contains('مصر') || n.contains('egypt')) return '🇪🇬';
  if (n.contains('سعود') || n.contains('saudi')) return '🇸🇦';
  if (n.contains('كويت') || n.contains('kuwait')) return '🇰🇼';
  if (n.contains('بحرين') || n.contains('bahrain')) return '🇧🇭';
  if (n.contains('عمان') || n.contains('oman')) return '🇴🇲';
  if (n.contains('قطر') || n.contains('qatar')) return '🇶🇦';
  if (n.contains('فلسطين') || n.contains('palestine')) return '🇵🇸';
  if (n.contains('مغرب') || n.contains('morocco')) return '🇲🇦';
  if (n.contains('تونس') || n.contains('tunisia')) return '🇹🇳';
  if (n.contains('جزائر') || n.contains('algeria')) return '🇩🇿';
  if (n.contains('لبنان') || n.contains('lebanon')) return '🇱🇧';
  if (n.contains('سوريا') || n.contains('syria')) return '🇸🇾';
  if (n.contains('عراق') || n.contains('iraq')) return '🇮🇶';
  if (n.contains('اليمن') || n.contains('yemen')) return '🇾🇪';
  if (n.contains('ليبيا') || n.contains('libya')) return '🇱🇾';
  if (n.contains('سودان') || n.contains('sudan')) return '🇸🇩';
  if (n.contains('الامارات') || n.contains('إمارات') || n.contains('uae')) return '🇦🇪';
  return '🌍';
}
