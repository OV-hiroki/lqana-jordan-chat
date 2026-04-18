// ============================================================
// Room Log Tab — Lgana Dark Purple Theme
// ============================================================

import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

const _kBg      = Color(0xFF1A1630);
const _kSection = Color(0xFF251F40);
const _kHeader  = Color(0xFF7B1FA2);
const _kBorder  = Color(0xFF3D3358);
const _kPagBg   = Color(0xFF120F25);

class RoomLogTab extends StatefulWidget {
  final String roomId;
  const RoomLogTab({super.key, required this.roomId});

  @override
  State<RoomLogTab> createState() => _RoomLogTabState();
}

class _RoomLogTabState extends State<RoomLogTab> {
  static const int _pageSize = 10;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(children: [
        // Header
        Container(
          color: _kHeader,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('سجل الغرفة',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<RoomLogEntry>>(
            stream: FirestoreService.instance.listenToRoomLog(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              final allLogs = snapshot.data ?? [];
              if (allLogs.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.history_toggle_off, size: 60,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    const Text('لا يوجد سجل',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 14)),
                  ]),
                );
              }

              final totalRecords = allLogs.length;
              final totalPages = (totalRecords / _pageSize).ceil().clamp(1, 9999);
              final page = _currentPage.clamp(1, totalPages);
              final start = (page - 1) * _pageSize;
              final end = (start + _pageSize).clamp(0, totalRecords);
              final pageLogs = allLogs.sublist(start, end);

              return Column(children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: pageLogs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _kBorder),
                    itemBuilder: (_, i) => _buildLogRow(pageLogs[i]),
                  ),
                ),
                _buildPagination(totalRecords, page, totalPages),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildLogRow(RoomLogEntry log) {
    String fmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.hour < 12 ? 'AM' : 'PM'}';

    final joinTime  = fmt(log.joinedAt);
    final leaveTime = log.leftAt != null ? fmt(log.leftAt!) : 'الآن';

    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Name
        Text(log.displayName,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14,
                fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 5),

        // Country + Device ID
        Row(children: [
          const Icon(Icons.location_on, size: 13, color: Colors.white38),
          const SizedBox(width: 4),
          Text(log.country ?? '—',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white54)),
          const Spacer(),
          const Icon(Icons.important_devices, size: 13, color: Colors.white38),
          const SizedBox(width: 4),
          Text(log.deviceId ?? '—',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white54)),
        ]),
        const SizedBox(height: 4),

        // Join + Duration
        Row(children: [
          const Icon(Icons.call_made, size: 12, color: Colors.white30),
          const SizedBox(width: 4),
          Text(joinTime,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white38)),
          const Spacer(),
          const Icon(Icons.av_timer, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 4),
          Text(log.durationLabel.isEmpty ? '—' : log.durationLabel,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                  fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
        ]),
        const SizedBox(height: 2),

        // Leave time
        Row(children: [
          const Icon(Icons.call_received, size: 12, color: Colors.white30),
          const SizedBox(width: 4),
          Text(leaveTime,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white38)),
        ]),
      ]),
    );
  }

  Widget _buildPagination(int totalRecords, int page, int totalPages) {
    return Container(
      color: _kPagBg,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(children: [
        // Prev / Next
        Row(children: [
          _pageBtn(
            icon: Icons.chevron_left,
            active: page > 1,
            onTap: page > 1 ? () => setState(() => _currentPage = page - 1) : null,
          ),
          const SizedBox(width: 6),
          _pageBtn(
            icon: Icons.chevron_right,
            active: page < totalPages,
            onTap: page < totalPages ? () => setState(() => _currentPage = page + 1) : null,
          ),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text('عدد السجلات: $totalRecords',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white54)),
          Text('الصفحة: $page / $totalPages',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white54)),
        ]),
      ]),
    );
  }

  Widget _pageBtn({required IconData icon, required bool active, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? _kHeader : _kSection,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? Colors.white : Colors.white24, size: 18),
        ),
      );
}
