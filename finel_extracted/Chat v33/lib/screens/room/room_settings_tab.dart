// ============================================================
// Room Settings Tab — Lgana Dark Purple Theme
// ============================================================

import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

// ── Lgana dark-purple palette ──────────────────────────────
const _kBg      = Color(0xFF1A1630);
const _kSection = Color(0xFF251F40);
const _kHeader  = Color(0xFF7B1FA2);
const _kBorder  = Color(0xFF3D3358);
const _kInput   = Color(0xFF1E1A35);
const _kAccent  = AppColors.primaryLight; // light purple label
// ──────────────────────────────────────────────────────────

class RoomSettingsTab extends StatefulWidget {
  final RoomModel room;
  final bool canEdit;
  const RoomSettingsTab({super.key, required this.room, this.canEdit = false});

  @override
  State<RoomSettingsTab> createState() => _RoomSettingsTabState();
}

class _RoomSettingsTabState extends State<RoomSettingsTab> {
  late TextEditingController _welcomeCtrl;
  late String _whoCanSpeak;
  late Map<String, int> _speakDuration;
  late bool _cameraEnabled;
  late String _lockStatus;
  late TextEditingController _lockReasonCtrl;
  late bool _hasGateway;
  late bool _allowImages;
  late bool _allowMasterAddMaster;
  late bool _allowMasterChangeSettings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.room.settings;
    _welcomeCtrl               = TextEditingController(text: s.welcomeMessage);
    _whoCanSpeak               = s.whoCanSpeak;
    _speakDuration             = Map.from(s.speakDuration);
    _cameraEnabled             = s.cameraEnabled;
    _lockStatus                = s.lockStatus;
    _lockReasonCtrl            = TextEditingController(text: s.lockReason);
    _hasGateway                = s.hasGateway;
    _allowImages               = s.allowImages;
    _allowMasterAddMaster      = s.allowMasterAddMaster;
    _allowMasterChangeSettings = s.allowMasterChangeSettings;
  }

  @override
  void dispose() {
    _welcomeCtrl.dispose();
    _lockReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!widget.canEdit) return;
    setState(() => _saving = true);
    final settings = RoomSettings(
      welcomeMessage:            _welcomeCtrl.text,
      whoCanSpeak:               _whoCanSpeak,
      speakDuration:             _speakDuration,
      cameraEnabled:             _cameraEnabled,
      lockStatus:                _lockStatus,
      lockReason:                _lockReasonCtrl.text,
      hasGateway:                _hasGateway,
      allowImages:               _allowImages,
      allowMasterAddMaster:      _allowMasterAddMaster,
      allowMasterChangeSettings: _allowMasterChangeSettings,
    );
    await FirestoreService.instance.updateRoomSettings(widget.room.id, settings);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات ✓',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
          backgroundColor: Color(0xFF7B1FA2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        color: _kBg,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // ── رسالة الترحيب ──────────────────────────
            _section('رسالة الترحيب'),
            Container(
              color: _kSection,
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _welcomeCtrl,
                enabled: widget.canEdit,
                maxLines: 4,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white),
                decoration: _inputDecoration(hint: 'رسالة ترحيب لأعضاء الغرفة...'),
              ),
            ),

            // ── من يتحدث ────────────────────────────────
            _section('التحدث'),
            _label('من يستطيع التحدث'),
            _radio('الجميع', 'all'),
            _radio('الاعضاء والمشرفين فقط', 'members_admins'),
            _radio('المشرفين فقط', 'admins'),
            _radio('لا احد', 'none'),

            // ── معاينة التصميم ──────────────────────────
            _section('نمط التصميم'),
            _label('معاينة الغرفة'),
            _buildRoomPreview(),

            // ── مدة التحدث ──────────────────────────────
            _section('مدة التحدث (ثانية)'),
            _durationRow('الزوار',     'guest',      Colors.white70),
            _durationRow('مُمبر',      'member',     AppColors.colorMember),
            _durationRow('أدمن',       'admin',      AppColors.colorAdmin),
            _durationRow('سوبر أدمن',  'superadmin', AppColors.colorSuperAdmin),
            _durationRow('ماستر',      'master',     AppColors.colorMaster),

            // ── خيارات متقدمة ───────────────────────────
            _section('خيارات متقدمة'),
            _label('قفل الغرفة'),
            _lockRadio('مفتوح',                     'open'),
            _lockRadio('للأعضاء والمشرفين فقط',     'members'),
            _lockRadio('بوابة دخول',                'gateway'),
            if (_lockStatus == 'members')
              Container(
                color: _kSection,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _lockReasonCtrl,
                  enabled: widget.canEdit,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white),
                  decoration: _inputDecoration(hint: 'سبب الاغلاق...'),
                ),
              ),

            // ── الصور ───────────────────────────────────
            _section('الصور والوسائط'),
            _switchRow('السماح بإرسال الصور في الدردشة', _allowImages,
                (v) => setState(() => _allowImages = v)),

            // ── صلاحيات الماستر ─────────────────────────
            _section('صلاحيات الماستر'),
            _switchRow('السماح بإضافة أسماء ماستر', _allowMasterAddMaster,
                (v) => setState(() => _allowMasterAddMaster = v)),
            _switchRow('السماح لأسماء الماستر بتغيير الإعدادات',
                _allowMasterChangeSettings,
                (v) => setState(() => _allowMasterChangeSettings = v)),

            // ── الكاميرا ────────────────────────────────
            _section('الكاميرا'),
            _switchRow('تفعيل الكاميرا في الغرفة', _cameraEnabled,
                (v) => setState(() => _cameraEnabled = v)),
          ],
        ),
      ),

      // ── زر الحفظ ──────────────────────────────────────
      if (widget.canEdit)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: _kSection,
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kHeader,
                disabledBackgroundColor: _kBorder,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ الإعدادات',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
    ]);
  }

  // ── Helpers ─────────────────────────────────────────────

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.white30, fontSize: 12),
        filled: true,
        fillColor: _kInput,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.all(10),
      );

  Widget _section(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        color: _kSection,
        child: Text(title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                fontFamily: 'Cairo', color: _kAccent, letterSpacing: 0.4)),
      );

  Widget _label(String text) => Container(
        width: double.infinity,
        color: _kBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(text,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontFamily: 'Cairo',
                color: Colors.white70, fontWeight: FontWeight.w600)),
      );

  Widget _radio(String label, String value) => _radioGeneric(
        label, value, _whoCanSpeak, (v) => setState(() => _whoCanSpeak = v));

  Widget _lockRadio(String label, String value) => _radioGeneric(
        label, value, _lockStatus, (v) => setState(() => _lockStatus = v));

  Widget _radioGeneric(String label, String value, String groupValue,
      ValueChanged<String> onChange) =>
      Container(
        color: _kBg,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RadioListTile<String>(
            value: value,
            groupValue: groupValue,
            onChanged: widget.canEdit ? (v) => onChange(v!) : null,
            title: Text(label,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white)),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            dense: true,
          ),
        ),
      );

  Widget _durationRow(String label, String key, Color color) {
    final ctrl = TextEditingController(text: '${_speakDuration[key] ?? 350}');
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              enabled: widget.canEdit,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (v) => _speakDuration[key] = int.tryParse(v) ?? 350,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                filled: true, fillColor: _kInput,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _kBorder)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const Spacer(),
          Text(': $label',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                  fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Container(
        color: _kBg,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: CheckboxListTile(
            value: value,
            onChanged: widget.canEdit ? (v) => onChanged(v!) : null,
            title: Text(label,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white)),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );

  Widget _buildRoomPreview() => Container(
        color: _kHeader,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Row(children: [
          const Icon(Icons.people, color: Colors.white70, size: 26),
          const SizedBox(width: 8),
          const Icon(Icons.volume_up, color: Colors.white70, size: 26),
          const Spacer(),
          Column(children: [
            Text(widget.room.title,
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo',
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const Text('--:--',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
          const Spacer(),
          const Icon(Icons.chat_bubble, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          const Icon(Icons.menu, color: Colors.white70, size: 24),
        ]),
      );
}
