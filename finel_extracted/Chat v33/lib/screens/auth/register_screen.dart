// ============================================================
// Jordan Audio Forum — Register Screen
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();
  final _bio      = TextEditingController();

  File?  _imageFile;
  bool   _showPass = false;
  bool   _loading  = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  String? _validate() {
    if (_name.text.trim().length < 2) return 'الاسم يجب أن يكون حرفين على الأقل';
    if (_email.text.trim().isEmpty)   return 'البريد الإلكتروني مطلوب';
    if (_password.text.length < 6)    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    if (_password.text != _confirm.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  Future<void> _register() async {
    final err = _validate();
    if (err != null) { setState(() => _error = err); return; }

    setState(() { _error = null; _loading = true; });
    final ok = await context.read<AuthProvider>().register(
      email: _email.text, password: _password.text,
      displayName: _name.text, profileImage: _imageFile, bio: _bio.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) setState(() => _error = context.read<AuthProvider>().error);
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose();
    _confirm.dispose(); _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // ── Back button ────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                icon: const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.textMuted),
                label: const Text('رجوع', style: TextStyle(
                  color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 13,
                )),
              ),
            ),
            // Header
            Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Text('إنشاء حساب جديد', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'Cairo',
              )),
            ]),
            const SizedBox(height: 28),

            // Avatar picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(children: [
                _imageFile != null
                    ? CircleAvatar(radius: 50, backgroundImage: FileImage(_imageFile!))
                    : CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryMuted,
                        child: Text(
                          _name.text.trim().isEmpty ? '?' :
                              _name.text.trim()[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36, color: AppColors.white,
                            fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgPrimary, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            const Text('اضغط لإضافة صورة', style: TextStyle(
              color: AppColors.textMuted, fontSize: 12, fontFamily: 'Cairo',
            )),
            const SizedBox(height: 24),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(children: [
                if (_error != null) _errorBox(_error!),

                AppInput(
                  label: 'الاسم الكامل', hint: 'اسمك الذي يظهر للآخرين',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
                AppInput(
                  label: 'البريد الإلكتروني', hint: 'example@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                ),
                AppInput(
                  label: 'كلمة المرور', hint: '6 أحرف على الأقل',
                  controller: _password, obscure: !_showPass,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  onSuffixTap: () => setState(() => _showPass = !_showPass),
                ),
                AppInput(
                  label: 'تأكيد كلمة المرور', hint: 'أعد كتابة كلمة المرور',
                  controller: _confirm, obscure: !_showPass,
                  prefixIcon: Icons.lock_outline,
                ),
                AppInput(
                  label: 'نبذة عنك (اختياري)', hint: 'أخبر الناس شيئاً عنك...',
                  controller: _bio,
                  prefixIcon: Icons.info_outline,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),

                AppButton(
                  label: 'إنشاء الحساب',
                  onPressed: _register,
                  loading: _loading,
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('لديك حساب بالفعل؟ ', style: TextStyle(
                    color: AppColors.textSecondary, fontFamily: 'Cairo',
                  )),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/login'),
                    child: const Text('سجّل دخولك', style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                    )),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.errorMuted, borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(
        color: AppColors.error, fontSize: 13, fontFamily: 'Cairo',
      ))),
    ]),
  );
}
