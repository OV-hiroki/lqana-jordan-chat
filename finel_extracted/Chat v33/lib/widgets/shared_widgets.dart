// ============================================================
// Jordan Audio Forum — Shared Widgets
// ============================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/room_model.dart';

// ─────────────────────────────────────────────
// 🔘 AppButton
// ─────────────────────────────────────────────
enum ButtonVariant { primary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonVariant variant;
  final double? width;
  final double height;
  final Widget? icon;

  const AppButton({
    super.key, required this.label, this.onPressed,
    this.loading = false, this.variant = ButtonVariant.primary,
    this.width, this.height = 52, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    Color bg, fg, border;
    switch (variant) {
      case ButtonVariant.outline:
        bg = Colors.transparent; fg = AppColors.primary; border = AppColors.primary;
      case ButtonVariant.ghost:
        bg = AppColors.bgTertiary; fg = AppColors.textPrimary; border = Colors.transparent;
      case ButtonVariant.danger:
        bg = AppColors.errorMuted; fg = AppColors.error; border = AppColors.error;
      default:
        bg = AppColors.primary; fg = AppColors.white; border = Colors.transparent;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            side: BorderSide(color: border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(label, style: TextStyle(
                      color: fg, fontWeight: FontWeight.w700,
                      fontSize: 15, fontFamily: 'Cairo',
                    )),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 📝 AppInput
// ─────────────────────────────────────────────
class AppInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? errorText;
  final int maxLines;
  final TextCapitalization textCapitalization;

  const AppInput({
    super.key, this.label, this.hint, required this.controller,
    this.obscure = false, this.keyboardType = TextInputType.text,
    this.prefixIcon, this.suffixIcon, this.onSuffixTap,
    this.errorText, this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Cairo',
              )),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            textCapitalization: widget.textCapitalization,
            style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon,
                      color: _focused ? AppColors.primary : AppColors.textMuted, size: 20)
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(widget.suffixIcon, color: AppColors.textMuted, size: 20))
                  : null,
              errorText: widget.errorText,
              errorStyle: const TextStyle(color: AppColors.error, fontSize: 12, fontFamily: 'Cairo'),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 👤 UserAvatar
// ─────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key, this.imageUrl, required this.name,
    this.size = 48, this.showBorder = false, this.borderColor,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    return parts.length == 1
        ? parts[0][0].toUpperCase()
        : '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    Widget avatar = imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            imageBuilder: (_, img) => CircleAvatar(
              radius: radius, backgroundImage: img,
              backgroundColor: AppColors.bgSecondary,
            ),
            placeholder: (_, __) => _placeholder(radius),
            errorWidget: (_, __, ___) => _placeholder(radius),
          )
        : _placeholder(radius);

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.primary, width: 2,
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(2), child: avatar),
      );
    }
    return SizedBox(width: size, height: size, child: avatar);
  }

  Widget _placeholder(double radius) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.primaryMuted,
    child: Text(_initials, style: TextStyle(
      color: AppColors.white, fontWeight: FontWeight.w700,
      fontSize: radius * 0.7, fontFamily: 'Cairo',
    )),
  );
}

// ─────────────────────────────────────────────
// 🏠 RoomCard
// ─────────────────────────────────────────────
class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category + Live badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge(label: '${room.categoryIcon} ${room.category}', color: AppColors.primary),
                if (room.isLive) _liveBadge(),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(room.title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, fontFamily: 'Cairo',
            ), maxLines: 2, overflow: TextOverflow.ellipsis),

            if (room.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(room.description, style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Cairo',
              ), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],

            // Speakers avatars
            if (room.speakers.isNotEmpty) ...[
              const SizedBox(height: 12),
              _speakersRow(),
            ],

            // Stats
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.mic, size: 13, color: AppColors.speaking),
              const SizedBox(width: 4),
              Text('${room.speakersCount}', style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
              const SizedBox(width: 12),
              const Icon(Icons.headset, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${room.listenersCount}', style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
              const Spacer(),
              Text('${room.totalParticipants} مشارك', style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12, fontFamily: 'Cairo')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _liveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.errorMuted, borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(
        color: AppColors.error, shape: BoxShape.circle,
      )),
      const SizedBox(width: 4),
      const Text('مباشر', style: TextStyle(
        color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
      )),
    ]),
  );

  Widget _speakersRow() => Row(children: [
    ...room.speakers.take(4).toList().asMap().entries.map((e) =>
        Padding(
          padding: EdgeInsets.only(left: e.key > 0 ? -8 : 0),
          child: UserAvatar(
            imageUrl: e.value.photoURL, name: e.value.displayName,
            size: 32, showBorder: true,
          ),
        )),
    if (room.speakers.length > 4)
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text('+${room.speakers.length - 4}', style: const TextStyle(
          color: AppColors.textMuted, fontSize: 12, fontFamily: 'Cairo',
        )),
      ),
  ]);
}

// ─────────────────────────────────────────────
// 📛 AppBadge
// ─────────────────────────────────────────────
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AppBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(
      color: color, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
    )),
  );
}
