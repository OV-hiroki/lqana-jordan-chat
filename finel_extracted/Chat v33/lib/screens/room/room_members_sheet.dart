// ============================================================
// Room Members Sheet — Classic style (like screenshots)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/shared_widgets.dart';

class RoomMembersSheet extends StatelessWidget {
  final String roomId;
  const RoomMembersSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(children: [
        // Header
        Container(
          height: 44, color: AppColors.bgHeader,
          child: Stack(alignment: Alignment.center, children: [
            const Text('إدارة الحسابات', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: 15, fontFamily: 'Cairo')),
            Positioned(right: 12,
              child: GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 22))),
          ]),
        ),

        // Members list
        Expanded(
          child: StreamBuilder<RoomModel?>(
            stream: FirestoreService.instance.listenToRoom(roomId),
            builder: (ctx, snap) {
              final room = snap.data;
              if (room == null) return const Center(child: CircularProgressIndicator());
              final speakers = room.speakers;
              final myUid = ctx.read<AuthProvider>().profile?.uid ?? '';
              final isAdmin = ctx.read<AuthProvider>().isAdmin;
              return ListView.separated(
                itemCount: speakers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _MemberRow(
                  speaker: speakers[i],
                  isMe: speakers[i].uid == myUid,
                  canManage: isAdmin,
                  roomId: roomId,
                ),
              );
            },
          ),
        ),

        // Footer
        StreamBuilder<RoomModel?>(
          stream: FirestoreService.instance.listenToRoom(roomId),
          builder: (_, snap) {
            final room = snap.data;
            final speakers  = room?.speakersCount ?? 0;
            final listeners = room?.listenersCount ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.bgTertiary,
              child: Row(children: [
                Text('متحدثون [$speakers]',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: AppColors.colorAdmin)),
                const SizedBox(width: 16),
                Text('مستمعون [$listeners]',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: AppColors.colorMember)),
                const Spacer(),
                Text('المجموع: [${speakers + listeners}]',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: AppColors.textSecondary)),
              ]),
            );
          },
        ),
      ]),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ParticipantModel speaker;
  final bool isMe;
  final bool canManage;
  final String roomId;
  const _MemberRow({required this.speaker, required this.isMe,
    required this.canManage, required this.roomId});

  Color get _nameColor {
    switch (speaker.role) {
      case AppConstants.roleHost: return AppColors.colorMaster;
      case AppConstants.roleModerator: return AppColors.colorSuperAdmin;
      case AppConstants.roleSpeaker: return AppColors.colorAdmin;
      default: return AppColors.colorMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        // Role icon
        Container(width: 22, height: 22,
          decoration: BoxDecoration(
            color: _nameColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _nameColor.withOpacity(0.4)),
          ),
          child: const Icon(Icons.person, size: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        // Name
        Expanded(child: Text(
          isMe ? '${speaker.displayName} (أنت)' : speaker.displayName,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: _nameColor, fontFamily: 'Cairo'),
        )),
        // Mute indicator
        if (speaker.isMuted)
          const Icon(Icons.mic_off, size: 14, color: AppColors.error)
        else
          const Icon(Icons.mic, size: 14, color: AppColors.speaking),
        const SizedBox(width: 6),
        // Hand
        if (speaker.hasRaisedHand) const Text('✋', style: TextStyle(fontSize: 14)),
        // Lock icon (like screenshots)
        const SizedBox(width: 6),
        Icon(Icons.lock, size: 18, color: Colors.amber.shade700),
      ]),
    );
  }
}
