// lib/screens/settings_screen.dart
// مطابقة 100% للقطات المرجعية: عام (8 مفاتيح) + لغة + خط + لون رسالة
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _muteDm        = false;
  bool _muteAllSound  = false;
  bool _muteSpeaking  = true;
  bool _autoStatusPhone = true;
  bool _pullMicOnCall = true;
  bool _muteNameRemind = false;
  bool _muteDmNotif   = false;
  bool _joinLeaveNotif = false;
  String _lang = 'ar';
  double _fontScale = 1.0;
  bool _boldMsg  = false;
  bool _italicMsg = false;
  Color _msgColor = const Color(0xFF00E676);

  static const _kMuteDm        = 'settings_mute_dm';
  static const _kMuteAllSound  = 'settings_mute_all_sound';
  static const _kMuteSpeaking  = 'settings_mute_speaking';
  static const _kAutoStatusPhone= 'settings_auto_status_phone';
  static const _kPullMicOnCall  = 'settings_pull_mic_on_call';
  static const _kMuteNameRemind = 'settings_mute_name_remind';
  static const _kMuteDmNotif   = 'settings_mute_dm_notif';
  static const _kJoinLeave     = 'settings_join_leave';
  static const _kLang          = 'settings_lang';
  static const _kFontScale     = 'settings_font_scale';
  static const _kBold          = 'settings_msg_bold';
  static const _kItalic        = 'settings_msg_italic';
  static const _kMsgColor      = 'settings_msg_color';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _muteDm         = p.getBool(_kMuteDm) ?? false;
      _muteAllSound   = p.getBool(_kMuteAllSound) ?? false;
      _muteSpeaking   = p.getBool(_kMuteSpeaking) ?? true;
      _autoStatusPhone= p.getBool(_kAutoStatusPhone) ?? true;
      _pullMicOnCall  = p.getBool(_kPullMicOnCall) ?? true;
      _muteNameRemind = p.getBool(_kMuteNameRemind) ?? false;
      _muteDmNotif    = p.getBool(_kMuteDmNotif) ?? false;
      _joinLeaveNotif = p.getBool(_kJoinLeave) ?? false;
      _lang           = p.getString(_kLang) ?? 'ar';
      _fontScale      = p.getDouble(_kFontScale) ?? 1.0;
      _boldMsg        = p.getBool(_kBold) ?? false;
      _italicMsg      = p.getBool(_kItalic) ?? false;
      final c = p.getInt(_kMsgColor);
      if (c != null) _msgColor = Color(c);
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMuteDm, _muteDm);
    await p.setBool(_kMuteAllSound, _muteAllSound);
    await p.setBool(_kMuteSpeaking, _muteSpeaking);
    await p.setBool(_kAutoStatusPhone, _autoStatusPhone);
    await p.setBool(_kPullMicOnCall, _pullMicOnCall);
    await p.setBool(_kMuteNameRemind, _muteNameRemind);
    await p.setBool(_kMuteDmNotif, _muteDmNotif);
    await p.setBool(_kJoinLeave, _joinLeaveNotif);
    await p.setString(_kLang, _lang);
    await p.setDouble(_kFontScale, _fontScale);
    await p.setBool(_kBold, _boldMsg);
    await p.setBool(_kItalic, _italicMsg);
    await p.setInt(_kMsgColor, _msgColor.toARGB32());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الحفظ', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  static const _presetColors = <Color>[
    Color(0xFF00E676), Color(0xFF26C6DA), Color(0xFFE91E63),
    Color(0xFFFFA000), Color(0xFF7C4DFF), Color(0xFFFFFFFF),
    Color(0xFF212121), Color(0xFFE53935),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF00897B), Color(0xFF4DB6AC), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _sectionLabel('عام'),
                    _sw('تعطيل الرسائل الخاصة',    _muteDm,         (v) => setState(() => _muteDm = v)),
                    _sw('الغاء التنبيهات الصوتية',  _muteAllSound,   (v) => setState(() => _muteAllSound = v)),
                    _sw('الغاء التنبيهات الصوتية اثناء التحدث', _muteSpeaking, (v) => setState(() => _muteSpeaking = v)),
                    _sw('تحويل الحالة ل هاتف اثناء المكالمات الهاتفية', _autoStatusPhone, (v) => setState(() => _autoStatusPhone = v)),
                    _sw('عند وجود مكالمة هاتفية اسحب مني المايك', _pullMicOnCall, (v) => setState(() => _pullMicOnCall = v)),
                    _sw('الغاء تنبيهات تذكير الاسم',_muteNameRemind,(v) => setState(() => _muteNameRemind = v)),
                    _sw('الغاء تنبيهات الرسائل الخاصة', _muteDmNotif, (v) => setState(() => _muteDmNotif = v)),
                    _sw('تنبيهات الدخول و الخروج',  _joinLeaveNotif, (v) => setState(() => _joinLeaveNotif = v)),
                    const SizedBox(height: 16),
                    _sectionLabel('اللغة'),
                    _radio('العربية', 'ar'),
                    _radio('English', 'en'),
                    _radio('Français', 'fr'),
                    const SizedBox(height: 16),
                    _sectionLabel('الخط'),
                    _buildFontSection(),
                    const SizedBox(height: 16),
                    _buildColorSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 26),
      ),
      const Text('الاعدادات',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 20,
          fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(width: 26),
    ]),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Align(alignment: Alignment.centerRight,
      child: Text(label, style: const TextStyle(fontFamily: 'Cairo',
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70))),
  );

  Widget _sw(String label, bool value, ValueChanged<bool> cb) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Switch(
        value: value, onChanged: cb,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF26C6DA),
        inactiveThumbColor: Colors.grey.shade300,
        inactiveTrackColor: Colors.white30,
      ),
      Expanded(child: Text(label, textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white))),
    ]),
  );

  Widget _radio(String label, String value) => GestureDetector(
    onTap: () => setState(() => _lang = value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Radio<String>(
          value: value, groupValue: _lang,
          onChanged: (v) => setState(() => _lang = v!),
          activeColor: const Color(0xFF26C6DA),
          fillColor: WidgetStateProperty.all(
            _lang == value ? const Color(0xFF26C6DA) : Colors.white54),
        ),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
          fontWeight: _lang == value ? FontWeight.w700 : FontWeight.normal,
          color: Colors.white)),
      ]),
    ),
  );

  Widget _buildFontSection() => Column(children: [
    Row(children: [
      const Text('صغير', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
      Expanded(child: Slider(
        value: _fontScale, min: 0.7, max: 1.5, divisions: 8,
        activeColor: const Color(0xFF26C6DA),
        inactiveColor: Colors.white30, thumbColor: Colors.white,
        onChanged: (v) => setState(() => _fontScale = v),
      )),
      const Text('كبير', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
    ]),
    _sw('عريض', _boldMsg,   (v) => setState(() => _boldMsg = v)),
    _sw('مائل', _italicMsg, (v) => setState(() => _italicMsg = v)),
  ]);

  Widget _buildColorSection() => Column(children: [
    Row(children: [
      GestureDetector(
        onTap: _showColorDialog,
        child: Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
            gradient: SweepGradient(colors: [
              Colors.red, Colors.orange, Colors.yellow, Colors.green,
              Colors.blue, Colors.indigo, Colors.purple, Colors.red,
            ]),
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text('Test Message', style: TextStyle(
        fontFamily: 'Cairo', fontSize: 14 * _fontScale,
        fontWeight: _boldMsg ? FontWeight.bold : FontWeight.normal,
        fontStyle: _italicMsg ? FontStyle.italic : FontStyle.normal,
        color: _msgColor,
      )),
      const Spacer(),
      Container(width: 48, height: 48,
        decoration: BoxDecoration(color: _msgColor, borderRadius: BorderRadius.circular(8))),
    ]),
    const SizedBox(height: 10),
    Wrap(
      alignment: WrapAlignment.end, spacing: 8, runSpacing: 8,
      children: _presetColors.map((c) {
        final sel = _msgColor.toARGB32() == c.toARGB32();
        return GestureDetector(
          onTap: () => setState(() => _msgColor = c),
          child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle,
              border: Border.all(
                color: sel ? Colors.white : Colors.white30, width: sel ? 3 : 1))),
        );
      }).toList(),
    ),
  ]);

  void _showColorDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('اختر لوناً', style: TextStyle(fontFamily: 'Cairo')),
      content: Wrap(spacing: 8, runSpacing: 8,
        children: [..._presetColors,
          Colors.pink, Colors.cyan, Colors.lime, Colors.amber,
          Colors.deepPurple, Colors.teal, Colors.brown, Colors.grey,
        ].map((c) => GestureDetector(
          onTap: () { setState(() => _msgColor = c); Navigator.pop(context); },
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        )).toList()),
    ));
  }

  Widget _buildActionButtons() => Row(children: [
    Expanded(child: ElevatedButton(
      onPressed: _load,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE57373), foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('الغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
    )),
    const SizedBox(width: 12),
    Expanded(child: ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DB6AC), foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
    )),
  ]);
}
