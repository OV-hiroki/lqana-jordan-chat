// ============================================================
// Room Ban Tab — Lgana Dark Purple Theme
// ============================================================

import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

const _kBg      = Color(0xFF1A1630);
const _kSection = Color(0xFF251F40);
const _kHeader  = Color(0xFF7B1FA2);
const _kBorder  = Color(0xFF3D3358);

class RoomBanTab extends StatefulWidget {
  final String roomId;
  final bool isAdmin;
  const RoomBanTab({super.key, required this.roomId, required this.isAdmin});

  @override
  State<RoomBanTab> createState() => _RoomBanTabState();
}

class _RoomBanTabState extends State<RoomBanTab> {
  bool _showPCs = true;

  void _unban(BannedEntry entry, String docId) {
    if (!widget.isAdmin) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSection,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('إلغاء الحظر',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16)),
        content: Text('إلغاء حظر ${entry.displayName}؟',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              FirestoreService.instance.unbanFromRoom(widget.roomId, docId);
              Navigator.pop(context);
            },
            child: const Text('تأكيد',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<BannedEntry>>(
            stream: FirestoreService.instance.listenToBans(widget.roomId, pcBans: _showPCs),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final bans = snapshot.data ?? [];
              if (bans.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shield_outlined, size: 60,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    const Text('لا يوجد محظورين',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 14)),
                  ]),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: bans.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
                itemBuilder: (_, i) => _buildBanRow(bans[i]),
              );
            },
          ),
        ),
        _buildBottomToggle(),
      ]),
    );
  }

  Widget _buildHeader() => Container(
        color: _kHeader,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, color: Colors.white70, size: 16),
            SizedBox(width: 6),
            Text('المحظورون',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      );

  Widget _buildBanRow(BannedEntry entry) {
    final dateFormat =
        '${entry.bannedAt.day}/${entry.bannedAt.month}/${entry.bannedAt.year} '
        '${entry.bannedAt.hour}:${entry.bannedAt.minute.toString().padLeft(2, '0')}';
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(entry.displayName,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(entry.deviceId ?? entry.ip ?? '—',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white54)),
          const SizedBox(width: 6),
          const Icon(Icons.important_devices, size: 14, color: Colors.white38),
          const Spacer(),
          Text(entry.country ?? '—',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white54)),
          const SizedBox(width: 4),
          const Icon(Icons.location_on, size: 14, color: Colors.white38),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(entry.duration,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
          const SizedBox(width: 4),
          const Icon(Icons.timer, size: 14, color: Colors.white38),
          const Spacer(),
          Text(entry.bannedBy,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.9))),
          const SizedBox(width: 4),
          Icon(Icons.person, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(dateFormat,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white38)),
          const SizedBox(width: 4),
          const Icon(Icons.access_time, size: 12, color: Colors.white24),
        ]),
      ]),
    );
  }

  Widget _buildBottomToggle() => Container(
        color: _kSection,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _toggleBtn('Banned IPs', !_showPCs, () => setState(() => _showPCs = false)),
          Container(width: 1, height: 22, color: _kBorder),
          _toggleBtn('Banned PCs', _showPCs, () => setState(() => _showPCs = true)),
        ]),
      );

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _kHeader : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? _kHeader : _kBorder),
          ),
          child: Text(label,
              style: TextStyle(fontFamily: 'Cairo',
                  color: active ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      );
}
