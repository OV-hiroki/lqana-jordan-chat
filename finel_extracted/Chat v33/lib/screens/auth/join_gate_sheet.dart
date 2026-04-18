// ============================================================
// Join Gate Sheet — Lgana v31
// ✅ ثلاثة تبويبات: مسجَّل | عضو | زائر
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

const _kSheet  = Color(0xFF1A1630);
const _kCard   = Color(0xFF251F40);
const _kBorder = Color(0xFF3D3358);
const _kInput  = Color(0xFF1E1A35);
const _kPink   = Color(0xFFEB4C72);
const _kTabBg  = Color(0xFF120F25);

class JoinGateSheet extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onJoined;

  const JoinGateSheet({
    super.key,
    required this.room,
    required this.onJoined,
  });

  @override
  State<JoinGateSheet> createState() => _JoinGateSheetState();
}

class _JoinGateSheetState extends State<JoinGateSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _goAuth(String route) {
    Navigator.of(context).pop();
    // ✅ FIX: نمرر roomId عشان بعد الدخول يرجع للغرفة تلقائياً
    context.push(route, extra: widget.room.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── Drag handle ─────────────────────────────
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _kBorder, borderRadius: BorderRadius.circular(2)),
            ),

            // ── Room info header ─────────────────────────
            _RoomHeader(room: widget.room),
            const SizedBox(height: 20),

            // ── Tab bar ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _kTabBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                labelStyle: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                indicator: BoxDecoration(
                  color: _kPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'مسجَّل'),
                  Tab(text: 'عضو'),
                  Tab(text: 'زائر'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab content ──────────────────────────────
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tab,
                children: [
                  // Tab 1: تسجيل الدخول
                  _LoginSection(onLogin: () => _goAuth('/login')),
                  // Tab 2: إنشاء حساب
                  _RegisterSection(onRegister: () => _goAuth('/register')),
                  // Tab 3: زائر
                  _GuestSection(
                    room: widget.room,
                    onJoined: () {
                      Navigator.of(context).pop();
                      widget.onJoined();
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Room header
// ─────────────────────────────────────────────────────────────
class _RoomHeader extends StatelessWidget {
  final RoomModel room;
  const _RoomHeader({required this.room});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Center(
          child: Text(room.categoryIcon, style: const TextStyle(fontSize: 26)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(room.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: Colors.white, fontFamily: 'Cairo'),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.person, size: 13, color: Colors.white38),
            const SizedBox(width: 3),
            Text(room.hostName,
                style: const TextStyle(fontSize: 12, color: Colors.white54,
                    fontFamily: 'Cairo')),
            if (room.isLive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _kPink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('مباشر',
                    style: TextStyle(fontSize: 10, color: _kPink,
                        fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              ),
            ],
          ]),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1: مسجَّل (تسجيل الدخول)
// ─────────────────────────────────────────────────────────────
class _LoginSection extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginSection({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_outlined, color: _kPink, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('حساب مسجَّل', style: TextStyle(fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
              Text('ادخل بحسابك للحصول على مميزات كاملة',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 11)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 46,
        child: ElevatedButton.icon(
          onPressed: onLogin,
          icon: const Icon(Icons.login, size: 18, color: Colors.white),
          label: const Text('تسجيل الدخول',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                  fontSize: 15, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2: عضو (إنشاء حساب)
// ─────────────────────────────────────────────────────────────
class _RegisterSection extends StatelessWidget {
  final VoidCallback onRegister;
  const _RegisterSection({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_add_outlined, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('عضو جديد', style: TextStyle(fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
              Text('إنشاء حساب مجاني في ثوانٍ',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 11)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 46,
        child: OutlinedButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.person_add_outlined, size: 18, color: _kPink),
          label: const Text('إنشاء حساب',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                  fontSize: 15, color: _kPink)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kPink, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3: زائر
// ─────────────────────────────────────────────────────────────
class _GuestSection extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onJoined;
  const _GuestSection({required this.room, required this.onJoined});

  @override
  State<_GuestSection> createState() => _GuestSectionState();
}

class _GuestSectionState extends State<_GuestSection> {
  final _nick = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    final name = _nick.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'الاسم يجب أن يكون حرفين على الأقل');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await context.read<AuthProvider>().updateProfile(displayName: name);
    if (!mounted) return;
    widget.onJoined();
  }

  @override
  void dispose() { _nick.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (_error != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A0010),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_error!,
              style: const TextStyle(color: AppColors.error,
                  fontSize: 12, fontFamily: 'Cairo')),
        ),
      TextField(
        controller: _nick,
        textAlign: TextAlign.right,
        autofocus: false,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white),
        onSubmitted: (_) => _loading ? null : _confirm(),
        decoration: InputDecoration(
          hintText: 'اسمك المستعار...',
          hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.white30, fontSize: 13),
          prefixIcon: const Icon(Icons.person_outline, color: Colors.white38, size: 20),
          filled: true,
          fillColor: _kInput,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPink, width: 1.5)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity, height: 46,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _confirm,
          icon: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.mic, size: 18, color: Colors.white),
          label: Text(
            _loading ? 'جار الدخول...' : 'ادخل الغرفة',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                fontSize: 15, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B1FA2),
            disabledBackgroundColor: _kBorder,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}
