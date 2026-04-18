// ============================================================
// More Screen — الصفحة الإضافية (مثل lgana.com)
// ✅ v24: تصميم مطابق للقطة الشاشة
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/shared_widgets.dart';
import '../home/support_chat_sheet.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});
  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _totalUsers = 0;
  int _totalRooms = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final rooms = await FirestoreService.instance.getAllRooms();
      final liveRooms = rooms.where((r) => r.isLive).length;
      if (!mounted) return;
      setState(() {
        _totalRooms = liveRooms;
        _totalUsers = rooms.fold(0, (s, r) => s + r.speakersCount + r.listenersCount);
      });
    } catch (_) {}
  }

  void _openSupportChat() {
    final isGuest = context.read<AuthProvider>().isGuest;
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يجب تسجيل الدخول أولاً للتواصل مع الدعم',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.primary,
      ));
      context.push('/login');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupportChatSheet(),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('عن البرنامج',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(AppConstants.appName,
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800,
                  fontSize: 18, color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('الإصدار ${AppConstants.appVersion}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                  color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text('غرف صوتية وكتابية مباشرة',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً',
                style: TextStyle(color: AppColors.primary, fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isGuest = context.watch<AuthProvider>().isGuest;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(children: [
        // ── Header (pink lgana style) ─────────────────────
        _buildHeader(profile, isGuest),

        // ── Menu list ─────────────────────────────────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _menuItem(
                label: 'الاعدادات',
                onTap: () => context.push('/settings'),
              ),
              _divider(),
              _menuItem(
                label: 'غرفة المبيعات',
                onTap: _openSupportChat,
              ),
              _divider(),
              _menuItem(
                label: 'شراء خدمة',
                onTap: _openSupportChat,
              ),
              _divider(),
              _menuItem(
                label: 'خدمة العملاء',
                onTap: _openSupportChat,
              ),
              _divider(),
              _menuItem(
                label: 'اعادة تحميل القائمة',
                onTap: () {
                  _loadStats();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم إعادة تحميل القائمة',
                        style: TextStyle(fontFamily: 'Cairo')),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ));
                },
              ),
              _divider(),
              _menuItem(
                label: 'عن البرنامج',
                onTap: _showAbout,
              ),
              _divider(),

              // ── Admin items (shown only for admins) ────────
              if (isAdmin) ...[
                _menuItem(
                  label: 'لوحة الإدارة',
                  onTap: () => context.go('/admin'),
                  isHighlighted: true,
                ),
                _divider(),
              ],

              // ── Login / Logout ─────────────────────────────
              if (isGuest)
                _menuItem(
                  label: 'تسجيل الدخول / إنشاء حساب',
                  onTap: () => context.push('/login'),
                  isHighlighted: true,
                )
              else
                _menuItem(
                  label: 'تسجيل الخروج',
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/');
                  },
                  isDanger: true,
                ),
              _divider(),

              const SizedBox(height: 40),
            ],
          ),
        ),

        // ── Stats bar (like lgana) ─────────────────────────
        _buildStatsBar(),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(profile, bool isGuest) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            // Avatar / login hint
            GestureDetector(
              onTap: () => isGuest ? context.push('/login') : context.go('/profile'),
              child: isGuest
                  ? Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 1.5),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Colors.white, size: 24),
                    )
                  : UserAvatar(
                      imageUrl: profile?.photoURL,
                      name: profile?.displayName ?? '?',
                      size: 44,
                      showBorder: true,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isGuest ? 'أهلاً بك' : (profile?.displayName ?? 'مستخدم'),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  isGuest ? 'اضغط لتسجيل الدخول' : (profile?.email ?? ''),
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 12, fontFamily: 'Cairo',
                  ),
                ),
              ]),
            ),
            // App logo icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white24, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Menu item ─────────────────────────────────────────────
  Widget _menuItem({
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: isDanger
                ? AppColors.error
                : isHighlighted
                    ? AppColors.primary
                    : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        color: AppColors.borderMuted,
      );

  // ── Stats bar ─────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.group, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 4),
        Text('$_totalUsers مستخدم',
            style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13,
              color: AppColors.textSecondary)),
        const SizedBox(width: 24),
        const Icon(Icons.chat_bubble_outline,
            color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 4),
        Text('$_totalRooms غرفة',
            style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13,
              color: AppColors.textSecondary)),
      ]),
    );
  }
}
