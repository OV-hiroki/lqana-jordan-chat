// lib/screens/chat_screen.dart
// ✅ مطابق لـ index.html بالكامل: قائمة الأعضاء، طابور المايك، خلفية الغرفة، أدوات الإدارة
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import '../services/cloudinary_service.dart';
import '../services/favorites_store.dart';
import '../services/firebase_service.dart';
import '../services/push_messaging.dart';
import '../theme.dart';
import 'profile_screen.dart';
import 'games_screen.dart';
import 'status_picker.dart';
import 'inbox_screen.dart';

const String _agoraAppId = '98ff0070534d4fd2a6790c31d1d2b140';

// ─── ألوان الرتب (مطابق للموقع) ────────────────────────────────────────────
Color getRoleColor(UserRole role) {
  switch (role) {
    case UserRole.master:     return const Color(0xFFcc0000);
    case UserRole.superAdmin: return const Color(0xFF008000);
    case UserRole.admin:      return const Color(0xFF0000ff);
    case UserRole.member:     return const Color(0xFF800080);
    case UserRole.root:       return const Color(0xFFd97706);
    case UserRole.sales:      return const Color(0xFF7c3aed);
    default:                  return const Color(0xFF4b5563);
  }
}

// ─── لون قلب المستوى (مطابق للموقع) ───────────────────────────────────────
Color getHeartColor(int level) {
  if (level <= 5)  return const Color(0xFFef4444);
  if (level <= 10) return const Color(0xFF3b82f6);
  if (level <= 15) return const Color(0xFF22c55e);
  if (level <= 20) return const Color(0xFFeab308);
  if (level <= 25) return const Color(0xFFa855f7);
  return const Color(0xFF06b6d4);
}

class ChatScreen extends StatefulWidget {
  final ChatRoom room;
  final ChatUser me;
  final Function(ChatUser)? onMeUpdated;
  const ChatScreen({super.key, required this.room, required this.me, this.onMeUpdated});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _svc = FirebaseService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();

  late ChatUser _me;
  List<ChatMsg> _msgs = [];
  List<ChatUser> _members = [];
  RoomState _rs = const RoomState();
  StreamSubscription? _msgSub, _memberSub, _stateSub;

  bool _showEmoji = false;
  bool _sending = false;
  bool _uploadingImage = false;
  ChatMsg? _replyTo;

  // شاشة الأعضاء (سلايدر)
  bool _showMemberList = false;
  late AnimationController _memberListAnimCtrl;
  late Animation<Offset> _memberListAnim;

  // أدوات الإدارة
  bool _showAdminTools = false;

  // Agora
  RtcEngine? _engine;
  bool _micOn = false;
  bool _inChannel = false;
  bool _audioMuted = false;

  // Timer
  int _elapsedSec = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _me = widget.me;

