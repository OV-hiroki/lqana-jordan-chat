// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
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

const String _agoraAppId = '98ff0070534d4fd2a6790c31d1d2b140';

class ChatScreen extends StatefulWidget {
  final ChatRoom room;
  final ChatUser me;
  final Function(ChatUser)? onMeUpdated;
  const ChatScreen({super.key, required this.room, required this.me, this.onMeUpdated});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

  // Agora
  RtcEngine? _engine;
  bool _micOn = false;
  bool _inChannel = false;
  bool _audioMuted = false; // زر كتم الصوت الكلي (المكبر في الـ top bar)

  // Timer for elapsed time
  int _elapsedSec = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _me = widget.me;
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
      token: '', // استخدم token من الـ server في الإنتاج
      channelId: 'room_${widget.room.id}',
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  Future<void> _toggleMic() async {
    if (!_inChannel) {
      await _joinAgoraChannel();
    }
    setState(() => _micOn = !_micOn);
    await _engine?.muteLocalAudioStream(!_micOn);

    // Update Firestore room state
    if (_micOn) {
      await _svc.updateRoomState(widget.room.id, {'activeMic': _me.id});
    } else {
      await _svc.updateRoomState(widget.room.id, {'activeMic': null});
    }
  }

  // ─── Subscribe ────────────────────────────────────────────────────────────
  void _subscribe() {
    _msgSub = _svc.msgsStream(widget.room.id).listen((m) {
      if (!mounted) return;
      setState(() => _msgs = m.where((msg) => msg.timestamp >= _rs.clearedAt).toList());
      _scrollBottom();
    });
    _memberSub = _svc.membersStream(widget.room.id).listen((m) {
      if (mounted) setState(() => _members = m);
    });
    _stateSub = _svc.roomStateStream(widget.room.id).listen((s) {
      if (mounted) setState(() => _rs = s);
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel(); _memberSub?.cancel(); _stateSub?.cancel();
    _timer?.cancel();
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
      _toast('إرسال الصور مغلق حالياً 🔒');
      return;
    }
    if (_uploadingImage || _sending) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await CloudinaryService.instance.uploadImage(x);
      await _svc.sendMsg(widget.room.id, {
        'senderId': _me.id,
        'senderName': _me.name,
        'senderAvatar': _me.avatar,
        'senderRole': _me.role.fsValue,
        'senderNameColor': _me.nameColor,
        'text': '',
        'imageUrl': url,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      _toast('فشل رفع الصورة');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.teal, duration: const Duration(seconds: 2)));
  }

  String get _timerStr {
    if (!_inChannel && !_micOn) return 'Mic Free';
    final h = _elapsedSec ~/ 3600;
    final m = (_elapsedSec % 3600) ~/ 60;
    final s = _elapsedSec % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}'
                 : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
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
                _roomMenuItem(Icons.settings_outlined, 'الإعدادات', AppColors.teal, () { Navigator.pop(dialogCtx); }),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopBar(),
          if (_rs.pinnedMsg?.isNotEmpty == true) _buildPinned(),
          Expanded(child: _buildMessages()),
          if (_showEmoji) _buildEmojiGrid(),
          if (_replyTo != null) _buildReplyBar(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─── Top bar (نفس الشاشة: رمادي فاتح، هامبرجر أزرق، chat أصفر) ──────────
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
      child: Row(
        children: [
          // Hamburger (أزرق)
          GestureDetector(
            onTap: _showRoomMenu,
            child: Container(
              width: 46, height: 40,
              decoration: BoxDecoration(
                color: AppColors.btnMenu,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _topBar(), const SizedBox(height: 4), _topBar(), const SizedBox(height: 4), _topBar(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Chat bubble (أصفر)
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 42, height: 40,
              decoration: BoxDecoration(
                color: AppColors.btnChat,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF424242), size: 22),
            ),
          ),
          // Center: mic owner name + timer
          Expanded(
            child: Column(
              children: [
                Text(
                  activeMicUser?.name ?? (_inChannel ? _me.name : 'Mic Free'),
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800,
                    color: activeMicUser != null ? Colors.red : Colors.black54,
                  ),
                ),
                Text(
                  _inChannel ? _timerStr : '--:--',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),
          // Mute speaker button
          GestureDetector(
            onTap: () {
              setState(() => _audioMuted = !_audioMuted);
              _engine?.muteAllRemoteAudioStreams(_audioMuted);
            },
            child: Row(
              children: [
                Icon(
                  _audioMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.red, size: 22,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.close, color: Colors.red, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Connected count
          Column(
            children: [
              Text('متصل', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.green)),
              Text('${_members.length}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topBar() => Container(
    height: 2.5, width: 20, margin: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
  );

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

  // ─── Welcome message (نفس الشكل: تاج وورود) ──────────────────────────────
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
          // Oval placeholder (شريط التواجد)
          Container(
            width: 60, height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(9),
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
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(msg.text ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    final isMine = msg.senderId == _me.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(radius: 16,
              backgroundImage: msg.senderAvatar != null ? NetworkImage(msg.senderAvatar!) : null,
              backgroundColor: Colors.grey.shade200,
              child: msg.senderAvatar == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null),
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMine)
                      Text(msg.senderName,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _parseColor(msg.senderNameColor) ?? AppColors.teal)),
                    if (msg.replyToId != null) _buildReplyPreview(msg),
                    if (msg.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(msg.imageUrl!, width: 180, fit: BoxFit.cover))
                    else
                      Text(msg.text ?? '',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.black87)),
                    Text(_fmtTime(msg.timestamp),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 6),
            CircleAvatar(radius: 16,
              backgroundImage: _me.avatar != null ? NetworkImage(_me.avatar!) : null,
              backgroundColor: Colors.grey.shade200,
              child: _me.avatar == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
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
            // Reactions
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

  // ─── Emoji grid (نفس الشكل: grid مع زر ألعاب الغرفة) ─────────────────────
  Widget _buildEmojiGrid() {
    const emojis = ['😊','😘','🥰','😍','🤣','😂','😄','😐','🤨','😏','😎','😋','😜','😩','😢','😮','🤐','😑','😏','😕','😤','😠','🥱','😴'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Games button
          GestureDetector(
            onTap: () {
              setState(() => _showEmoji = false);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => GamesScreen(room: widget.room, me: _me)));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(14),
              ),
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
          // Emoji header
          const Align(
            alignment: Alignment.centerRight,
            child: Text('اختر إيموجي ✨', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 8),
          // Emoji grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
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

  // ─── Input bar (نفس الشكل بالضبط) ────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 8, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      color: Colors.white,
      child: Row(
        children: [
          // Send button (تيل دائري)
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
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
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
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة',
                  hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Plus button (أخضر)
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
          // Mic button (أحمر/أخضر)
          GestureDetector(
            onTap: _toggleMic,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _micOn ? AppColors.btnMicOn : AppColors.btnMic,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _micOn ? Icons.mic : Icons.mic_off,
                color: Colors.white, size: 22,
              ),
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
