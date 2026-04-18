// lib/screens/login_modal.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class LoginModal extends StatefulWidget {
  final ChatRoom room;
  final Function(ChatUser) onLoggedIn;
  const LoginModal({super.key, required this.room, required this.onLoggedIn});
  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _svc = FirebaseService();
  int _tab = 0; // 0=مسجل, 1=عضو, 2=زائر
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getString('lgana_username') ?? '';
    if (n.isNotEmpty && mounted) setState(() => _nameCtrl.text = n);
  }

  Future<void> _login() async {
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'أدخل الاسم'); return; }
    if (_tab != 2 && pass.isEmpty) { setState(() => _error = 'أدخل كلمة المرور'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      ChatUser? user;
      if (_tab == 2) {
        // زائر
        final uid = _svc.currentUid ?? DateTime.now().millisecondsSinceEpoch.toString();
        user = ChatUser(
          id: 'guest_$uid', name: name,
          role: UserRole.guest, isOnline: true,
          roomId: int.tryParse(widget.room.id),
          joinedAt: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        // مسجل أو عضو
        user = await _svc.loginWithRoomAccount(widget.room.id, name, pass);
        user ??= await _svc.loginRegistered(name, pass);
        if (user == null) {
          setState(() { _error = 'اسم المستخدم أو كلمة المرور غلط'; _loading = false; });
          return;
        }
        user = user.copyWith(isOnline: true, roomId: int.tryParse(widget.room.id));
      }

      await _svc.joinRoom(user);
      final p = await SharedPreferences.getInstance();
      await p.setString('lgana_username', name);
      if (mounted) { Navigator.pop(context); widget.onLoggedIn(user); }
    } catch (_) {
      setState(() => _error = 'حدث خطأ، حاول مجدداً');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            // 3 tabs: مسجل, عضو, زائر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _tabBtn('زائر', 2),
                  _tabBtn('عضو', 1),
                  _tabBtn('مسجل', 0),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Username field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          hintText: 'الاسم',
                          hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          filled: false,
                        ),
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                      ),
                    ),
                    Container(
                      width: 40, height: 40,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE082),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            if (_tab != 2) ...[
              const SizedBox(height: 10),
              // Password field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'كلمة المرور',
                            hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            filled: false,
                          ),
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                        ),
                      ),
                      Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.key_outlined, color: Colors.black45, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.red, fontSize: 13)),
              ),
            const SizedBox(height: 14),
            // Buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // حفظ
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white)),
                        const SizedBox(width: 6),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // إلغاء
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text('إلغاء',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // دخول
                  GestureDetector(
                    onTap: _loading ? null : _login,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF80CBC4),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: _loading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('دخول',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
              color: active ? AppColors.teal : Colors.white,
            )),
        ),
      ),
    );
  }
}
