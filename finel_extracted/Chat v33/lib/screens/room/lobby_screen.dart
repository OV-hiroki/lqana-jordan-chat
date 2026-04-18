// lib/screens/lobby_screen.dart
// واجهة مطابقة لمرجع src/img: شريط أخبار، بطاقات دول/أقسام، فيروزي، مفضلة، بحث، عالم
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/favorites_store.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import '../utils/country_style.dart';
import 'chat_screen.dart';
import 'inbox_screen.dart';
import 'login_modal.dart';
import 'settings_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _svc = FirebaseService();

  List<RoomSection> _sections = [];
  List<ChatUser> _onlineUsers = [];
  ChatUser? _me;
  Map<String, dynamic> _ticker = {'text': 'أهلاً بكم في الزائرين القانا الاردن صوتي أكبر تجمع عربي', 'isVisible': true};

  int _tab = 0;
  bool _searching = false;
  String _q = '';
  final _searchCtrl = TextEditingController();
  final List<String> _favorites = [];
  StreamSubscription<List<Map<String, dynamic>>>? _inboxUnreadSub;
  int _inboxUnread = 0;

  /// توسيع قسم لعرض الغرف داخله (مثل السهم في الصور)
  String? _expandedSectionId;
  int _goldSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    FavoritesStore.load().then((l) {
      if (mounted) setState(() => _favorites..clear()..addAll(l));
    });
    _svc.sectionsStream().listen((s) {
      if (!mounted) return;
      setState(() {
        _sections = s;
        if (_goldSectionIndex >= _sections.length) _goldSectionIndex = 0;
        if (_expandedSectionId != null && !s.any((e) => e.id == _expandedSectionId)) {
          _expandedSectionId = null;
        }
      });
    });
    _svc.allOnlineUsersStream().listen((u) { if (mounted) setState(() => _onlineUsers = u); });
    _svc.sysConfigStream('ticker_config').listen((d) { if (mounted && d.isNotEmpty) setState(() => _ticker = d); });
  }

  void _bindInboxUnread(ChatUser me) {
    _inboxUnreadSub?.cancel();
    _inboxUnreadSub = _svc.inboxStream(me.id).listen((rows) {
      var n = 0;
      for (final r in rows) {
        if (dmThreadIsUnread(Map<String, dynamic>.from(r), me.id)) n++;
      }
      if (mounted) setState(() => _inboxUnread = n);
    });
  }

  @override
  void dispose() {
    _inboxUnreadSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _totalRooms => _sections.fold(0, (s, sec) => s + sec.rooms.length);

  int _onlineInSection(RoomSection sec) {
    var n = 0;
    for (final r in sec.rooms) {
      n += _onlineUsers.where((u) => u.roomId == int.tryParse(r.id)).length;
    }
    return n;
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
          _bindInboxUnread(user);
          _enterRoom(room);
        },
      ),
    );
  }

  void _showMainMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.black54),
                      ),
                    ),
                    const Expanded(
                      child: Text('القائمة الرئيسية',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 34),
                  ],
                ),
              ),
              const Divider(height: 1),
              _menuItem(Icons.mail_outline, 'الرسائل الخاصة', () {
                Navigator.pop(dialogCtx);
                if (_me == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ادخل غرفة وسجّل دخولاً أولاً', style: TextStyle(fontFamily: 'Cairo'))),
                  );
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => InboxScreen(me: _me!)));
              }, badge: _inboxUnread),
              const Divider(height: 1),
              _menuItem(Icons.settings_outlined, 'الإعدادات', () {
                Navigator.pop(dialogCtx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
              const Divider(height: 1),
              _menuItem(Icons.headphones_outlined, 'غرفة المبيعات', () { Navigator.pop(dialogCtx); }),
              const Divider(height: 1),
              _menuItem(Icons.shopping_cart_outlined, 'شراء خدمة', () { Navigator.pop(dialogCtx); }),
              const Divider(height: 1),
              _menuItem(Icons.info_outline, 'عن البرنامج (قريباً)', () { Navigator.pop(dialogCtx); }, dim: true),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {bool dim = false, int badge = 0}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      trailing: Icon(icon, color: dim ? Colors.grey.shade400 : Colors.black54, size: 22),
      title: Row(
        children: [
          if (badge > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          Expanded(
            child: Text(label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 15,
                color: dim ? Colors.grey.shade400 : Colors.black87,
              )),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopTicker(),
          if (_tab == 2 || _searching) _buildSearchBar() else _buildMainBody(),
          _buildStatusBar(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildTopTicker() {
    final text = '${_ticker['text'] ?? ''} لقانا الأردن شات - أكبر تجمع عربي صوتي';
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  text,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showMainMenu,
            child: Container(
              width: 50,
              height: 44,
              margin: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _menuBarLine(), const SizedBox(height: 4), _menuBarLine(), const SizedBox(height: 4), _menuBarLine(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBarLine() => Container(
    width: 20, height: 2.5,
    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(2)),
  );

  Widget _buildSearchBar() {
    return Expanded(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() { _tab = 0; _searching = false; _q = ''; _searchCtrl.clear(); }),
                  child: const Icon(Icons.close, color: Colors.black45, size: 22),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textDirection: TextDirection.rtl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _q = v),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم الغرفة...',
                      hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _q.isEmpty
              ? Container(
                  color: AppColors.lobbyListTeal,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, color: Colors.white.withValues(alpha: 0.35), size: 72),
                        const SizedBox(height: 14),
                        Text('اكتب اسم الغرفة للبحث',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              : _buildRoomsList(_sections),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBody() {
    return Expanded(
      child: _tab == 1
        ? _buildFavorites()
        : _tab == 3
          ? _buildWorldLocked()
          : (_tab == 0 && !_searching)
            ? _buildCountrySections()
            : _buildRoomsList(_sections),
    );
  }

  Widget _buildWorldLocked() {
    return Container(
      color: AppColors.lobbyListTeal,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 56, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 12),
            Icon(Icons.lock_outline, size: 32, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text('العالم — قريباً',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.95))),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySections() {
    if (_sections.isEmpty) {
      return Container(
        color: AppColors.lobbyListTeal,
        child: const Center(
          child: Text('جاري تحميل الأقسام…', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        ),
      );
    }
    return Container(
      color: AppColors.lobbyListTeal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        itemCount: _sections.length,
        itemBuilder: (context, i) {
          final sec = _sections[i];
          final selected = i == _goldSectionIndex;
          final expanded = _expandedSectionId == sec.id;
          final online = _onlineInSection(sec);
          final roomsCount = sec.rooms.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _goldSectionIndex = i;
                      _expandedSectionId = expanded ? null : sec.id;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.countrySelected : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          AnimatedRotation(
                            turns: expanded ? 0.25 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.black54,
                              size: 26,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(sec.name,
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('$online مستخدم',
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.bar_chart, size: 15, color: Colors.grey.shade600),
                                    const SizedBox(width: 14),
                                    Text('$roomsCount غرفة',
                                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.chat_bubble_outline, size: 15, color: Colors.grey.shade600),
                                  ],
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
                            child: Text(flagEmojiForSectionName(sec.name), style: const TextStyle(fontSize: 28)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                    child: sec.rooms.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('لا توجد غرف في هذا القسم',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.black54)),
                        )
                      : Column(
                          children: sec.rooms.map((r) => _roomTileInSection(r)).toList(),
                        ),
                  ),
                  crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roomTileInSection(ChatRoom room) {
    final online = _onlineUsers.where((u) => u.roomId == int.tryParse(room.id)).length;
    final isFav = _favorites.contains(room.id);
    return GestureDetector(
      onTap: () => _onRoomTap(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('دخول', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
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
                child: Icon(isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber.shade700, size: 24),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(room.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$online / ${room.maxCapacity}',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                          color: online > 0 ? AppColors.teal : Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.people_alt_outlined, size: 14,
                        color: online > 0 ? AppColors.teal : Colors.grey.shade400),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: room.avatar != null
                ? Image.network(room.avatar!, width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44, height: 44, color: Colors.grey.shade200,
                      child: const Icon(Icons.meeting_room_outlined, color: Colors.grey, size: 24)))
                : Container(width: 44, height: 44, color: Colors.grey.shade100,
                    child: const Icon(Icons.meeting_room_outlined, color: Colors.grey, size: 24)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList(List<RoomSection> sections) {
    final allRooms = <ChatRoom>[];
    for (final s in sections) allRooms.addAll(s.rooms);

    final filtered = _q.isEmpty
      ? allRooms
      : allRooms.where((r) => r.name.contains(_q)).toList();

    if (filtered.isEmpty) {
      return Container(
        color: AppColors.lobbyListTeal,
        child: const Center(
          child: Text('لا توجد غرف', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.white)),
        ),
      );
    }

    return Container(
      color: AppColors.lobbyListTeal,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _buildRoomCard(filtered[i]),
      ),
    );
  }

  Widget _buildRoomCard(ChatRoom room) {
    final online = _onlineUsers.where((u) => u.roomId == int.tryParse(room.id)).length;
    final isFav = _favorites.contains(room.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(left: 4, right: 10, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: Colors.amber.shade700, size: 26),
            onPressed: () async {
              await FavoritesStore.toggle(room.id);
              final l = await FavoritesStore.load();
              if (mounted) setState(() { _favorites.clear(); _favorites.addAll(l); });
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onRoomTap(room),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(room.name,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$online مستخدم',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(width: 6),
                            Icon(Icons.bar_chart, size: 16, color: Colors.grey.shade500),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: room.avatar != null
                      ? ClipOval(child: Image.network(room.avatar!, fit: BoxFit.cover))
                      : const Icon(Icons.person_outline, color: Colors.grey, size: 26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavorites() {
    if (_favorites.isEmpty) {
      return Container(
        color: AppColors.lobbyListTeal,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 56, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(height: 14),
              Text('لا توجد غرف مفضلة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    final favRooms = _sections
      .expand((s) => s.rooms)
      .where((r) => _favorites.contains(r.id))
      .toList();

    return Container(
      color: AppColors.lobbyListTeal,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: favRooms.length,
        itemBuilder: (_, i) {
          final room = favRooms[i];
          final online = _onlineUsers.where((u) => u.roomId == int.tryParse(room.id)).length;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFE082)),
                  child: const Center(child: Text('⭐', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onRoomTap(room),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(room.name,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w800)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$online/${room.maxCapacity}',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(width: 4),
                            Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 22),
                  onPressed: () async {
                    await FavoritesStore.toggle(room.id);
                    final l = await FavoritesStore.load();
                    if (mounted) setState(() { _favorites.clear(); _favorites.addAll(l); });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$_totalRooms غرفة',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal)),
          const SizedBox(width: 6),
          const Icon(Icons.chat_bubble_outline, size: 17, color: AppColors.teal),
          const SizedBox(width: 22),
          Text('${_onlineUsers.length} مستخدم',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal)),
          const SizedBox(width: 6),
          const Icon(Icons.bar_chart, size: 17, color: AppColors.teal),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: AppColors.teal,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 6,
        top: 6,
      ),
      child: Row(
        children: [
          _navItem('الغرف', Icons.home_outlined, Icons.home, 0),
          _navItem('المفضلة', Icons.favorite_border, Icons.favorite, 1),
          _navItem('بحث', Icons.search, Icons.search, 2),
          _navItem('', Icons.public, Icons.public, 3, hasLock: true),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, IconData activeIcon, int idx, {bool hasLock = false}) {
    final active = _tab == idx;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (idx == 2) {
            setState(() { _tab = 2; _searching = true; });
          } else if (idx == 1) {
            FavoritesStore.load().then((l) {
              if (mounted) setState(() { _favorites.clear(); _favorites.addAll(l); _tab = 1; _searching = false; });
            });
          } else {
            setState(() { _tab = idx; _searching = false; });
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon,
                  color: active ? Colors.white : Colors.white.withValues(alpha: 0.72),
                  size: 26),
                if (hasLock)
                  const Positioned(
                    bottom: -3,
                    right: -5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.lock, size: 9, color: AppColors.teal),
                      ),
                    ),
                  ),
              ],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(label, style: TextStyle(
                fontFamily: 'Cairo', fontSize: 11,
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.72),
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              )),
            ],
          ],
        ),
      ),
    );
  }
}