    // انيميشن قائمة الأعضاء
    _memberListAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _memberListAnim = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _memberListAnimCtrl, curve: Curves.easeOut));

    _initAgora();
    _subscribe();
    PushMessagingService.instance.syncTokenToProfile(_me.id);
    _sendSystem('دخل ${_me.name} 🌹');
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSec++);
    });
  }

  // ─── Agora Init ───────────────────────────────────────────────────────────
  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: _agoraAppId));
    await _engine!.enableAudio();
    await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, _) {
        if (mounted) setState(() => _inChannel = true);
      },
      onLeaveChannel: (conn, _) {
        if (mounted) setState(() { _inChannel = false; _micOn = false; });
      },
    ));
  }

  Future<void> _joinAgoraChannel() async {
    await _engine?.joinChannel(
      token: '',
      channelId: 'room_${widget.room.id}',
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> _toggleMic() async {
    if (!_inChannel) await _joinAgoraChannel();
    setState(() => _micOn = !_micOn);
    await _engine?.muteLocalAudioStream(!_micOn);
    await _svc.updateActiveMic(widget.room.id, _micOn ? _me.id : null);
  }

  // ─── Subscribe ────────────────────────────────────────────────────────────
  void _subscribe() {
    _msgSub = _svc.msgsStream(widget.room.id).listen((m) {
      if (!mounted) return;
      setState(() => _msgs = m.where((msg) => msg.timestamp >= _rs.clearedAt).toList());
      _scrollBottom();
    });
    _memberSub = _svc.membersStream(widget.room.id).listen((m) {
      if (mounted) setState(() => _members = _sortMembers(m));
    });
    _stateSub = _svc.roomStateStream(widget.room.id).listen((s) {
      if (mounted) setState(() => _rs = s);
    });
  }

  // ترتيب الأعضاء (مطابق للموقع: المالك أولاً ثم SUPER_ADMIN ثم حسب الرتبة)
  List<ChatUser> _sortMembers(List<ChatUser> members) {
    final sorted = [...members];
    sorted.sort((a, b) {
      int rankA = _getUserRank(a);
      int rankB = _getUserRank(b);
      return rankB - rankA;
    });
    return sorted;
  }

  int _getUserRank(ChatUser u) {
    if (u.name == widget.room.name) return 10; // مالك الغرفة
    switch (u.role) {
      case UserRole.root:       return 9;
      case UserRole.master:     return 8;
      case UserRole.superAdmin: return 7;
      case UserRole.admin:      return 6;
      case UserRole.member:     return 5;
      case UserRole.sales:      return 4;
      default:                  return 1;
    }
  }

  bool get _isRoomAdmin =>
    _me.role == UserRole.root ||
    _me.role == UserRole.master ||
    _me.role == UserRole.superAdmin ||
    _me.role == UserRole.admin;

  @override
  void dispose() {
    _msgSub?.cancel(); _memberSub?.cancel(); _stateSub?.cancel();
    _timer?.cancel();
    _memberListAnimCtrl.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    _msgCtrl.dispose(); _scroll.dispose();
    _sendSystem('غادر ${_me.name} 👋');
    _svc.leaveRoom(_me.id);
    super.dispose();
  }

  Future<void> _sendSystem(String text) async {
    await _svc.sendMsg(widget.room.id, {
      'senderId': 'system', 'senderName': 'النظام', 'isSystem': true,
      'text': text, 'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending || _uploadingImage) return;
    if (_rs.chatLocked && _me.role.weight < UserRole.admin.weight) {
      _toast('الشات مغلق حالياً 🔒'); return;
    }
    setState(() => _sending = true);
    try {
      final d = <String, dynamic>{
        'senderId': _me.id, 'senderName': _me.name,
        'senderAvatar': _me.avatar, 'senderRole': _me.role.fsValue,
        'senderNameColor': _me.nameColor, 'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      if (_replyTo != null) {
        d['replyToId'] = _replyTo!.id;
        d['replyToName'] = _replyTo!.senderName;
        d['replyToText'] = _replyTo!.text;
      }
      await _svc.sendMsg(widget.room.id, d);
      _msgCtrl.clear();
      setState(() => _replyTo = null);
    } catch (_) { _toast('فشل الإرسال'); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    if (_rs.imagesLocked && _me.role.weight < UserRole.admin.weight) {
      _toast('إرسال الصور مغلق حالياً 🔒'); return;
    }
    if (_uploadingImage || _sending) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await CloudinaryService.instance.uploadImage(x);
      await _svc.sendMsg(widget.room.id, {
        'senderId': _me.id, 'senderName': _me.name, 'senderAvatar': _me.avatar,
        'senderRole': _me.role.fsValue, 'senderNameColor': _me.nameColor,
        'text': '', 'imageUrl': url, 'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) { _toast('فشل رفع الصورة'); }
    finally { if (mounted) setState(() => _uploadingImage = false); }
  }

  void _toast(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isSuccess ? Colors.green.shade600 : AppColors.teal,
        duration: const Duration(seconds: 2),
      )
    );
  }

  String get _timerStr {
    if (!_inChannel && !_micOn) return 'Mic Free';
    final h = _elapsedSec ~/ 3600;
    final m = (_elapsedSec % 3600) ~/ 60;
    final s = _elapsedSec % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}'
                 : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  // ─── Toggle Member List ──────────────────────────────────────────────────
  void _toggleMemberList() {
    setState(() => _showMemberList = !_showMemberList);
    if (_showMemberList) {
      _memberListAnimCtrl.forward();
    } else {
      _memberListAnimCtrl.reverse();
    }
  }

  // ─── Room menu ────────────────────────────────────────────────────────────
  void _showRoomMenu() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close, size: 16, color: Colors.black54),
                        ),
                      ),
                      const Expanded(
                        child: Text('خيارات الغرفة',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _roomMenuItem(Icons.person_outline, 'ملفي الشخصي', AppColors.teal, () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: _me, isSelf: true, onUpdate: (u) { setState(() => _me = u); })));
                }),
                const Divider(height: 1),
                _roomMenuItem(Icons.star_border, 'إضافة / إزالة من المفضلة', AppColors.teal, () async {
                  Navigator.pop(dialogCtx);
                  final nowFav = await FavoritesStore.toggle(widget.room.id);
                  _toast(nowFav ? 'أضيفت الغرفة للمفضلة ⭐' : 'أُزيلت من المفضلة');
                }),
                const Divider(height: 1),
                _roomMenuItem(Icons.monitor_heart_outlined, 'تغيير الحالة', AppColors.teal, () {
                  Navigator.pop(dialogCtx);
                  showDialog(context: context, builder: (_) => StatusPicker(
                    current: _me.status,
                    onSelect: (s) async {
                      Navigator.pop(context);
                      await _svc.updateUserField(_me.id, 'status', s.fsValue);
                      setState(() => _me = _me.copyWith(status: s));
                    },
                  ));
                }),
                const Divider(height: 1),
                _roomMenuItem(Icons.mail_outline, 'الرسائل الخاصة', AppColors.teal, () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InboxScreen(me: _me)));
                }),
                if (_isRoomAdmin) ...[
                  const Divider(height: 1),
                  _roomMenuItem(Icons.admin_panel_settings_outlined, 'أدوات الإدارة', Colors.orange, () {
                    Navigator.pop(dialogCtx);
                    setState(() => _showAdminTools = true);
                  }),
                ],
                const Divider(height: 1),
                _roomMenuItem(Icons.delete_outline, 'مسح النص (عندي)', AppColors.teal, () {
                  setState(() => _msgs = []);
                  Navigator.pop(dialogCtx);
                }),
                const Divider(height: 1),
                _roomMenuItem(Icons.error_outline, 'إرسال تبليغ', Colors.orange, () { Navigator.pop(dialogCtx); }),
                const Divider(height: 1),
                _roomMenuItem(Icons.arrow_back, 'رجوع للأقسام (بدون خروج)', AppColors.teal, () {
                  Navigator.pop(dialogCtx);
                  Navigator.pop(context);
                }),
                const Divider(height: 1),
                _roomMenuItem(Icons.logout, 'خروج نهائي من الغرفة', Colors.red, () async {
                  Navigator.pop(dialogCtx);
                  await _svc.leaveRoom(_me.id);
                  if (mounted) Navigator.pop(context);
                }, isRed: true),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomMenuItem(IconData icon, String label, Color color, VoidCallback onTap, {bool isRed = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      trailing: Icon(icon, color: color, size: 22),
      title: Text(label,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Cairo', fontSize: 14,
          color: isRed ? Colors.red : Colors.black87,
          fontWeight: isRed ? FontWeight.w700 : FontWeight.normal,
        )),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // تطبيق خلفية الغرفة إذا وجدت
    Widget content = Column(
      children: [
        _buildTopBar(),
        if (_rs.pinnedMsg?.isNotEmpty == true) _buildPinned(),
        Expanded(child: _buildMessages()),
        if (_showEmoji) _buildEmojiGrid(),
        if (_replyTo != null) _buildReplyBar(),
        _buildInputBar(),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // خلفية الغرفة (مطابق للموقع)
          if (_rs.background != null)
            Positioned.fill(
              child: Image.network(_rs.background!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.white)),
            ),
          if (_rs.background != null)
            Positioned.fill(child: Container(color: Colors.white.withOpacity(0.85))),
          // المحتوى الرئيسي
          SafeArea(child: content),
          // قائمة الأعضاء (سلايدر من اليسار — مثل الموقع)
          if (_showMemberList)
            GestureDetector(
              onTap: _toggleMemberList,
              child: Container(color: Colors.black45),
            ),
          if (_showMemberList)
            Positioned(
              top: 0, bottom: 0, right: 0,
              width: MediaQuery.of(context).size.width * 0.72,
              child: SlideTransition(
                position: _memberListAnim,
                child: _buildMemberListPanel(),
              ),
            ),
          // أدوات الإدارة (bottom sheet)
          if (_showAdminTools)
            _buildAdminToolsOverlay(),
        ],
      ),
    );
  }

  // ─── Top bar (مطابق للموقع) ───────────────────────────────────────────────
  Widget _buildTopBar() {
    final activeMicUser = _rs.activeMic != null
      ? _members.firstWhere((m) => m.id == _rs.activeMic,
          orElse: () => ChatUser(id: '', name: _rs.activeMic!, joinedAt: 0))
      : null;

    return Container(
      color: AppColors.chatTopBar,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 10, left: 8, right: 8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Hamburger (أزرق) — يفتح قائمة الغرفة
              GestureDetector(
                onTap: _showRoomMenu,
                child: Container(
                  width: 46, height: 40,
                  decoration: BoxDecoration(color: AppColors.btnMenu, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_topBarLine(), const SizedBox(height: 4), _topBarLine(), const SizedBox(height: 4), _topBarLine()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Chat bubble (أصفر) — يعرض قائمة الأعضاء
              GestureDetector(
                onTap: _toggleMemberList,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42, height: 40,
                      decoration: BoxDecoration(color: AppColors.btnChat, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.people_alt_outlined, color: Color(0xFF424242), size: 22),
                    ),
                    if (_members.isNotEmpty)
                      Positioned(
                        top: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('${_members.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              // Center: اسم المتحدث + مؤقت
              Expanded(
                child: Column(
                  children: [
                    Text(
                      activeMicUser?.name ?? (_inChannel ? _me.name : 'Mic Free'),
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800,
                        color: activeMicUser != null ? Colors.red : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _inChannel ? _timerStr : '--:--',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              // زر كتم الصوت
              GestureDetector(
                onTap: () {
                  setState(() => _audioMuted = !_audioMuted);
                  _engine?.muteAllRemoteAudioStreams(_audioMuted);
                },
                child: Row(
                  children: [
                    Icon(_audioMuted ? Icons.volume_off : Icons.volume_up, color: Colors.red, size: 22),
                    const SizedBox(width: 2),
                    Icon(Icons.close, color: Colors.red.withOpacity(_audioMuted ? 1.0 : 0.3), size: 14),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // عدد المتصلين
              Column(
                children: [
                  const Text('متصل', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.green)),
                  Text('${_members.length}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green)),
                ],
              ),
            ],
          ),
          // ─── صف صور الأعضاء المتواجدين (مطابق للموقع) ─────────────────
          if (_members.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMembersRow(),
          ],
          // ─── طابور المايك ───────────────────────────────────────────────
          if (_rs.micQueue.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMicQueue(),
          ],
        ],
      ),
    );
  }

  Widget _topBarLine() => Container(
    height: 2.5, width: 20, margin: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
  );

  // ─── صف صور الأعضاء (مطابق للموقع) ─────────────────────────────────────
  Widget _buildMembersRow() {
    final visible = _members.take(12).toList();
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        itemBuilder: (_, i) {
          final u = visible[i];
          final isActiveMic = _rs.activeMic == u.id;
          return GestureDetector(
            onTap: () => _showUserActionMenu(u),
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
                children: [
                  _buildUserAvatar(u, size: 36, isActiveMic: isActiveMic),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── أفاتار المستخدم مع الإطار والمستوى (مطابق للموقع) ─────────────────
  Widget _buildUserAvatar(ChatUser u, {double size = 42, bool isActiveMic = false}) {
    final heartColor = getHeartColor(u.level);
    final roleColor = getRoleColor(u.role);

    return SizedBox(
      width: size + 10,
      height: size + 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الإطار المتوهج للمتحدث
          if (isActiveMic)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.7), blurRadius: 10, spreadRadius: 3)],
                ),
              ),
            ),
          // حلقة اللون حسب الرتبة
          Container(
            width: size + 6, height: size + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: u.isVip ? const Color(0xFFfbbf24) : roleColor, width: 2),
              color: Colors.white,
            ),
            child: ClipOval(
              child: u.avatar != null
                ? Image.network(u.avatar!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultAvatar())
                : _defaultAvatar(),
            ),
          ),
          // قلب المستوى في الأسفل
          Positioned(
            bottom: 0, right: 0,
            child: _buildLevelHeart(u.level, heartColor),
          ),
          // VIP تاج
          if (u.isVip)
            Positioned(
              top: -4, left: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFFfbbf24), shape: BoxShape.circle),
                child: const Icon(Icons.star, size: 8, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: const Color(0xFFfce052),
    child: const Icon(Icons.person, color: Colors.black54),
  );

  Widget _buildLevelHeart(int level, Color color) {
    return SizedBox(
      width: 20, height: 20,
      child: Stack(
        children: [
          Icon(Icons.favorite, color: color, size: 20),
          Center(
            child: Text('$level', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── طابور المايك (مطابق للموقع) ─────────────────────────────────────────
  Widget _buildMicQueue() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('طابور المايك:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _rs.micQueue.asMap().entries.map((e) {
                  final idx = e.key + 1;
                  final uid = e.value;
                  final user = _members.firstWhere((m) => m.id == uid, orElse: () => ChatUser(id: uid, name: '؟', joinedAt: 0));
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Row(
                      children: [
                        Text('$idx.', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2),
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          backgroundColor: Colors.grey.shade300,
                          child: user.avatar == null ? const Icon(Icons.person, size: 10, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 2),
                        Text(user.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinned() {
    return Container(
      color: const Color(0xFFFFF9C4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          const Text('📌', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(_rs.pinnedMsg!,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  // ─── Messages ─────────────────────────────────────────────────────────────
  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _msgs.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _buildWelcome();
        return _buildBubble(_msgs[i - 1]);
      },
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text('✨👑✨ نورت يا ${_me.name} ✨👑✨',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Color(0xFFDAA520), fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_rs.welcomeMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 10),
          Container(height: 1.5, color: const Color(0xFFFFD700), margin: const EdgeInsets.symmetric(horizontal: 20)),
          const SizedBox(height: 8),
          // شريط المتواجدين الأفاتارات
          if (_members.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _members.length > 8 ? 8 : _members.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: _members[i].avatar != null ? NetworkImage(_members[i].avatar!) : null,
                    backgroundColor: Colors.grey.shade300,
                    child: _members[i].avatar == null ? const Icon(Icons.person, size: 14, color: Colors.grey) : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMsg msg) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
          child: Text(msg.text ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final isMine = msg.senderId == _me.id;
    final senderUser = _members.firstWhere((m) => m.id == msg.senderId,
      orElse: () => ChatUser(id: msg.senderId, name: msg.senderName, avatar: msg.senderAvatar, joinedAt: 0));

    // لون الاسم (مطابق للموقع: من roleColors)
    final nameColor = msg.senderNameColor != null
      ? _parseColor(msg.senderNameColor)
      : getRoleColor(UserRoleX.fromString(msg.senderRole));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            GestureDetector(
              onTap: () => _showUserActionMenu(senderUser),
              child: _buildUserAvatar(senderUser, size: 30),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMsgActions(msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMine ? const Color(0xFFE8FBF5) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 4 : 16),
                    bottomRight: Radius.circular(isMine ? 16 : 4),
                  ),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMine)
                      Text(msg.senderName,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w800, color: nameColor)),
                    if (msg.replyToId != null) _buildReplyPreview(msg),
                    if (msg.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(msg.imageUrl!, width: 180, fit: BoxFit.cover))
                    else
                      Text(msg.text ?? '',
                        style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 14, color: Colors.black87,
                          fontWeight: isMine ? FontWeight.normal : FontWeight.w500,
                        )),
                    Text(_fmtTime(msg.timestamp),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showUserActionMenu(_me),
              child: _buildUserAvatar(_me, size: 30),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ChatMsg msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8),
        border: const Border(right: BorderSide(color: AppColors.teal, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(msg.replyToName ?? '؟', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal)),
          Text(msg.replyToText ?? '...', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showMsgActions(ChatMsg msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️','😂','👍','😮','😢','🔥'].map((e) =>
                  GestureDetector(
                    onTap: () { Navigator.pop(context); },
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  )).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              trailing: const Icon(Icons.reply, color: AppColors.teal),
              title: const Text('رد', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
              onTap: () { Navigator.pop(context); setState(() => _replyTo = msg); },
            ),
            ListTile(
              trailing: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('نسخ', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                if (msg.text != null) Clipboard.setData(ClipboardData(text: msg.text!));
              },
            ),
            if (msg.senderId == _me.id || _me.role.weight >= UserRole.admin.weight)
              ListTile(
                trailing: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _svc.deleteMsg(widget.room.id, msg.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── قائمة الأعضاء (سلايدر) ─────────────────────────────────────────────
  Widget _buildMemberListPanel() {
    return Material(
      elevation: 20,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 12, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7ED9C3), Color(0xFF81D4FA)]),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleMemberList,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text('المتواجدون (${_members.length})',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            // القائمة
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _members.length,
                itemBuilder: (_, i) => _buildMemberTile(_members[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(ChatUser u) {
    final isActiveMic = _rs.activeMic == u.id;
    final isBanned = _rs.bannedUsers.containsKey(u.id) && (_rs.bannedUsers[u.id]?['expiry'] ?? 0) > DateTime.now().millisecondsSinceEpoch;
    final isMuted = _rs.mutedUsers.containsKey(u.id) && (_rs.mutedUsers[u.id]?['expiry'] ?? 0) > DateTime.now().millisecondsSinceEpoch;
    final roleColor = getRoleColor(u.role);

    return GestureDetector(
      onTap: () => _showUserActionMenu(u),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActiveMic ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActiveMic ? Colors.green.shade300 : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Row(
          children: [
            // أيقونات الحالة (محظور/مكتوم)
            Column(
              children: [
                if (isBanned) const Icon(Icons.block, color: Colors.red, size: 14)
                else if (isMuted) const Icon(Icons.volume_off, color: Colors.orange, size: 14)
                else if (isActiveMic) const Icon(Icons.mic, color: Colors.green, size: 14)
                else const SizedBox(width: 14),
              ],
            ),
            const SizedBox(width: 8),
            // الأفاتار
            _buildUserAvatar(u, size: 38),
            const SizedBox(width: 10),
            // الاسم والرتبة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(u.name,
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800,
                      color: roleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (u.isVip)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFfbbf24), borderRadius: BorderRadius.circular(4)),
                          child: const Text('VIP', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      Text(u.role.label,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: roleColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            // أيقونة المايك الفاضي
            if (!isActiveMic && !isBanned)
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InboxScreen(me: _me)));
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.mail_outline, size: 16, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── قائمة إجراءات المستخدم (عند النقر على الأفاتار أو العضو) ────────────
  void _showUserActionMenu(ChatUser u) {
    if (u.id == _me.id) {
      // عرض ملفي الشخصي
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProfileScreen(user: _me, isSelf: true, onUpdate: (upd) { setState(() => _me = upd); })));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header المستخدم
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildUserAvatar(u, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800, color: getRoleColor(u.role))),
                          Text('${u.role.label} • مستوى ${u.level}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                trailing: const Icon(Icons.person_outline, color: AppColors.teal),
                title: const Text('عرض الملف الشخصي', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: u, isSelf: false, onUpdate: (_) {})));
                },
              ),
              ListTile(
                trailing: const Icon(Icons.mail_outline, color: AppColors.teal),
                title: const Text('إرسال رسالة خاصة', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InboxScreen(me: _me)));
                },
              ),
              // أدوات الإدارة (فقط للمشرفين)
              if (_isRoomAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  trailing: const Icon(Icons.mic_off, color: Colors.orange),
                  title: const Text('كتم الصوت (5 دقائق)', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', color: Colors.orange)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _svc.muteUser(widget.room.id, u.id, 5);
                    _toast('تم كتم ${u.name}', isSuccess: true);
                  },
                ),
                ListTile(
                  trailing: const Icon(Icons.block, color: Colors.red),
                  title: const Text('حظر العضو', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _svc.banUser(widget.room.id, u.id, 'حظر بواسطة المشرف');
                    _toast('تم حظر ${u.name}', isSuccess: false);
                  },
                ),
                ListTile(
                  trailing: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('طرد من الغرفة', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _svc.kickUser(widget.room.id, u.id);
                    _toast('تم طرد ${u.name}');
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── أدوات الإدارة (Overlay) ──────────────────────────────────────────────
  Widget _buildAdminToolsOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showAdminTools = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    // Handle
                    Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('لوحة الإدارة', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w800))),
                          GestureDetector(
                            onTap: () => setState(() => _showAdminTools = false),
                            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.close, size: 18)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // قفل/فتح الشات
                            _adminToolRow(
                              icon: _rs.chatLocked ? Icons.lock : Icons.lock_open,
                              label: _rs.chatLocked ? 'فتح الشات' : 'قفل الشات',
                              color: _rs.chatLocked ? Colors.red : Colors.green,
                              onTap: () async {
                                await _svc.updateRoomState(widget.room.id, {'isChatLocked': !_rs.chatLocked});
                                _toast(_rs.chatLocked ? 'تم فتح الشات' : 'تم قفل الشات', isSuccess: true);
                              },
                            ),
                            const SizedBox(height: 10),
                            // قفل/فتح المايك
                            _adminToolRow(
                              icon: _rs.micLocked ? Icons.mic_off : Icons.mic,
                              label: _rs.micLocked ? 'فتح المايك' : 'قفل المايك',
                              color: _rs.micLocked ? Colors.red : Colors.green,
                              onTap: () async {
                                await _svc.updateRoomState(widget.room.id, {'isMicLocked': !_rs.micLocked});
                                _toast(_rs.micLocked ? 'تم فتح المايك' : 'تم قفل المايك', isSuccess: true);
                              },
                            ),
                            const SizedBox(height: 10),
                            // قفل/فتح الصور
                            _adminToolRow(
                              icon: _rs.imagesLocked ? Icons.image_not_supported : Icons.image,
                              label: _rs.imagesLocked ? 'فتح الصور' : 'قفل الصور',
                              color: _rs.imagesLocked ? Colors.red : Colors.green,
                              onTap: () async {
                                await _svc.updateRoomState(widget.room.id, {'isImagesLocked': !_rs.imagesLocked});
                                _toast(_rs.imagesLocked ? 'تم فتح الصور' : 'تم قفل الصور', isSuccess: true);
                              },
                            ),
                            const SizedBox(height: 10),
                            // إسقاط المايك
                            if (_rs.activeMic != null)
                              _adminToolRow(
                                icon: Icons.mic_off,
                                label: 'إسقاط المتحدث الحالي',
                                color: Colors.orange,
                                onTap: () async {
                                  await _svc.updateActiveMic(widget.room.id, null);
                                  _toast('تم إسقاط المايك', isSuccess: true);
                                },
                              ),
                            const SizedBox(height: 10),
                            // مسح الشات (للكل)
                            _adminToolRow(
                              icon: Icons.cleaning_services,
                              label: 'مسح الشات (للجميع)',
                              color: Colors.red,
                              onTap: () {
                                setState(() => _showAdminTools = false);
                                _showConfirmDialog(
                                  'مسح الشات',
                                  'هل أنت متأكد من مسح جميع رسائل الشات؟',
                                  () async {
                                    await _svc.updateRoomState(widget.room.id, {'chatClearedAt': DateTime.now().millisecondsSinceEpoch});
                                    _toast('تم مسح الشات', isSuccess: true);
                                  }
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _adminToolRow({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: color))),
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          content: Text(content, style: const TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
            TextButton(onPressed: () { Navigator.pop(context); onConfirm(); }, child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo', color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // ─── Reply bar ────────────────────────────────────────────────────────────
  Widget _buildReplyBar() {
    return Container(
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          GestureDetector(onTap: () => setState(() => _replyTo = null),
            child: const Icon(Icons.close, size: 18, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_replyTo!.senderName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal)),
              Text(_replyTo!.text ?? '...', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ],
      ),
    );
  }

  // ─── Emoji grid ───────────────────────────────────────────────────────────
  Widget _buildEmojiGrid() {
    const emojis = ['😊','😘','🥰','😍','🤣','😂','😄','😐','🤨','😏','😎','😋','😜','😩','😢','😮','🤐','😑','😕','😤','😠','🥱','😴','❤️','🔥','👍','💯','🌹','💐','😇'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _showEmoji = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => GamesScreen(room: widget.room, me: _me)));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(14)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎮', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('ألعاب الغرفة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(width: 8),
                  Text('🕹️', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
          const Align(alignment: Alignment.centerRight,
            child: Text('اختر إيموجي ✨', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey))),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            children: emojis.map((e) => GestureDetector(
              onTap: () {
                _msgCtrl.text += e;
                setState(() => _showEmoji = false);
              },
              child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Input bar (مطابق للموقع) ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      color: Colors.white.withOpacity(0.95),
      child: Row(
        children: [
          // Send button
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
              child: (_sending || _uploadingImage)
                ? const Padding(padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 6),
          // Emoji button
          GestureDetector(
            onTap: () => setState(() => _showEmoji = !_showEmoji),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Center(child: Text('😊', style: TextStyle(fontSize: 20))),
            ),
          ),
          const SizedBox(width: 6),
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _msgCtrl,
                textDirection: TextDirection.rtl,
                onTap: () => setState(() => _showEmoji = false),
                decoration: InputDecoration(
                  hintText: _rs.chatLocked && !_isRoomAdmin ? 'الشات مغلق 🔒' : 'اكتب رسالة',
                  hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                enabled: !(_rs.chatLocked && !_isRoomAdmin),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Plus button (صور)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => SafeArea(
                  child: ListTile(
                    trailing: const Icon(Icons.image_outlined, color: AppColors.teal),
                    title: const Text('إرسال صورة', textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendImage();
                    },
                  ),
                ),
              );
            },
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(color: AppColors.btnPlus, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 6),
          // Mic button
          GestureDetector(
            onTap: _toggleMic,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _micOn ? AppColors.btnMicOn : AppColors.btnMic,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_micOn ? Icons.mic : Icons.mic_off, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); } catch (_) { return null; }
  }

  String _fmtTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final h = d.hour > 12 ? d.hour - 12 : d.hour;
    final amPm = d.hour >= 12 ? 'م' : 'ص';
    return '$h:${d.minute.toString().padLeft(2,'0')} $amPm';
  }
}
