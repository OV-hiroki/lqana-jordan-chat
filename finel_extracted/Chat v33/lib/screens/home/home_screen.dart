// ============================================================
//  Home Screen — Lgana Style (مطابق للصور 100%)
//  Header بنفسجي/وردي + logo lgana + تصنيف بالدول + قائمة الغرف
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../favorites/favorites_screen.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../auth/join_gate_sheet.dart';
import 'create_room_sheet.dart';
import 'support_chat_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // null = show country grid, non-null = show rooms of that country
  String? _selectedCountry;

  // استخدام الألوان الوردية والبيضاء الموحدة
  static const _headerColor = Color(0xFFE91E63); // وردي أساسي
  static const _purple      = Color(0xFFE91E63);
  static const _pinkLight   = Color(0xFFF48FB1);

  @override
  void dispose() {
    super.dispose();
  }

  void _openCreateRoom() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (_) => CreateRoomSheet(
        onCreated: (room) => context.push('/room/${room.id}', extra: true),
      ),
    );
  }

  void _handleRoomJoin(RoomModel room) {
    final authProvider = context.read<AuthProvider>();
    final isGuest = authProvider.isGuest;

    // ✅ FIX: المستخدم المسجل يدخل الغرفة مباشرة
    if (!isGuest) {
      context.push('/room/${room.id}');
      return;
    }

    // ✅ FIX: الزائر يرى JoinGateSheet للاختيار بين دخول كزائر أو تسجيل
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JoinGateSheet(
        room: room,
        onJoined: () {
          // ✅ بعد الدخول كزائر — ادخل الغرفة مباشرة
          context.push('/room/${room.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isGuest = context.watch<AuthProvider>().isGuest;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Column(children: [
          // ── Header ────────────────────────────────────────
          _buildHeader(profile, isGuest, isAdmin),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: _selectedCountry == null
                ? _buildCountryList()
                : _buildRoomsList(),
          ),
        ]),
        floatingActionButton: isAdmin ? FloatingActionButton(
          heroTag: 'create',
          backgroundColor: _purple,
          onPressed: _openCreateRoom,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ) : FloatingActionButton(
          heroTag: 'support',
          mini: true,
          backgroundColor: AppColors.success,
          onPressed: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const SupportChatSheet()),
          child: const Icon(Icons.headset_mic, color: Colors.white),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  HEADER — Lgana style (وردي/بنفسجي داكن)
  // ══════════════════════════════════════════════════════
  Widget _buildHeader(profile, bool isGuest, bool isAdmin) {
    return Container(
      color: _headerColor,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // Logo row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              // Back arrow (if inside a country)
              if (_selectedCountry != null)
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedCountry = null;
                  }),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  ),
                ),

              // Login / avatar (right side in RTL = leading)
              GestureDetector(
                onTap: () => isGuest ? context.push('/login') : context.push('/profile'),
                child: Row(children: [
                  if (isGuest) ...[
                    const Icon(Icons.person_outline, color: Colors.white70, size: 20),
                    const SizedBox(width: 4),
                    const Text('دخول',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
                  ] else ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white30,
                      backgroundImage: (profile?.photoURL?.isNotEmpty ?? false)
                          ? NetworkImage(profile!.photoURL!) : null,
                      child: (profile?.photoURL?.isEmpty ?? true)
                          ? const Icon(Icons.person, color: Colors.white, size: 16) : null,
                    ),
                    const SizedBox(width: 6),
                    Text(profile?.displayName ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Cairo')),
                  ],
                ]),
              ),

              const Spacer(),

              // App logo — text style
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App name
                  const Text('Jordan Audio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                    )),
                  const Text('Forum',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    )),
                ],
              ),
            ]),
          ),


          // Country title row (when inside a country)
          if (_selectedCountry != null) ...[
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ClipOval(
                    child: Text(
                      _getCountryFlag(_selectedCountry!),
                      style: const TextStyle(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _getCountryLabel(_selectedCountry!),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold,
                    fontSize: 14, fontFamily: 'Cairo'),
                )),
                // Reload
                GestureDetector(
                  onTap: () => setState(() {}),
                  child: const Icon(Icons.refresh, color: Colors.white70, size: 18)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  COUNTRY LIST  (main view — matches Lgana design)
  // ══════════════════════════════════════════════════════
  Widget _buildCountryList() {
    return StreamBuilder<List<RoomModel>>(
      stream: FirestoreService.instance.listenToRooms(),
      builder: (context, snap) {
        final allRooms = snap.data ?? [];

        // Count rooms & users per country
        Map<String, int> roomCount = {};
        Map<String, int> userCount = {};
        int totalRooms = 0;
        int totalUsers = 0;
        for (final r in allRooms) {
          if (!r.isLive) continue;
          final c = r.category;
          roomCount[c] = (roomCount[c] ?? 0) + 1;
          userCount[c] = (userCount[c] ?? 0) + r.speakersCount + r.listenersCount;
          totalRooms++;
          totalUsers += r.speakersCount + r.listenersCount;
        }

        return Column(
          children: [
            // Country rows
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: AppConstants.countries.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 0, endIndent: 0),
                itemBuilder: (_, i) {
                  final c = AppConstants.countries[i];
                  final rooms = roomCount[c['id']] ?? 0;
                  final users = userCount[c['id']] ?? 0;
                  return _CountryRow(
                    flag:   c['flag']!,
                    label:  c['label']!,
                    rooms:  rooms,
                    users:  users,
                    onTap: () => setState(() => _selectedCountry = c['id']),
                  );
                },
              ),
            ),
            // ── Totals footer ────────────────────────────
            Container(
              color: AppColors.bgSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('$totalUsers مستخدم',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('$totalRooms غرفة',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  //  ROOMS LIST  (when country selected)
  // ══════════════════════════════════════════════════════
  Widget _buildRoomsList() {
    return StreamBuilder<List<RoomModel>>(
      stream: FirestoreService.instance.listenToRooms(
        category: _selectedCountry,
      ),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9C27B0)));
        }
        var rooms = snap.data ?? [];
        rooms = rooms.where((r) => r.isLive).toList();
        if (rooms.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎙️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('لا توجد غرف في هذا القسم',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 15,
                    color: Colors.grey)),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => setState(() {}),
                child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ));
        }
        return RefreshIndicator(
          color: _purple,
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1),
            itemBuilder: (_, i) => _RoomRow(
              room: rooms[i],
              onTap: () => _handleRoomJoin(rooms[i]),
            ),
          ),
        );
      },
    );
  }

  // Helpers
  String _getCountryFlag(String id) =>
      AppConstants.countries.firstWhere(
        (c) => c['id'] == id, orElse: () => {'flag': '🌍'})['flag']!;

  String _getCountryLabel(String id) =>
      AppConstants.countries.firstWhere(
        (c) => c['id'] == id, orElse: () => {'label': 'غرف'})['label']!;
}

