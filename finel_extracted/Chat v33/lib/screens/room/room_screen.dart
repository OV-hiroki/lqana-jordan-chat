// ============================================================
//  Room Screen v31 — Complete Lgana UI Rebuild
//  UI: room_widgets.dart | Logic: Firebase + Agora preserved
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/agora_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

import 'room_widgets.dart';
import 'room_info_tab.dart';
import 'room_settings_tab.dart';
import 'room_ban_tab.dart';
import 'room_log_tab.dart';
import 'room_reports_tab.dart';
// import 'add_account_dialog.dart'; // TODO: File was replaced with LoginScreen
import 'private_chat_overlay.dart';

// ══════════════════════════════════════════════════════════
class RoomScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  const RoomScreen({super.key, required this.roomId, this.isHost = false});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

// ══════════════════════════════════════════════════════════
class _RoomScreenState extends State<RoomScreen> {
  // ── UI state ───────────────────────────────────────────
  bool _chatTabActive = true;
  bool _showMenu = false;
  bool _showEmoji = false;
  bool _chatSilenced = false;
  bool _agoraReady = false;
  bool _uploadingChatImage = false;

  // ── Local state for instant UI feedback ─────────────────
  bool? _localIsMuted;
  bool? _localHasRaisedHand;

  // ── Private Chat state ────────────────────────────────────
  String? _privateChatWithUid;
  String? _privateChatWithName;
  String? _lastPrivateMessage;

  // ── Chat scroll state ─────────────────────────────────────
  int _previousMessageCount = 0;

  // ── Room timer ─────────────────────────────────────────
  late Timer _timer;
  int _elapsedSeconds = 0;

  // ── Misc ───────────────────────────────────────────────
  String? _logDocId;

  // ── Controllers / nodes ────────────────────────────────
  final _msgCtrl        = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  final _focusNode      = FocusNode();

