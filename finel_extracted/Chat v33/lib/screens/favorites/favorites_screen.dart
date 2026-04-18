// ============================================================
// Favorites Screen — ✅ FIXED: Live stream + proper refresh
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<RoomModel> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ FIX: أعد التحميل لو تغيّر المستخدم
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = context.read<AuthProvider>().profile?.uid;
    // ✅ FIX: لا تحمّل المفضلات للمستخدم المجهول (offline_user)
    if (uid == null || uid == 'offline_user') {
      if (mounted) setState(() { _rooms = []; _loading = false; });
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final rooms = await FirestoreService.instance.getFavoriteRooms(uid);
      if (mounted) setState(() { _rooms = rooms; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _rooms = []; _loading = false; });
    }
  }

  Future<void> _removeFavorite(String roomId) async {
    final uid = context.read<AuthProvider>().profile?.uid;
    if (uid == null) return;
    await FirestoreService.instance.removeFavorite(uid, roomId);
    // ✅ FIX: أعد التحميل بعد الحذف
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<AuthProvider>().isGuest;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'المفضلات',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: isGuest
          ? _buildGuestMessage()
          : _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _rooms.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadFavorites,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _rooms.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _RoomRow(
                          room: _rooms[i],
                          onTap: () => context.push('/room/${_rooms[i].id}'),
                          onRemove: () => _removeFavorite(_rooms[i].id),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildGuestMessage() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'يجب تسجيل الدخول لعرض المفضلات',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('تسجيل الدخول',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_border, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'لا توجد غرف في المفضلات',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 8),
        const Text(
          'اضغط ★ على أي غرفة لإضافتها',
          style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _loadFavorites,
          child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ),
  );
}

class _RoomRow extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RoomRow({required this.room, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          // Room cover image or icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: (room.coverImage?.isNotEmpty ?? false)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: room.coverImage!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.mic, color: AppColors.primary, size: 26),
                    ),
                  )
                : const Icon(Icons.mic, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),

          // Room info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(room.title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: Color(0xFF212121), fontFamily: 'Cairo')),
              const SizedBox(height: 3),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(room.hostName,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo')),
                const SizedBox(width: 8),
                const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text('${room.speakersCount + room.listenersCount}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo')),
              ]),
            ]),
          ),
          const SizedBox(width: 8),

          // Status badges
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (room.isLive)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.fiber_manual_record, size: 6, color: Colors.red),
                  SizedBox(width: 2),
                  Text('LIVE', style: TextStyle(fontSize: 9,
                      color: Colors.red, fontWeight: FontWeight.bold)),
                ]),
              ),
          ]),
          const SizedBox(width: 6),

          // ✅ Remove from favorites button
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.star, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
        ]),
      ),
    );
  }
}
