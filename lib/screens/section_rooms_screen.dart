// lib/screens/section_rooms_screen.dart
// شاشة عرض غرف قسم معين في صفحة مستقلة
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/favorites_store.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'login_modal.dart';

class SectionRoomsScreen extends StatefulWidget {
  final RoomSection section;
  final ChatUser? me;

  const SectionRoomsScreen({super.key, required this.section, this.me});

  @override
  State<SectionRoomsScreen> createState() => _SectionRoomsScreenState();
}

class _SectionRoomsScreenState extends State<SectionRoomsScreen> {
  final _svc = FirebaseService();
  List<ChatUser> _onlineUsers = [];
  ChatUser? _me;
  final List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _me = widget.me;
    FavoritesStore.load().then((l) {
      if (mounted) setState(() => _favorites..clear()..addAll(l));
    });
    _svc.allOnlineUsersStream().listen((u) {
      if (mounted) setState(() => _onlineUsers = u);
    });
  }

  void _onRoomTap(ChatRoom room) {
    if (_me == null) {
      _showLogin(room);
    } else {
      _enterRoom(room);
    }
  }

  void _enterRoom(ChatRoom room) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(room: room, me: _me!,
        onMeUpdated: (u) => setState(() => _me = u)),
    )).then((_) {
      FavoritesStore.load().then((l) {
        if (mounted) setState(() { _favorites.clear(); _favorites.addAll(l); });
      });
    });
  }

  void _showLogin(ChatRoom room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LoginModal(
        room: room,
        onLoggedIn: (user) {
          setState(() => _me = user);
          _enterRoom(room);
        },
      ),
    );
  }

  int _onlineInRoom(ChatRoom room) {
    return _onlineUsers.where((u) => u.roomId == int.tryParse(room.id)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lobbyListTeal,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: widget.section.rooms.isEmpty
              ? _buildEmptyState()
              : _buildRoomsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() => Container(
    color: Colors.white,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      right: 16,
      bottom: 12,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_forward, size: 20, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.section.name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text('${widget.section.rooms.length} غرفة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
          ),
          child: Text(
            _flagEmojiForSectionName(widget.section.name),
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ],
    ),
  );

  String _flagEmojiForSectionName(String name) {
    // Simple mapping - you can expand this as needed
    final lower = name.toLowerCase();
    if (lower.contains('الاردن') || lower.contains('أردن')) return '🇯🇴';
    if (lower.contains('مصر')) return '🇪🇬';
    if (lower.contains('السعودية') || lower.contains('سعودية')) return '🇸🇦';
    if (lower.contains('الامارات') || lower.contains('إمارات')) return '🇦🇪';
    if (lower.contains('الكويت')) return '🇰🇼';
    if (lower.contains('قطر')) return '🇶🇦';
    if (lower.contains('البحرين')) return '🇧🇭';
    if (lower.contains('عمان') || lower.contains('سلطنة')) return '🇴🇲';
    if (lower.contains('العراق')) return '🇮🇶';
    if (lower.contains('سوريا') || lower.contains('سورية')) return '🇸🇾';
    if (lower.contains('لبنان')) return '🇱🇧';
    if (lower.contains('فلسطين')) return '🇵🇸';
    if (lower.contains('المغرب')) return '🇲🇦';
    if (lower.contains('الجزائر')) return '🇩🇿';
    if (lower.contains('تونس')) return '🇹🇳';
    if (lower.contains('ليبيا')) return '🇱🇾';
    if (lower.contains('السودان')) return '🇸🇩';
    if (lower.contains('ال Yemen') || lower.contains('اليمن')) return '🇾🇪';
    return '🌍';
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.meeting_room_outlined,
          size: 64,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 16),
        Text('لا توجد غرف في هذا القسم',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildRoomsList() => ListView.builder(
    padding: const EdgeInsets.all(10),
    itemCount: widget.section.rooms.length,
    itemBuilder: (_, i) {
      final room = widget.section.rooms[i];
      return _buildRoomCard(room);
    },
  );

  Widget _buildRoomCard(ChatRoom room) {
    final online = _onlineInRoom(room);
    final isFav = _favorites.contains(room.id);

    return GestureDetector(
      onTap: () => _onRoomTap(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF4ADE80), width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipOval(
                child: room.avatar != null
                  ? Image.network(room.avatar!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_outline,
                        color: Colors.grey,
                        size: 26,
                      ),
                    )
                  : const Icon(Icons.person_outline,
                    color: Colors.grey,
                    size: 26,
                  ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(room.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildEqualizerBars(),
                          const SizedBox(width: 6),
                          Text('$online مستخدم',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      if (room.description != null && room.description!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFB2DFDB)),
                          ),
                          child: Text(
                            room.description!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00796B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await FavoritesStore.toggle(room.id);
                final l = await FavoritesStore.load();
                if (mounted) setState(() { _favorites.clear(); _favorites.addAll(l); });
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEqualizerBars() => SizedBox(
    width: 10,
    height: 10,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _animateBar(1.0),
        const SizedBox(width: 1.5),
        _animateBar(0.8),
        const SizedBox(width: 1.5),
        _animateBar(0.6),
      ],
    ),
  );

  Widget _animateBar(double heightFactor) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    width: 2.5,
    height: 10 * heightFactor,
    decoration: BoxDecoration(
      color: Colors.grey.shade400,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