  // ══════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _joinRoom();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _elapsedSeconds++); },
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _msgCtrl.dispose();
    _chatScrollCtrl.dispose();
    _focusNode.dispose();
    AgoraService.instance.clearAllCallbacks();
    AgoraService.instance.leaveChannel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════
  String get _elapsed {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 80),
          () { if (mounted) setState(() => _showEmoji = true); });
    }
  }

  // ══════════════════════════════════════════════════════
  //  AGORA / FIRESTORE LOGIC  (preserved from v29)
  // ══════════════════════════════════════════════════════
  void _joinRoom() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return;

    final roomDoc = await FirestoreService.instance.getRoomOnce(widget.roomId);
    var role = widget.isHost ? AppConstants.roleMaster : AppConstants.roleGuest;
    if (!widget.isHost &&
        roomDoc?.designatedRoomAdminUid != null &&
        roomDoc!.designatedRoomAdminUid == profile.uid) {
      role = AppConstants.roleAdmin;
    }

    final p = ParticipantModel(
      uid:         profile.uid,
      displayName: profile.displayName,
      photoURL:    profile.photoURL,
      role:        role,
      isMuted:     true,
      deviceId:    'dev_${profile.uid.length >= 8 ? profile.uid.substring(0, 8) : profile.uid}',
      country:     'JO',
    );

    // مزامنة الحالة المحلية
    setState(() {
      _localIsMuted = p.isMuted;
      _localHasRaisedHand = p.hasRaisedHand;
    });

    _logDocId = await FirestoreService.instance.logJoin(widget.roomId, p);
    await FirestoreService.instance.joinAsListener(widget.roomId);

    // إرسال رسالة نظام في الدردشة
    await FirestoreService.instance.sendSystemMessage(
      widget.roomId,
      '${p.displayName} انضم إلى الغرفة',
    );

    // ✅ FIX: دائماً اضف المستخدم كـ speaker عشان يظهر في القائمة ويقدر يتحكم في المايك
    // (كل المستخدمين في speakers — isMuted: true للزوار والأعضاء)
    await FirestoreService.instance.addSpeaker(widget.roomId, p);

    _setupAgoraCallbacks();

    // ✔ طلب إذن المايك وقت التشغيل (Android ضروري)
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'لم يتم منح إذن المايكروفون — لا يمكن استخدام الصوت',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ));
        if (micStatus.isPermanentlyDenied) openAppSettings();
      }
    }

    // تأخير بسيط لضمان تجهيز محرك Agora
    await Future.delayed(const Duration(milliseconds: 300));

    final ok = await AgoraService.instance.joinChannel(
      channelId: widget.roomId,
      userId: profile.uid,  // استخدم userId مباشرة
      joinMuted: true,
    );
    if (mounted) {
      setState(() => _agoraReady = ok);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر الاتصال بالغرفة الصوتية — تحقّق من الإنترنت',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ));
      }
    }
  }

  void _setupAgoraCallbacks() {
    final agora = AgoraService.instance;
    
    // استخدم نمط الـ callback الجديد (يمكن تسجيل عدة callbacks)
    agora.onRemoteJoined((uid) {
      // مستخدم جديد انضم
      if (mounted) setState(() {});
    });
    
    agora.onRemoteLeft((uid) {
      if (mounted) setState(() {});
    });
    
    agora.onSpeaking((_) {
      // speakingUidsNotifier يتولى التحديث بنفسه
    });
    
    agora.onError((code, msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ Agora ($code): $msg',
            style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ));
    });
    
    agora.onMuteChanged((isMuted) {
      // تحديث حالة الـ mute محلياً إذا لزم الأمر
      if (mounted) setState(() {});
    });
  }

  void _leaveRoom() async {
    final uid = context.read<AuthProvider>().profile?.uid;
    final profile = context.read<AuthProvider>().profile;

    // ✅ إرسال رسالة نظام قبل المغادرة
    if (profile != null) {
      try {
        await FirestoreService.instance.sendSystemMessage(
          widget.roomId,
          '${profile.displayName} غادر الغرفة',
        );
      } catch (_) {}
    }

    await AgoraService.instance.leaveChannel();
    if (uid != null) {
      // ✅ FIX: نزيل المستخدم من speakers (مش بس decrement listeners)
      try { await FirestoreService.instance.removeSpeaker(widget.roomId, uid); } catch (_) {}
      // ✅ decrement listeners أيضاً (للتوازن مع joinAsListener)
      try { await FirestoreService.instance.leaveAsListener(widget.roomId); } catch (_) {}
    }
    if (_logDocId != null) {
      try { await FirestoreService.instance.logLeave(widget.roomId, _logDocId!); } catch (_) {}
    }
  }

  Future<void> _toggleMute(RoomModel room, ParticipantModel myP) async {
    final newMuted = !myP.isMuted;

    // تحديث الحالة المحلية فوراً لـ UI feedback
    setState(() => _localIsMuted = newMuted);

    // تحديث Agora
    await AgoraService.instance.setLocalMuted(newMuted);

    // التأكد من أن المستخدم موجود كمتحدث في Firestore
    if (!newMuted) {
      // إذا نريد فتح المايك، تأكد من أن المستخدم متحدث
      await FirestoreService.instance.addSpeaker(room.id, myP);

      // إرسال رسالة نظام عند الحصول على المايك
      await FirestoreService.instance.sendSystemMessage(
        room.id,
        '${myP.displayName} حصل على المايك',
      );
    }

    // تحديث isMuted في Firestore
    await FirestoreService.instance.toggleMute(room.id, myP.uid, newMuted);
  }

  void _sendMessage(String roomId, UserModel? profile) {
    if (_chatSilenced) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الدردشة الكتابية مكتومة',
            style: TextStyle(fontFamily: 'Cairo')),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || profile == null) return;
    FirestoreService.instance.sendRoomMessage(roomId, profile, text: txt);
    _msgCtrl.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(RoomModel room, UserModel? profile,
      ImageSource source) async {
    // ✗ منع الزوار من إرسال الصور
    final isGuest = context.read<AuthProvider>().isGuest;
    if (isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('يجب تسجيل الدخول لإرسال الصور والفيديو',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFFD81B60),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ));
      }
      return;
    }

    if (_chatSilenced || profile == null) return;
    if (!room.settings.allowImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('إرسال الصور معطّل في هذه الغرفة',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }

    final picker = ImagePicker();
    final xfile  = await picker.pickImage(
        source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 84);
    if (xfile == null || !mounted) return;
    setState(() => _uploadingChatImage = true);
    try {
      final bytes = await xfile.readAsBytes();
      final up = await CloudinaryService.instance.uploadImageBytes(bytes,
          filename: xfile.name.isNotEmpty ? xfile.name : 'chat.jpg',
          folder: '${AppConstants.folderRoomImages}/chat_${room.id}');
      if (!mounted) return;
      if (!up.success || up.url == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(up.error ?? 'فشل رفع الصورة',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      await FirestoreService.instance.sendRoomMessage(room.id, profile,
          text: _msgCtrl.text.trim(), imageUrl: up.url);
      _msgCtrl.clear();
    } finally {
      if (mounted) setState(() => _uploadingChatImage = false);
    }
  }

  // ══════════════════════════════════════════════════════
  //  ADMIN PANEL  (bottom sheet wrapping existing tabs)
  // ══════════════════════════════════════════════════════
  void _showAdminPanel(BuildContext ctx, bool isOwner, bool isAdmin, RoomModel room) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminPanelSheet(
        room:    room,
        isAdmin: isAdmin,
        isOwner: isOwner,
        myUid:   context.read<AuthProvider>().profile?.uid ?? '',
        onAddAccount: () {
          // TODO: Fix AddAccountDialog - file was replaced with LoginScreen
          final profile = context.read<AuthProvider>().profile!;
          Navigator.pop(ctx);
          // showDialog(context: context,
          //   builder: (_) => AddAccountDialog(
          //       roomId: room.id, myName: profile.displayName));
        },
      ),
    );
  }

  void _showMemberActions(BuildContext ctx, ParticipantModel speaker,
      String myUid, bool canManage, String roomId) {
    if (!canManage || speaker.uid == myUid) return;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.borderDefault, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(speaker.displayName,
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                  fontSize: 15, color: AppColors.roleColor(speaker.role))),
          ),
          const Divider(height: 1),
          _ActionTile(Icons.mic_off, 'كتم / فك الكتم', AppColors.warning,
            () => FirestoreService.instance.toggleMute(roomId, speaker.uid, !speaker.isMuted)),
          _ActionTile(Icons.how_to_reg, 'تغيير الرتبة', AppColors.primary,
            () { Navigator.pop(ctx); _showRoleDialog(ctx, speaker, roomId); }),
          _ActionTile(Icons.exit_to_app, 'طرد من الغرفة', AppColors.error,
            () => FirestoreService.instance.removeSpeaker(roomId, speaker.uid)),
          _ActionTile(Icons.devices_other, 'حظر الجهاز', AppColors.error,
            () async {
              await FirestoreService.instance.banFromRoom(roomId,
                displayName: speaker.displayName, deviceId: speaker.deviceId,
                bannedBy: context.read<AuthProvider>().profile?.displayName ?? '?');
              await FirestoreService.instance.removeSpeaker(roomId, speaker.uid);
            }),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _showRoleDialog(BuildContext ctx, ParticipantModel speaker, String roomId) {
    final myUid = context.read<AuthProvider>().profile?.uid ?? '';
    final isOwnerNow = widget.isHost ||
        (context.read<AuthProvider>().profile?.isAdmin == true);
    showDialog(context: ctx, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('تغيير رتبة ${speaker.displayName}',
          style: const TextStyle(fontFamily: 'Cairo',
              color: AppColors.textPrimary, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnerNow) AppConstants.roleMaster,
            if (isOwnerNow) AppConstants.roleSuperAdmin,
            AppConstants.roleAdmin,
            AppConstants.roleMember,
            AppConstants.roleGuest,
          ].map((role) => ListTile(
            onTap: () async {
              await FirestoreService.instance
                  .changeSpeakerRole(roomId, speaker.uid, role);
              if (mounted) Navigator.pop(context);
            },
            leading: CircleAvatar(
                radius: 8, backgroundColor: AppColors.roleColor(role)),
            title: Text(AppConstants.roleLabel(role),
              style: TextStyle(fontFamily: 'Cairo',
                  color: AppColors.roleColor(role), fontWeight: FontWeight.bold)),
          )).toList(),
        ),
      ),
    ));
  }

  void _showReportDialog(String roomId) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Row(children: [
          Icon(Icons.flag, color: AppColors.error), SizedBox(width: 8),
          Text('تبليغ', style: TextStyle(fontFamily: 'Cairo',
              color: AppColors.textPrimary)),
        ]),
        content: TextField(controller: ctrl, maxLines: 3,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary),
          decoration: const InputDecoration(
              hintText: 'اذكر سبب التبليغ...',
              hintStyle: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo',
                color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context),
            child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo',
                color: Colors.white))),
        ],
      ),
    ));
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryLight,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () {
            if (_showMenu)  setState(() => _showMenu  = false);
            if (_showEmoji) setState(() => _showEmoji = false);
          },
          behavior: HitTestBehavior.translucent,
          child: StreamBuilder<RoomModel?>(
            stream: FirestoreService.instance.listenToRoom(widget.roomId),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
              }

              final room = snapshot.data;
              if (room == null || !room.isLive) {
                return ClosedRoomView(onBack: () => Navigator.pop(context));
              }

              final myUid   = context.watch<AuthProvider>().profile?.uid ?? '';
              final profile = context.watch<AuthProvider>().profile;
              // ✅ FIX: myP لازم يكون موجود دايماً بعد joinRoom (كل المستخدمين في speakers)
              final myP = room.speakers.where((s) => s.uid == myUid).isNotEmpty
                  ? room.speakers.firstWhere((s) => s.uid == myUid)
                  : null;
              final iAmSpkr = myP != null;
              // ✅ FIX: isAdmin يشمل كل الرتب فوق member + الأدمن المعين من الداشبورد
              final isDesignatedAdmin = room.designatedRoomAdminUid != null &&
                  room.designatedRoomAdminUid == myUid;
              final isAdmin = widget.isHost ||
                  isDesignatedAdmin ||
                  (myP != null &&
                      myP.role != AppConstants.roleGuest &&
                      myP.role != AppConstants.roleMember);
              // ✅ FIX: isOwner = صاحب الغرفة الحقيقي أو الأدمن العام
              final isOwner = widget.isHost ||
                  myUid == room.renterUid ||
                  myUid == room.hostUid ||
                  (profile?.isAdmin == true);

              final isMuted       = _localIsMuted ?? (myP?.isMuted ?? true);
              final hasRaisedHand = _localHasRaisedHand ?? (myP?.hasRaisedHand ?? false);

              return Stack(children: [
                // ── Main screen ────────────────────────
                RoomChatBg(
                  child: Column(children: [
                    // TOP BAR
                    RoomTopBar(
                      roomName:      room.title,
                      isMuted:       isMuted,
                      elapsed:       _elapsed,
                      chatTabActive: _chatTabActive,
                      onRoomTap: () {
                        if (myP != null) _toggleMute(room, myP);
                      },
                      onMembersTap: () => setState(() {
                        _chatTabActive = false;
                        _showMenu = false;
                      }),
                      onChatTap: () => setState(() {
                        _chatTabActive = true;
                        _showMenu = false;
                      }),
                      onMenuTap: () =>
                          setState(() => _showMenu = !_showMenu),
                    ),

                    // Private message notification bar
                    if (_lastPrivateMessage != null)
                      Container(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(children: [
                          const Icon(Icons.message, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastPrivateMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Open private chat
                              setState(() => _lastPrivateMessage = null);
                            },
                            child: const Icon(Icons.close, color: AppColors.primary, size: 16),
                          ),
                        ]),
                      ),

                    // Agora status bar (subtle)
                    if (_agoraReady)
                      Container(
                        color: AppColors.speaking.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: ValueListenableBuilder<Set<int>>(
                          valueListenable:
                              AgoraService.instance.remoteUidsNotifier,
                          builder: (_, remotes, __) => Row(children: [
                            const Icon(Icons.record_voice_over,
                                color: AppColors.speaking, size: 12),
                            const SizedBox(width: 5),
                            Text('الصوت نشط • ${remotes.length} متصل',
                              style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 10,
                                color: AppColors.speaking)),
                          ]),
                        ),
                      ),

                    // CONTENT
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _chatTabActive
                            ? _buildChat(room.id, myUid)
                            : _buildMembers(room, myUid, isAdmin),
                      ),
                    ),

                    // INPUT BAR
                    RoomInputBar(
                      controller:     _msgCtrl,
                      focusNode:      _focusNode,
                      isMuted:        isMuted,
                      showEmoji:      _showEmoji,
                      isChatSilenced: _chatSilenced,
                      isUploading:    _uploadingChatImage,
                      hasRaisedHand:  hasRaisedHand,
                      onSend: () => _sendMessage(room.id, profile),
                      onMicToggle: () {
                        if (myP != null) _toggleMute(room, myP);
                      },
                      onEmojiToggle: _toggleEmoji,
                      onMediaTap: () => showMediaOptionsSheet(context,
                        onGallery: () =>
                            _pickAndSendImage(room, profile, ImageSource.gallery),
                        onCamera: () =>
                            _pickAndSendImage(room, profile, ImageSource.camera),
                      ),
                      onHandRaise: () {
                        if (myP != null) {
                          final newRaisedHand = !hasRaisedHand;

                          // تحديث الحالة المحلية فوراً لـ UI feedback
                          setState(() => _localHasRaisedHand = newRaisedHand);

                          // تحديث Firestore في الخلفية
                          FirestoreService.instance.raiseHand(
                              room.id, myP.uid, newRaisedHand);

                          // إرسال رسالة نظام
                          if (newRaisedHand) {
                            FirestoreService.instance.sendSystemMessage(
                              room.id,
                              '${myP.displayName} رفع يده',
                            );
                          }
                        }
                      },
                    ),

                    // EMOJI PICKER
                    if (_showEmoji)
                      RoomEmojiPicker(
                        onEmojiSelected: (e) {
                          final c = _msgCtrl.value;
                          final t = c.text + e;
                          _msgCtrl.value = c.copyWith(
                            text: t,
                            selection: TextSelection.collapsed(offset: t.length),
                          );
                        },
                      ),
                  ]),
                ),

                // ── Dropdown menu ──────────────────────
                if (_showMenu)
                  RoomDropdownMenu(
                    onClose: () => setState(() => _showMenu = false),
                    onStatus: () => _showStatusDialog(),
                    onSettings: isAdmin
                        ? () => _showAdminPanel(context, isOwner, isAdmin, room)
                        : null,
                    onFavorite: () => _addToFavorites(room),
                    onClearChat: isAdmin
                        ? () => FirestoreService.instance
                            .clearRoomMessages(room.id)
                        : null,
                    onReport: () => _showReportDialog(room.id),
                    onLeave: () async {
                      setState(() => _showMenu = false);
                      final ok = await showLeaveRoomDialog(context);
                      if (ok == true && context.mounted) {
                        _leaveRoom();
                        Navigator.pop(context);
                      }
                    },
                  ),

                // ── Private Chat Overlay ────────────────
                if (_privateChatWithUid != null)
                  PrivateChatOverlay(
                    roomId:    widget.roomId,
                    myUid:     myUid,
                    myName:    profile?.displayName ?? 'مجهول',
                    otherUid:  _privateChatWithUid!,
                    otherName: _privateChatWithName ?? 'مجهول',
                    onClose: () => setState(() {
                      _privateChatWithUid  = null;
                      _privateChatWithName = null;
                    }),
                  ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  // ── Status dialog ─────────────────────────────────────
  void _showStatusDialog() {
    final statuses = [
      ('🎵', 'موجود'),
      ('😴', 'غائب'),
      ('📞', 'على الهاتف'),
      ('🔇', 'مشغول'),
      ('❤️', 'وضع خاص'),
      ('☕', 'استراحة'),
      ('🎮', 'ألعاب'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('تغيير الحالة',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo',
                fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...statuses.map((s) => ListTile(
            onTap: () async {
              Navigator.pop(ctx);
              // ✅ FIX: حفظ الحالة في Firestore
              final myUid = context.read<AuthProvider>().profile?.uid;
              if (myUid != null) {
                await FirestoreService.instance.updateSpeaker(
                  widget.roomId, myUid, {'statusEmoji': s.$1},
                );
                await FirestoreService.instance.sendSystemMessage(
                  widget.roomId,
                  '${context.read<AuthProvider>().profile?.displayName ?? ''} غيّر حالته إلى ${s.$1} ${s.$2}',
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('الحالة: ${s.$1} ${s.$2}',
                      style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: const Color(0xFF7B1FA2),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            leading: Text(s.$1, style: const TextStyle(fontSize: 22)),
            title: Text(s.$2,
              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Add to favorites ────────────────────────────────
  Future<void> _addToFavorites(RoomModel room) async {
    final uid = context.read<AuthProvider>().profile?.uid;
    if (uid == null || uid == 'offline_user') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يجب تسجيل الدخول لإضافة المفضلات',
            style: TextStyle(fontFamily: 'Cairo')),
      ));
      return;
    }
    // ✅ FIX: حفظ حقيقي في Firestore
    final isFav = await FirestoreService.instance.isFavorite(uid, room.id);
    if (isFav) {
      await FirestoreService.instance.removeFavorite(uid, room.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تمت إزالة "${room.title}" من المفضلة',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      await FirestoreService.instance.addFavorite(uid, room.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تمت إضافة "${room.title}" للمفضلة ❤️',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFFD81B60),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  // ── Chat list ──────────────────────────────────────────
  Widget _buildChat(String roomId, String myUid) {
    return StreamBuilder<List<MessageModel>>(
      key: const ValueKey('chat'),
      stream: FirestoreService.instance.listenToRoomMessages(roomId),
      builder: (context, snapshot) {
        final msgs = snapshot.data ?? [];
        // Auto-scroll to bottom only on new message
        final shouldScroll = msgs.length > _previousMessageCount;
        _previousMessageCount = msgs.length;

        if (shouldScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_chatScrollCtrl.hasClients) {
              _chatScrollCtrl.jumpTo(_chatScrollCtrl.position.maxScrollExtent);
            }
          });
        }

        if (msgs.isEmpty) {
          return const Center(
            child: Text('لا توجد رسائل بعد',
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 13, color: Colors.white70)),
          );
        }
        return ListView.builder(
          controller: _chatScrollCtrl,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final m = msgs[i];
            // System messages
            if (m.text.startsWith('انضم') || m.text.startsWith('غادر') ||
                m.senderId == 'system') {
              return RoomSystemMsg(text: m.text);
            }
            return RoomChatMsg(
              msg: m,
              isMe: m.senderId == myUid,
              onLongPress: () => _showMsgOptions(m, myUid),
            );
          },
        );
      },
    );
  }

  void _showMsgOptions(MessageModel msg, String myUid) {
    // Dark popup menu matching the design image
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DarkMenuItem('محادثة خاصة', () {
                Navigator.pop(context);
                setState(() {
                  _privateChatWithUid  = msg.senderId;
                  _privateChatWithName = msg.senderName;
                });
              }),
              _DarkMenuItem('نسخ', () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم نسخ الرسالة',
                      style: TextStyle(fontFamily: 'Cairo')),
                  duration: Duration(seconds: 1),
                ));
              }),
              _DarkMenuItem('مسح النص', () {
                Navigator.pop(context);
              }),
              _DarkMenuItem(msg.senderName, () => Navigator.pop(context)),
              _DarkMenuItem('تجاهل', () => Navigator.pop(context), isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  // ── Members list ──────────────────────────────────────
  Widget _buildMembers(RoomModel room, String myUid, bool isAdmin) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: AgoraService.instance.speakingUidsNotifier,
      builder: (_, speakingUids, __) => RoomMembersPanel(
        members:      room.speakers,
        myUid:        myUid,
        speakingUids: speakingUids,
        onBackToChat: () => setState(() => _chatTabActive = true),
        onMemberTap:  (m) => _showMemberActions(context, m, myUid, isAdmin, room.id),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  ADMIN PANEL SHEET  (full-height modal with existing tabs)
// ══════════════════════════════════════════════════════════
class _AdminPanelSheet extends StatefulWidget {
  final RoomModel room;
  final bool isAdmin;
  final bool isOwner;
  final String myUid;
  final VoidCallback onAddAccount;

  const _AdminPanelSheet({
    required this.room,
    required this.isAdmin,
    required this.isOwner,
    required this.myUid,
    required this.onAddAccount,
  });

  @override
  State<_AdminPanelSheet> createState() => _AdminPanelSheetState();
}

class _AdminPanelSheetState extends State<_AdminPanelSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, Widget)>[
      ('معلومات',   RoomInfoTab(room: widget.room)),
      ('الإعدادات', RoomSettingsTab(room: widget.room, canEdit: widget.isOwner)),
      if (widget.isAdmin) ...[
        ('المحظورون', RoomBanTab(roomId: widget.room.id, isAdmin: widget.isAdmin)),
        ('السجل',     RoomLogTab(roomId: widget.room.id)),
        ('التقارير',  RoomReportsTab(roomId: widget.room.id)),
      ],
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(2)),
          ),
          // Tab bar
          Container(
            color: AppColors.bgTertiary,
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.asMap().entries.map((e) {
                  final sel = _tab == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.bgSecondary : Colors.transparent,
                        border: sel ? const Border(
                          bottom: BorderSide(color: AppColors.primary, width: 2))
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(e.value.$1,
                        style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 12,
                          color: sel ? AppColors.primary : AppColors.textMuted,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Tab content
          Expanded(child: IndexedStack(
            index: _tab,
            children: tabs.map((t) => t.$2).toList(),
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  HELPER TILE  (action in member bottom sheet)
// ══════════════════════════════════════════════════════════
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color, size: 20),
    title: Text(label,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: color)),
    onTap: () { Navigator.pop(context); onTap(); },
  );
}

// ══════════════════════════════════════════════════════════
//  DARK MENU ITEM  (long-press message popup — matches design)
// ══════════════════════════════════════════════════════════
class _DarkMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _DarkMenuItem(this.label, this.onTap, {this.isLast = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.10))),
      ),
      child: Text(
        label,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'Cairo',
        ),
      ),
    ),
  );
}

