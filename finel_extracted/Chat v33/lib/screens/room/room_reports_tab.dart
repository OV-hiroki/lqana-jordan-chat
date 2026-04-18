// ============================================================
// Room Reports Tab — Lgana Dark Purple Theme
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

class RoomReportsTab extends StatefulWidget {
  final String roomId;
  const RoomReportsTab({super.key, required this.roomId});

  @override
  State<RoomReportsTab> createState() => _RoomReportsTabState();
}

class _RoomReportsTabState extends State<RoomReportsTab> {
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
              Icon(Icons.admin_panel_settings, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('تقارير المشرفين',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<AdminReportEntry>>(
            stream: FirestoreService.instance.listenToAdminReports(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              final allReports = snapshot.data ?? [];
              if (allReports.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.assignment_outlined, size: 60,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    const Text('لا توجد تقارير',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 14)),
                  ]),
                );
              }

              final totalRecords = allReports.length;
              final totalPages = (totalRecords / _pageSize).ceil().clamp(1, 9999);
              final page = _currentPage.clamp(1, totalPages);
              final start = (page - 1) * _pageSize;
              final end = (start + _pageSize).clamp(0, totalRecords);
              final pageReports = allReports.sublist(start, end);

              return Column(children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: pageReports.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _kBorder),
                    itemBuilder: (_, i) => _buildReportRow(pageReports[i]),
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

  Widget _buildReportRow(AdminReportEntry report) {
    final dateStr =
        '${report.timestamp.day.toString().padLeft(2, '0')}/'
        '${report.timestamp.month.toString().padLeft(2, '0')}/'
        '${report.timestamp.year} '
        '${report.timestamp.hour.toString().padLeft(2, '0')}:'
        '${report.timestamp.minute.toString().padLeft(2, '0')} '
        '${report.timestamp.hour < 12 ? 'AM' : 'PM'}';

    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Admin name
        Text(report.adminName,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
                fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 6),

        // Action + target
        Row(children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.white38),
          const SizedBox(width: 4),
          Text(report.action,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white70)),
          const Spacer(),
          const Icon(Icons.person_pin, size: 13, color: Colors.white38),
          const SizedBox(width: 4),
          Text(report.targetName,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 6),

        // Timestamp
        Row(children: [
          const Icon(Icons.access_time, size: 13, color: Colors.white30),
          const SizedBox(width: 4),
          Text(dateStr,
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
          Text('عدد التقارير: $totalRecords',
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
