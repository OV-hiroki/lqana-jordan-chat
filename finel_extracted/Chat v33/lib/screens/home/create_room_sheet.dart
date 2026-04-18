// ============================================================
//  Create Room Sheet — مع رفع صورة الغرفة + تصنيف بالدول
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/shared_widgets.dart';

class CreateRoomSheet extends StatefulWidget {
  final void Function(RoomModel room) onCreated;
  const CreateRoomSheet({super.key, required this.onCreated});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _title       = TextEditingController();
  final _description = TextEditingController();
  String  _category  = AppConstants.countries.first['id']!;
  bool    _isPublic  = true;
  bool    _loading   = false;
  String? _error;

  // Room cover image
  File?   _imageFile;
  String? _uploadedImageUrl;
  bool    _uploadingImage = false;

  static const _purple = Color(0xFF9C27B0);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile  = await picker.pickImage(
      source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (xfile == null || !mounted) return;

    setState(() { _imageFile = File(xfile.path); _uploadingImage = true; });

    try {
      final bytes = await xfile.readAsBytes();
      final filename = 'room_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await CloudinaryService.instance.uploadImageBytes(
        bytes,
        filename: filename,
        folder: AppConstants.folderRoomImages,
      );
      if (mounted) {
        setState(() {
          _uploadedImageUrl = result.url;
          _uploadingImage = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _create() async {
    if (_title.text.trim().length < 3) {
      setState(() => _error = 'العنوان يجب أن يكون 3 أحرف على الأقل');
      return;
    }
    if (_uploadingImage) {
      setState(() => _error = 'انتظر حتى يكتمل رفع الصورة');
      return;
    }

    setState(() { _error = null; _loading = true; });

    try {
      final profile = context.read<AuthProvider>().profile!;
      final room = await FirestoreService.instance.createRoom(
        title:       _title.text.trim(),
        description: _description.text.trim(),
        category:    _category,
        host:        profile,
        isPublic:    _isPublic,
        coverImage:  _uploadedImageUrl,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(room);
      }
    } catch (e) {
      setState(() { _error = 'حدث خطأ: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDefault, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إنشاء غرفة جديدة',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Cairo')),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 24),

          Expanded(child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // Error
              if (_error != null) Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorMuted, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(
                    color: AppColors.error, fontSize: 13, fontFamily: 'Cairo'))),
                ]),
              ),

              // ── Cover image picker ────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
                  ),
                  child: _uploadingImage
                    ? const Center(child: CircularProgressIndicator(color: _purple))
                    : _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_imageFile!, fit: BoxFit.cover,
                            width: double.infinity),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: _purple, size: 36),
                            SizedBox(height: 8),
                            Text('أضف صورة للغرفة (اختياري)',
                              style: TextStyle(color: _purple, fontFamily: 'Cairo',
                                  fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────
              AppInput(
                label: 'عنوان الغرفة *',
                hint: 'مثال: غرفة الأردن العامة',
                controller: _title,
                prefixIcon: Icons.mic_outlined,
                textCapitalization: TextCapitalization.sentences,
              ),
              AppInput(
                label: 'وصف الغرفة (اختياري)',
                hint: 'عمَّ ستتحدثون؟',
                controller: _description,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              // ── Country / Category ────────────────────────
              const Text('القسم',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13,
                    fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: AppConstants.countries.map((c) {
                  final sel = _category == c['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _category = c['id']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFEDE7F6) : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? _purple : AppColors.borderDefault),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c['flag']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(c['label']!, style: TextStyle(
                          color: sel ? _purple : AppColors.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Privacy ───────────────────────────────────
              const Text('الخصوصية',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13,
                    fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _privacyOption(true,  Icons.public,       'عامة')),
                const SizedBox(width: 12),
                Expanded(child: _privacyOption(false, Icons.lock_outline, 'خاصة')),
              ]),
              const SizedBox(height: 28),

              AppButton(
                label: 'إنشاء الغرفة وبدء البث 🎙️',
                onPressed: _create,
                loading: _loading,
              ),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _privacyOption(bool value, IconData icon, String label) {
    final sel = _isPublic == value;
    return GestureDetector(
      onTap: () => setState(() => _isPublic = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFEDE7F6) : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? _purple : AppColors.borderDefault),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? _purple : AppColors.textMuted, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            color: sel ? _purple : AppColors.textMuted,
            fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Cairo')),
        ]),
      ),
    );
  }
}
