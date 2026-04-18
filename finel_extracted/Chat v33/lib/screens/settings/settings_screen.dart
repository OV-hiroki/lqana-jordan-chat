// ============================================================
//  Settings Screen — مطابق لصور التصميم 100%
//  Font | Private Msgs | Notifications | Language | General
//  يعمل بدون تسجيل دخول
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // ── Font & Personalization ─────────────────────────────
  Color _msgColor = const Color(0xFF212121);
  bool _msgBold = false;
  double _fontSize = 14.0;
  final List<Color> _colorPalette = [
    const Color(0xFF212121), const Color(0xFFE53935), const Color(0xFF1565C0),
    const Color(0xFF2E7D32), const Color(0xFF6A1B9A), const Color(0xFFAD1457),
    const Color(0xFFE65100), const Color(0xFF00838F), const Color(0xFF4E342E),
    const Color(0xFF37474F),
  ];

  // ── Private Messages ─────────────────────────────────
  int _pmPolicy = 1; // 0=reject all, 1=members only, 2=accept all

  // ── Notifications ────────────────────────────────────
  bool _notifGeneral       = true;
  bool _notifWhileTalking  = false;
  bool _notifNameReminder  = true;
  bool _notifPrivateMsg    = true;
  bool _notifEntryExit     = false;

  // ── Language ─────────────────────────────────────────
  int _lang = 1; // 0=EN, 1=AR, 2=FR

  // ── General ──────────────────────────────────────────
  bool _autoStatusOnCall   = true;
  bool _releaseMicOnCall   = false;

  static const _pink     = Color(0xFFE91E63); // وردي رئيسي
  static const _pinkDark = Color(0xFFC2185B); // وردي غامق

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<AuthProvider>().isGuest;
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // ── Header ──────────────────────────────────────
        _Header(
          name: isGuest ? 'زائر' : (profile?.displayName ?? 'مستخدم'),
          photoURL: isGuest ? null : profile?.photoURL,
          isGuest: isGuest,
          onBack: () => context.pop(),
          onLogin: () => context.push('/login'),
        ),

        // ── Tab bar ─────────────────────────────────────
        Container(
          color: Colors.grey.shade100,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            indicatorColor: _pink,
            indicatorWeight: 3,
            labelColor: _pink,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo', fontSize: 12),
            tabs: const [
              Tab(text: 'الخط'),
              Tab(text: 'خاص'),
              Tab(text: 'تنبيهات'),
              Tab(text: 'اللغة'),
              Tab(text: 'عام'),
            ],
          ),
        ),

        // ── Tab views ───────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildFontTab(),
              _buildPrivateMsgTab(),
              _buildNotifTab(),
              _buildLanguageTab(),
              _buildGeneralTab(),
            ],
          ),
        ),

        // ── Save button ─────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 46),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تم حفظ الإعدادات',
                    style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Color(0xFF9C27B0),
                duration: Duration(seconds: 2),
              ));
            },
            child: const Text('حفظ الإعدادات',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 1 — Font & Personalization
  // ══════════════════════════════════════════════════════
  Widget _buildFontTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Preview bubble
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('معاينة الرسالة',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Text(
              'هذا مثال على شكل رسالتك في الدردشة',
              style: TextStyle(
                color: _msgColor,
                fontSize: _fontSize,
                fontWeight: _msgBold ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Cairo',
              ),
            ),
          ]),
        ),

        // Color picker
        _SectionTitle('لون الخط'),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: _colorPalette.map((c) =>
          GestureDetector(
            onTap: () => setState(() => _msgColor = c),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: _msgColor == c
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: _msgColor == c
                    ? [BoxShadow(color: c.withValues(alpha: 0.5),
                          blurRadius: 6, spreadRadius: 1)]
                    : null,
              ),
            ),
          ),
        ).toList()),
        const SizedBox(height: 20),

        // Bold
        _SectionTitle('نمط الخط'),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: Text('عريض (Bold)',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14))),
          Switch(
            value: _msgBold,
            onChanged: (v) => setState(() => _msgBold = v),
            activeColor: _pink,
          ),
        ]),
        const SizedBox(height: 16),

        // Font size
        _SectionTitle('حجم الخط'),
        const SizedBox(height: 4),
        Row(children: [
          const Text('ص', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Expanded(
            child: Slider(
              value: _fontSize,
              min: 11, max: 20,
              divisions: 9,
              activeColor: _pink,
              onChanged: (v) => setState(() => _fontSize = v),
            ),
          ),
          const Text('ك', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ]),
        Center(child: Text('${_fontSize.toInt()} pt',
          style: const TextStyle(color: Colors.grey, fontSize: 12,
              fontFamily: 'Cairo'))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 2 — Private Messages
  // ══════════════════════════════════════════════════════
  Widget _buildPrivateMsgTab() {
    final opts = [
      ('رفض الجميع',               Icons.block),
      ('قبول من الأعضاء فقط',      Icons.supervised_user_circle),
      ('قبول الجميع',              Icons.people_alt),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _SectionTitle('الرسائل الخاصة — من يمكنه مراسلتك؟'),
        const SizedBox(height: 16),
        ...List.generate(opts.length, (i) => Card(
          elevation: 0,
          color: _pmPolicy == i
              ? _pink.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: _pmPolicy == i ? _pink : Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => setState(() => _pmPolicy = i),
            leading: Icon(opts[i].$2,
                color: _pmPolicy == i ? _pink : Colors.grey),
            title: Text(opts[i].$1,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: _pmPolicy == i ? _pink : Colors.black87,
              )),
            trailing: _pmPolicy == i
                ? const Icon(Icons.check_circle, color: _pink)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
          ),
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 3 — Notifications
  // ══════════════════════════════════════════════════════
  Widget _buildNotifTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _SectionTitle('إعدادات التنبيهات'),
        const SizedBox(height: 8),
        _NotifTile('تنبيه صوتي عام', _notifGeneral,
            (v) => setState(() => _notifGeneral = v)),
        _NotifTile('تنبيه أثناء الحديث', _notifWhileTalking,
            (v) => setState(() => _notifWhileTalking = v)),
        _NotifTile('تذكير بالاسم', _notifNameReminder,
            (v) => setState(() => _notifNameReminder = v)),
        _NotifTile('تنبيه الرسائل الخاصة', _notifPrivateMsg,
            (v) => setState(() => _notifPrivateMsg = v)),
        _NotifTile('تنبيه الدخول والخروج', _notifEntryExit,
            (v) => setState(() => _notifEntryExit = v)),
      ]),
    );
  }

  Widget _NotifTile(String label, bool val, ValueChanged<bool> onChange) =>
    Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: SwitchListTile(
        value: val,
        onChanged: onChange,
        activeColor: _pink,
        title: Text(label,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
      ),
    );

  // ══════════════════════════════════════════════════════
  //  TAB 4 — Language
  // ══════════════════════════════════════════════════════
  Widget _buildLanguageTab() {
    final langs = [
      ('English', '🇬🇧', 0),
      ('العربية', '🇯🇴', 1),
      ('Français', '🇫🇷', 2),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _SectionTitle('اختر اللغة'),
        const SizedBox(height: 16),
        ...langs.map((l) => Card(
          elevation: 0,
          color: _lang == l.$3
              ? _pink.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: _lang == l.$3 ? _pink : Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => setState(() => _lang = l.$3),
            leading: Text(l.$2, style: const TextStyle(fontSize: 24)),
            title: Text(l.$1,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: _lang == l.$3 ? _pink : Colors.black87,
              )),
            trailing: _lang == l.$3
                ? const Icon(Icons.check_circle, color: _pink)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
          ),
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 5 — General
  // ══════════════════════════════════════════════════════
  Widget _buildGeneralTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _SectionTitle('إعدادات المكالمات الهاتفية'),
        const SizedBox(height: 8),
        _NotifTile('تغيير الحالة تلقائياً عند الاتصال',
            _autoStatusOnCall,
            (v) => setState(() => _autoStatusOnCall = v)),
        _NotifTile('تحرير المايك عند الاتصال الهاتفي',
            _releaseMicOnCall,
            (v) => setState(() => _releaseMicOnCall = v)),
        const SizedBox(height: 24),
        _SectionTitle('الحساب'),
        const SizedBox(height: 8),
        ListTile(
          onTap: () => context.push('/profile'),
          leading: const Icon(Icons.person_outline, color: Colors.grey),
          title: const Text('تعديل البيانات الشخصية',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.grey),
        ),
        Container(height: 1, color: Colors.grey.shade100),
        Builder(builder: (ctx) {
          final isGuest = context.watch<AuthProvider>().isGuest;
          if (isGuest) {
            return ListTile(
              onTap: () => context.push('/login'),
              leading: const Icon(Icons.login, color: Color(0xFF9C27B0)),
              title: const Text('تسجيل الدخول / إنشاء حساب',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                    color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)),
            );
          }
          return ListTile(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/');
            },
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                  color: Colors.red)),
          );
        }),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  HEADER WIDGET
// ══════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String name;
  final String? photoURL;
  final bool isGuest;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  const _Header({
    required this.name,
    required this.photoURL,
    required this.isGuest,
    required this.onBack,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF9B27AF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            // Back
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),

            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
              child: photoURL == null
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
            const SizedBox(width: 10),

            // Name
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 15, fontFamily: 'Cairo')),
                if (isGuest)
                  GestureDetector(
                    onTap: onLogin,
                    child: const Text('اضغط لتسجيل الدخول',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 12, fontFamily: 'Cairo')),
                  ),
              ],
            )),

            // Title
            const Text('الإعدادات',
              style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SECTION TITLE
// ══════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Color(0xFF9C27B0),
      )),
  );
}