// ══════════════════════════════════════════════════════════
//  COUNTRY ROW  — يطابق تصميم Lgana تماماً
//  [صورة العلم] | اسم الدولة | عدد المستخدمين + عدد الغرف | سهم
// ══════════════════════════════════════════════════════════
class _CountryRow extends StatelessWidget {
  final String flag;
  final String label;
  final int rooms;
  final int users;
  final VoidCallback onTap;

  const _CountryRow({
    required this.flag, required this.label,
    required this.rooms, required this.users,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          // Circular flag icon
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withValues(alpha: 0.1),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
            ),
            child: ClipOval(
              child: Text(
                flag,
                style: const TextStyle(fontSize: 32),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Country name
          Expanded(
            child: Text(label,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 16,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 10),

          // Stats column (aligned right)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$users',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Cairo')),
              const SizedBox(width: 3),
              const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$rooms',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Cairo')),
              const SizedBox(width: 3),
              const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.textSecondary),
            ]),
          ]),
          const SizedBox(width: 6),

          // Chevron
          const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 20),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  ROOM ROW  (in rooms list — Lgana style)
// ══════════════════════════════════════════════════════════
class _RoomRow extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onTap;
  const _RoomRow({required this.room, required this.onTap});

  @override
  State<_RoomRow> createState() => _RoomRowState();
}

class _RoomRowState extends State<_RoomRow> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final uid = context.read<AuthProvider>().profile?.uid;
    if (uid == null) return;

    final isFav = await FirestoreService.instance.isFavorite(uid, widget.room.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = context.read<AuthProvider>().profile?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لإضافة المفضلات',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await FirestoreService.instance.addFavorite(uid, widget.room.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة "${widget.room.title}" للمفضلة ⭐',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      await FirestoreService.instance.removeFavorite(uid, widget.room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
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
            child: (widget.room.coverImage?.isNotEmpty ?? false)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.room.coverImage!,
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
              // Title
              Text(widget.room.title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: Color(0xFF212121), fontFamily: 'Cairo')),
              const SizedBox(height: 3),
              // Host + participants
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(widget.room.hostName,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo')),
                const SizedBox(width: 8),
                const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text('${widget.room.speakersCount + widget.room.listenersCount}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Cairo')),
              ]),
            ]),
          ),
          const SizedBox(width: 8),

          // LIVE badge
          if (widget.room.isLive)
            Container(
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
          const SizedBox(width: 6),

          // Favorite star button
          GestureDetector(
            onTap: _toggleFavorite,
            child: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
        ]),
      ),
    );
  }
}
