// ============================================================
// Jordan Audio Forum — Profile Screen
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool    _editing = false;
  bool    _saving  = false;
  File?   _newImage;
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    _nameCtrl = TextEditingController(text: p?.displayName ?? '');
    _bioCtrl  = TextEditingController(text: p?.bio ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 80,
    );
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم لا يمكن أن يكون فارغاً',
          style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
      displayName: _nameCtrl.text,
      bio: _bioCtrl.text,
      newImage: _newImage,
    );
    if (mounted) {
      setState(() { _saving = false; if (ok) { _editing = false; _newImage = null; } });
    }
  }

  void _confirmLogout() {
    // Logout is hidden in this anonymous-only flow
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    if (profile == null) return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('حسابي', style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, fontFamily: 'Cairo',
                )),
                GestureDetector(
                  onTap: () => setState(() {
                    _editing = !_editing;
                    if (!_editing) _newImage = null;
                  }),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      _editing ? Icons.close : Icons.edit_outlined,
                      color: AppColors.primary, size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Avatar
            GestureDetector(
              onTap: _editing ? _pickImage : null,
              child: Stack(children: [
                _newImage != null
                    ? CircleAvatar(radius: 52, backgroundImage: FileImage(_newImage!))
                    : UserAvatar(
                        imageUrl: profile.photoURL, name: profile.displayName,
                        size: 104, showBorder: true,
                      ),
                if (_editing) Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgPrimary, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            if (!_editing) ...[
              Text(profile.displayName == 'مجهول' || profile.displayName.isEmpty ? 'ضيف' : profile.displayName, style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'Cairo',
              )),
              const SizedBox(height: 4),
              if (profile.email.isNotEmpty && profile.email != 'guest@jordan.forum')
                Text(profile.email, style: const TextStyle(
                  fontSize: 14, color: AppColors.textMuted, fontFamily: 'Cairo',
                )),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                AppBadge(label: '🛡️ أدمن', color: AppColors.hostColor),
              ],
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(profile.bio, textAlign: TextAlign.center, style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary,
                  fontFamily: 'Cairo', height: 1.5,
                )),
              ],
              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(children: [
                  _statBox('غرف أُديرت', profile.roomsHosted),
                  _divider(),
                  _statBox('متابِعون', profile.followersCount),
                  _divider(),
                  _statBox('يتابع', profile.followingCount),
                ]),
              ),
              const SizedBox(height: 24),

              // Settings
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(children: [
                  _settingsItem(Icons.notifications_outlined, 'الإشعارات'),
                  _settingsItem(Icons.shield_outlined, 'الخصوصية والأمان'),
                  _settingsItem(Icons.help_outline, 'المساعدة والدعم'),
                ]),
              ),
            ],

            // Edit form
            if (_editing) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(children: [
                  AppInput(
                    label: 'الاسم الكامل', controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                  AppInput(
                    label: 'نبذة عنك', controller: _bioCtrl,
                    prefixIcon: Icons.info_outline, maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  AppButton(
                    label: 'حفظ التغييرات',
                    onPressed: _save, loading: _saving,
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _statBox(String label, int value) => Expanded(
    child: Column(children: [
      Text('$value', style: const TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, fontFamily: 'Cairo',
      )),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
        fontSize: 12, color: AppColors.textMuted, fontFamily: 'Cairo',
      )),
    ]),
  );

  Widget _divider() => Container(
    width: 1, height: 40, color: AppColors.borderDefault,
  );

  Widget _settingsItem(IconData icon, String label, {
    Color? color, VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderMuted)),
      ),
      child: Row(children: [
        Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(
          fontSize: 15, color: color ?? AppColors.textPrimary, fontFamily: 'Cairo',
        )),
        const Spacer(),
        if (onTap != null) const Icon(Icons.chevron_right,
          color: AppColors.textMuted, size: 18),
      ]),
    ),
  );
}
