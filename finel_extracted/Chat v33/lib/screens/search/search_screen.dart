// ============================================================
// Search Screen — بحث v31 — Lgana Style
// ✅ تبويبات الدول + غرف مباشرة افتراضياً + بحث متقدم
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/room_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'all'; // 'all' = كل الدول

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // ── Countries filter chips (كل + الدول) ──────────────────
  static const _allChip = {'id': 'all', 'label': 'الكل', 'flag': '🌐'};
  List<Map<String, String>> get _chips =>
      [_allChip, ...AppConstants.countries];

  // ── Filter rooms ──────────────────────────────────────────
  List<RoomModel> _filter(List<RoomModel> rooms) {
    var list = rooms;
    if (_selectedCategory != 'all') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) =>
        r.title.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q) ||
        r.hostName.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(children: [
        // ── Header with search bar ─────────────────────────
        _buildHeader(),

        // ── Country chips ──────────────────────────────────
        _buildCategoryChips(),

        // ── Room list ──────────────────────────────────────
        Expanded(child: _buildRoomList()),
      ]),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(children: [
            // Search icon
            const Icon(Icons.search, color: Colors.white70, size: 22),
            const SizedBox(width: 10),
            // Search field
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: TextField(
                  controller: _ctrl,
                  textDirection: TextDirection.rtl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14,
                      color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن غرفة أو مضيف...',
                    hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                        color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _ctrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Category chips ───────────────────────────────────────
  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      color: AppColors.bgSecondary,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _chips.length,
        itemBuilder: (_, i) {
          final chip = _chips[i];
          final isSelected = _selectedCategory == chip['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = chip['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderDefault,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(chip['flag']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(chip['label']!,
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Room list via stream ──────────────────────────────────
  Widget _buildRoomList() {
    return StreamBuilder<List<RoomModel>>(
      stream: FirestoreService.instance.listenToRooms(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
        }
        final all = snapshot.data ?? [];
        final rooms = _filter(all);

        if (rooms.isEmpty && _query.isEmpty) {
          return _emptyState(
            icon: Icons.home_outlined,
            title: 'لا توجد غرف نشطة',
            subtitle: 'لم يتم العثور على غرف مباشرة في هذه الفئة',
          );
        }
        if (rooms.isEmpty && _query.isNotEmpty) {
          return _emptyState(
            icon: Icons.search_off,
            title: 'لا توجد نتائج',
            subtitle: 'جرّب كلمة بحث مختلفة',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rooms.length,
          itemBuilder: (_, i) => _RoomCard(room: rooms[i]),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 72,
              color: AppColors.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16,
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                  color: AppColors.textMuted)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// Room card
// ─────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomModel room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/room/${room.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(children: [
          // Category icon bubble
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Center(child: Text(room.categoryIcon,
                style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.title,
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(room.hostName,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                        color: AppColors.textSecondary)),
              ]),
            ],
          )),

          // Live badge + listener count
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (room.isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: const Text('مباشر',
                    style: TextStyle(color: AppColors.primary, fontSize: 10,
                        fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.headphones, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text('${room.listenersCount}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                      color: AppColors.textMuted)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
