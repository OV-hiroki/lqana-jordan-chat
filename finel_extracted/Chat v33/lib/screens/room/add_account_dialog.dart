// ============================================================
// Jordan Audio Forum — Login Screen v31
// ✅ ثلاثة تبويبات: مسجَّل | عضو جديد | زائر
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

// ── Pink & White Theme ──────────────────────────────────
const _kGrad1  = AppColors.bgPrimary;
const _kGrad2  = AppColors.bgTertiary;
const _kCard   = AppColors.bgSecondary;
const _kBorder = AppColors.primary;
const _kInput  = AppColors.bgPrimary;
const _kPink   = AppColors.primary;
// ──────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kGrad1, _kGrad2],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 20),

              // ── زر رجوع ─────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.arrow_back_ios,
                      size: 13, color: AppColors.textSecondary),
                  label: const Text('رجوع',
                      style: TextStyle(color: AppColors.textSecondary,
                          fontFamily: 'Cairo', fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),

              // ── شعار + اسم التطبيق ──────────────────────
              _Logo(),
              const SizedBox(height: 28),

              // ── بطاقة التبويبات ──────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(children: [
                  // ── شريط التبويبات ──────────────────────
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tab,
                      labelStyle: const TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                          fontSize: 13),
                      unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Cairo', fontSize: 13),
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicator: BoxDecoration(
                        color: _kPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'مسجَّل'),
                        Tab(text: 'عضو جديد'),
                        Tab(text: 'زائر'),
                      ],
                    ),
                  ),

                  // ── محتوى التبويبات ──────────────────────
                  SizedBox(
                    height: 420,
                    child: TabBarView(
                      controller: _tab,
                      children: const [
                        _LoginTab(),
                        _RegisterTab(),
                        _GuestTab(),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Logo component
// ─────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [
            AppColors.primaryLight, AppColors.primary,
          ]),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20, spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.mic, size: 40, color: Colors.white),
      ),
      const SizedBox(height: 12),
      const Text(AppConstants.appName,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary, fontFamily: 'Cairo')),
      const Text('غرف الصوت الحية',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
              fontFamily: 'Cairo')),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — تسجيل الدخول
// ─────────────────────────────────────────────────────────────
class _LoginTab extends StatefulWidget {
  const _LoginTab();
  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _showPass  = false;
  bool _loading   = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _error = null; _loading = true; });
    final ok = await context.read<AuthProvider>().login(
        _email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = context.read<AuthProvider>().error);
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(children: [
        if (_error != null) _ErrorBox(msg: _error!),
        _DarkInput(ctrl: _email, hint: 'البريد الإلكتروني',
            icon: Icons.mail_outline, type: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _DarkInput(ctrl: _password, hint: 'كلمة المرور',
            icon: Icons.lock_outline, obscure: !_showPass,
            suffixIcon: _showPass
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffix: () => setState(() => _showPass = !_showPass)),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {},
            child: const Text('نسيت كلمة المرور؟',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Cairo', fontSize: 12)),
          ),
        ),
        const SizedBox(height: 4),
        _PinkButton(
            label: 'تسجيل الدخول',
            loading: _loading,
            icon: Icons.login,
            onTap: _login),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('ليس لديك حساب؟ ',
              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo', fontSize: 13)),
          GestureDetector(
            onTap: () => context.pushReplacement('/register'),
            child: const Text('سجّل الآن',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo', fontSize: 13)),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — عضو جديد (تسجيل)
// ─────────────────────────────────────────────────────────────
class _RegisterTab extends StatefulWidget {
  const _RegisterTab();
  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  File? _imageFile;
  bool _showPass = false;
  bool _loading  = false;
  String? _error;

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (x != null && mounted) setState(() => _imageFile = File(x.path));
  }

  String? _validate() {
    if (_name.text.trim().length < 2) return 'الاسم يجب أن يكون حرفين على الأقل';
    if (_email.text.trim().isEmpty)   return 'البريد الإلكتروني مطلوب';
    if (_password.text.length < 6)    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  Future<void> _register() async {
    final err = _validate();
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _error = null; _loading = true; });
    final ok = await context.read<AuthProvider>().register(
      email: _email.text, password: _password.text,
      displayName: _name.text, profileImage: _imageFile,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = context.read<AuthProvider>().error);
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(children: [
        // Avatar picker
        GestureDetector(
          onTap: _pickImage,
          child: Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.bgPrimary,
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? const Icon(Icons.person, size: 32, color: AppColors.textMuted)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        if (_error != null) _ErrorBox(msg: _error!),
        _DarkInput(ctrl: _name, hint: 'الاسم الكامل', icon: Icons.person_outline),
        const SizedBox(height: 8),
        _DarkInput(ctrl: _email, hint: 'البريد الإلكتروني',
            icon: Icons.mail_outline, type: TextInputType.emailAddress),
        const SizedBox(height: 8),
        _DarkInput(ctrl: _password, hint: 'كلمة المرور (6+ أحرف)',
            icon: Icons.lock_outline, obscure: !_showPass,
            suffixIcon: _showPass
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffix: () => setState(() => _showPass = !_showPass)),
        const SizedBox(height: 12),
        _PinkButton(
            label: 'إنشاء الحساب',
            loading: _loading,
            icon: Icons.person_add_outlined,
            onTap: _register),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3 — زائر
// ─────────────────────────────────────────────────────────────
class _GuestTab extends StatefulWidget {
  const _GuestTab();
  @override
  State<_GuestTab> createState() => _GuestTabState();
}

class _GuestTabState extends State<_GuestTab> {
  final _nick    = TextEditingController();
  bool _loading  = false;
  String? _error;

  Future<void> _enter() async {
    final name = _nick.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'الاسم يجب أن يكون حرفين على الأقل');
      return;
    }
    setState(() { _error = null; _loading = true; });
    await context.read<AuthProvider>().updateProfile(displayName: name);
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() { _nick.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Icon area
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.person_outline, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Text('دخول كضيف',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('ادخل غرف الصوت بدون تسجيل',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
                color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        if (_error != null) _ErrorBox(msg: _error!),
        _DarkInput(
          ctrl: _nick,
          hint: 'اسمك المستعار (مثال: أبو علي)',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        _PinkButton(
          label: 'دخول الغرف',
          loading: _loading,
          icon: Icons.mic,
          onTap: _enter,
        ),
        const SizedBox(height: 16),
        Text(
          'الزوار لا يمكنهم إنشاء غرف أو إرسال صور',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
              color: AppColors.textMuted),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────
class _DarkInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final IconData? suffixIcon;
  final VoidCallback? onSuffix;

  const _DarkInput({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.onSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: AppColors.textMuted, size: 20),
                onPressed: onSuffix)
            : null,
        filled: true,
        fillColor: _kInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kBorder.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kBorder.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

class _PinkButton extends StatelessWidget {
  final String label;
  final bool loading;
  final IconData icon;
  final VoidCallback onTap;

  const _PinkButton({
    required this.label,
    required this.loading,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Icon(icon, size: 18, color: Colors.white),
        label: Text(
          loading ? 'جار التحميل...' : label,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
              fontSize: 15, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.borderDefault,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(color: AppColors.error,
                fontSize: 12, fontFamily: 'Cairo'))),
      ]),
    );
  }
}
