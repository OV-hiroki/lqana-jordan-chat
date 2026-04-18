// lib/screens/profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  final bool isSelf;
  final Function(ChatUser)? onUpdate;
  final VoidCallback? onDM;
  const ProfileScreen({super.key, required this.user, required this.isSelf, this.onUpdate, this.onDM});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = FirebaseService();
  late ChatUser _u;
  bool _editingBio = false;
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _u = widget.user;
    _bioCtrl.text = _u.bio ?? '';
  }

  @override
  void dispose() { _bioCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            _buildBio(),
            _buildGallery(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Header (خلفية داكنة بنية + أفاتار + اسم + مستوى) ───────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.brown.shade900.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (_u.avatar != null)
            Positioned.fill(
              child: Image.network(_u.avatar!, fit: BoxFit.cover),
            ),
          if (_u.avatar != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
          Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16, right: 16, bottom: 20,
        ),
        child: Column(
          children: [
            // Back arrow
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(height: 10),
            // Avatar (مربع مع إطار)
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _u.avatar != null
                  ? Image.network(_u.avatar!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF4A3728),
                      child: const Icon(Icons.person, color: Colors.white54, size: 60)),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isSelf)
                  const Icon(Icons.edit, color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(_u.name, style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            // Level progress bar
            Row(
              children: [
                Text('المستوى: ${_u.level}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
                const Spacer(),
                Text('${(_u.levelProgress * 100).toInt()}%', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _u.levelProgress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            // Partner + Age + Country
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _headerInfo(Icons.work_outline, _u.job ?? 'لا يوجد عمل'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pillBtn('💕', 'شريك الحياة'),
                _pillBtn('🎂', '--'),
                _pillBtn('👤', 'غير محدد'),
              ],
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _headerInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white70)),
        const SizedBox(width: 6),
        Icon(icon, color: Colors.white54, size: 16),
      ],
    );
  }

  Widget _pillBtn(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white)),
          const SizedBox(width: 6),
          Text(emoji, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Stats (4 مربعات ملونة) ───────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _statBox('${_u.visitCount}', 'الزوار', AppColors.stat1),
          const SizedBox(width: 8),
          _statBox('${_u.presencePercent.toInt()}%', 'التواجد', AppColors.stat2),
          const SizedBox(width: 8),
          _statBox('${_u.talkDuration}', 'مدة التحدث', AppColors.stat3),
          const SizedBox(width: 8),
          _statBox('${_u.banCount}', 'حظر', AppColors.stat4),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // ─── Bio ──────────────────────────────────────────────────────────────────
  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _editingBio && widget.isSelf
                ? TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(border: InputBorder.none, filled: false),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  )
                : Text(
                    _u.bio?.isNotEmpty == true ? _u.bio! : 'لم يتم كتابة نبذة شخصية...',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                      color: _u.bio?.isNotEmpty == true ? Colors.black87 : Colors.grey.shade500),
                  ),
            ),
            if (widget.isSelf) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (_editingBio) {
                    await _svc.updateUserField(_u.id, 'bio', _bioCtrl.text.trim(),
                      isRegistered: _u.role != UserRole.guest);
                    setState(() { _u = _u.copyWith(bio: _bioCtrl.text.trim()); _editingBio = false; });
                    widget.onUpdate?.call(_u);
                  } else {
                    setState(() => _editingBio = true);
                  }
                },
                child: Icon(_editingBio ? Icons.check : Icons.edit,
                  color: Colors.grey.shade600, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Gallery ──────────────────────────────────────────────────────────────
  Widget _buildGallery() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('معرض الصور', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemCount: 9,
            itemBuilder: (_, i) {
              final hasImg = i < _u.gallery.length;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasImg
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_u.gallery[i], fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade400, size: 28),
                        const SizedBox(height: 4),
                        Text('إضافة صورة', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade400)),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
