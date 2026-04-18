// ============================================================
//  room_widgets.dart — Lgana Room UI Components
//  Matches reference design images 100%
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/message_model.dart';
import '../../models/room_model.dart';
import '../../theme/app_colors.dart';

// ══════════════════════════════════════════════════════════
//  COLOR HELPERS - وردي وأبيض (Pink & White)
// ══════════════════════════════════════════════════════════
class RC {
  static const pink       = Color(0xFFE91E63); // وردي رئيسي
  static const pinkHeader = Color(0xFFC2185B); // وردي غامق للـ header

  static const List<Color> _names = [
    Color(0xFF6A1B9A), Color(0xFF1565C0), Color(0xFF8B4513),
    Color(0xFF2E7D32), Color(0xFFC62828), Color(0xFF00838F),
    Color(0xFF4527A0), Color(0xFFAD1457), Color(0xFFE65100),
    Color(0xFFFF6F00),
  ];
  static const List<Color> _bars = [
    Color(0xFFE53935), Color(0xFFFFB300), Color(0xFF42A5F5),
    Color(0xFF9E9E9E), Color(0xFF6A1B9A), Color(0xFF00838F),
  ];

  static Color nameFor(String id) {
    final h = id.codeUnits.fold(0, (a, b) => a + b);
    return _names[h % _names.length];
  }

  static Color barFor(String id) {
    final h = id.codeUnits.fold(0, (a, b) => a + b);
    return _bars[h % _bars.length];
  }
}

// ══════════════════════════════════════════════════════════
//  BACKGROUND  (وردي فاتح مع مربعات وأشكال بيضاء)
// ══════════════════════════════════════════════════════════
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 28; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final sz = 28.0 + rng.nextDouble() * 36;
      final angle = rng.nextDouble() * 0.6 - 0.3;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: sz, height: sz),
          const Radius.circular(8),
        ),
        stroke,
      );
      canvas.restore();
    }
    for (int i = 0; i < 45; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        1.5, dot,
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter _) => false;
}

class RoomChatBg extends StatelessWidget {
  final Widget child;
  const RoomChatBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF06292), Color(0xFFE91E63)], // وردي فاتح إلى وردي
        ),
      ),
    ),
    Positioned.fill(child: CustomPaint(painter: _BgPainter())),
    child,
  ]);
}

// ══════════════════════════════════════════════════════════
//  TOP BAR
// ══════════════════════════════════════════════════════════
class RoomTopBar extends StatelessWidget {
  final String roomName;
  final bool isMuted;
  final String elapsed;
  final bool chatTabActive;
  final VoidCallback onRoomTap;
  final VoidCallback onMembersTap;
  final VoidCallback onChatTap;
  final VoidCallback onMenuTap;

  const RoomTopBar({
    super.key,
    required this.roomName,
    required this.isMuted,
    required this.elapsed,
    required this.chatTabActive,
    required this.onRoomTap,
    required this.onMembersTap,
    required this.onChatTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RC.pinkHeader, // وردي غامق للـ header
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          // Room name pill
          GestureDetector(
            onTap: onRoomTap,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 170),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(roomName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 13, fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(width: 4),
                Text(elapsed,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
          ),
          const Spacer(),
          _TopBtn(icon: Icons.people_alt_outlined, active: !chatTabActive, onTap: onMembersTap),
          const SizedBox(width: 2),
          _TopBtn(icon: Icons.chat_bubble_outline, active: chatTabActive, onTap: onChatTap),
          const SizedBox(width: 2),
          _TopBtn(icon: Icons.menu, active: false, onTap: onMenuTap),
        ]),
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TopBtn({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 36,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: active ? RC.pink : Colors.white, size: 22),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  CHAT MESSAGE  (avatar + rank bar + white bubble)
// ══════════════════════════════════════════════════════════
class RoomChatMsg extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final VoidCallback? onLongPress;

  const RoomChatMsg({super.key, required this.msg, required this.isMe, this.onLongPress});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "ص" : "م"}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Circular avatar
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.purple.shade200,
            backgroundImage: (msg.senderPhoto?.isNotEmpty ?? false)
                ? NetworkImage(msg.senderPhoto!) : null,
            child: (msg.senderPhoto?.isEmpty ?? true)
                ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
          ),
          const SizedBox(width: 4),
          // Rank color bar
          Container(
            width: 3, height: 52,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: RC.barFor(msg.senderId),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          // White bubble
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: time LEFT — name RIGHT
                  Row(children: [
                    Text(_fmt(msg.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10.5, fontFamily: 'Cairo')),
                    const Spacer(),
                    Text(msg.senderName,
                      style: TextStyle(
                        color: RC.nameFor(msg.senderId),
                        fontWeight: FontWeight.bold,
                        fontSize: 13, fontFamily: 'Cairo',
                      )),
                  ]),
                  const SizedBox(height: 3),
                  // Image
                  if (msg.imageUrl?.isNotEmpty ?? false) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: CachedNetworkImage(
                          imageUrl: msg.imageUrl!, fit: BoxFit.cover, width: double.infinity,
                          placeholder: (_, __) => const Padding(padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7B1FA2))),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (msg.text.isNotEmpty && msg.text != '📷') const SizedBox(height: 6),
                  ],
                  // Text body
                  if (msg.text.isNotEmpty && msg.text != '📷')
                    Text(msg.text,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14.5, color: Color(0xFF212121),
                        height: 1.4, fontFamily: 'Cairo')),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// System message (join/leave etc.)
class RoomSystemMsg extends StatelessWidget {
  final String text;
  const RoomSystemMsg({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
    child: Center(
      child: Text(text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontSize: 12.5, fontFamily: 'Cairo')),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  MEMBERS PANEL  (white bg, simple list)
// ══════════════════════════════════════════════════════════
class RoomMembersPanel extends StatelessWidget {
  final List<ParticipantModel> members;
  final String myUid;
  final Set<int> speakingUids;
  final VoidCallback onBackToChat;
  final void Function(ParticipantModel) onMemberTap;

  const RoomMembersPanel({
    super.key,
    required this.members,
    required this.myUid,
    required this.speakingUids,
    required this.onBackToChat,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        // "All" — back to public chat
        InkWell(
          onTap: onBackToChat,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(children: [
              Icon(Icons.people_alt, color: Colors.grey.shade600, size: 26),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('All', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')),
                Text('العودة الى الدردشة العامة.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Cairo')),
              ]),
            ]),
          ),
        ),
        // Members
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              final speaking = speakingUids.contains(_agoraId(m.uid));
              return _MemberRow(
                member: m,
                isMe: m.uid == myUid,
                isSpeaking: speaking,
                onTap: () => onMemberTap(m),
              );
            },
          ),
        ),
      ]),
    );
  }

  int _agoraId(String uid) {
    // Same algorithm as AgoraService.uidToAgoraId
    if (uid.isEmpty) return 1;
    var h = 0;
    for (final codeUnit in uid.codeUnits) {
      h = ((h << 5) - h) + codeUnit;
      h = h & 0x7FFFFFFF; // Convert to 32-bit positive integer
    }
    if (h == 0) h = 1; // Ensure non-zero
    return h;
  }
}

class _MemberRow extends StatelessWidget {
  final ParticipantModel member;
  final bool isMe;
  final bool isSpeaking;
  final VoidCallback onTap;
  const _MemberRow({required this.member, required this.isMe,
    required this.isSpeaking, required this.onTap});

  Color get _roleColor => AppColors.roleColor(member.role);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
        ),
        child: Row(children: [
          // Avatar with status indicators
          Stack(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor.withValues(alpha: 0.2),
              backgroundImage: (member.photoURL?.isNotEmpty ?? false)
                  ? NetworkImage(member.photoURL!) : null,
              child: (member.photoURL?.isEmpty ?? true)
                  ? Icon(Icons.person, color: _roleColor) : null,
            ),
            // Speaking indicator (green mic)
            if (isSpeaking)
              Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5)),
                  child: const Icon(Icons.mic, color: Colors.white, size: 8),
                )),
            // Raised hand indicator (yellow hand)
            if (member.hasRaisedHand && !isSpeaking)
              Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.amber, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5)),
                  child: const Icon(Icons.front_hand, color: Colors.white, size: 8),
                )),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMe ? '${member.displayName} (أنت)' : member.displayName,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _roleColor, fontWeight: FontWeight.bold,
                        fontSize: 14, fontFamily: 'Cairo'),
                    ),
                    // ✅ FIX: عرض حالة الحقيقية من Firestore
                    if (member.statusEmoji.isNotEmpty)
                      Text(member.statusEmoji,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.end),
                  ],
                ),
              ),
              // Status icon
              if (member.hasRaisedHand && !isSpeaking)
                const Icon(Icons.front_hand, color: Colors.amber, size: 18),
            ]),
          ),
          Icon(
            member.isMuted ? Icons.mic_off : Icons.mic,
            color: member.isMuted ? Colors.grey : Colors.green,
            size: 20,
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  INPUT BAR  (purple, mic + ••• + field + emoji + send/hand)
// ══════════════════════════════════════════════════════════
class RoomInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isMuted;
  final bool showEmoji;
  final bool isChatSilenced;
  final bool isUploading;
  final bool hasRaisedHand;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onEmojiToggle;
  final VoidCallback onMediaTap;
  final VoidCallback onHandRaise;

  const RoomInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isMuted,
    required this.showEmoji,
    required this.isChatSilenced,
    required this.isUploading,
    required this.hasRaisedHand,
    required this.onSend,
    required this.onMicToggle,
    required this.onEmojiToggle,
    required this.onMediaTap,
    required this.onHandRaise,
  });

  @override
  State<RoomInputBar> createState() => _RoomInputBarState();
}

class _RoomInputBarState extends State<RoomInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    final h = widget.controller.text.trim().isNotEmpty;
    if (h != _hasText) setState(() => _hasText = h);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RC.pink,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(children: [
        // Mic
        _Ico(
          icon: widget.isMuted ? Icons.mic_off : Icons.mic,
          color: widget.isMuted ? Colors.redAccent : Colors.white,
          onTap: widget.onMicToggle,
        ),
        const SizedBox(width: 4),
        // More (•••)
        _Ico(icon: Icons.more_horiz, color: Colors.white, onTap: widget.onMediaTap),
        const SizedBox(width: 6),
        // Text field
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.isChatSilenced && !widget.isUploading,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
              onSubmitted: (_) => widget.onSend(),
              decoration: InputDecoration(
                hintText: widget.isUploading
                    ? 'جاري رفع الصورة…'
                    : (widget.isChatSilenced ? 'الدردشة مكتومة' : 'اكتب رسالة'),
                hintTextDirection: TextDirection.rtl,
                hintStyle: const TextStyle(
                    color: Colors.grey, fontSize: 14, fontFamily: 'Cairo'),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Emoji toggle
        _Ico(
          icon: widget.showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
          color: Colors.amber,
          onTap: widget.onEmojiToggle,
        ),
        const SizedBox(width: 4),
        // Send / Hand raise
        GestureDetector(
          onTap: _hasText ? widget.onSend : widget.onHandRaise,
          child: SizedBox(
            width: 36, height: 36,
            child: widget.isUploading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Icon(
                    _hasText ? Icons.send : Icons.front_hand_outlined,
                    color: (!_hasText && widget.hasRaisedHand)
                        ? Colors.amber : Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ]),
    );
  }
}

class _Ico extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Ico({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 36, height: 36,
        child: Icon(icon, color: color, size: 22)),
  );
}

// ══════════════════════════════════════════════════════════
//  EMOJI PICKER
// ══════════════════════════════════════════════════════════
class RoomEmojiPicker extends StatefulWidget {
  final void Function(String) onEmojiSelected;
  const RoomEmojiPicker({super.key, required this.onEmojiSelected});

  @override
  State<RoomEmojiPicker> createState() => _RoomEmojiPickerState();
}

class _RoomEmojiPickerState extends State<RoomEmojiPicker> {
  int _tab = 0;
  static const _icons = [
    Icons.emoji_emotions_outlined, Icons.pets,
    Icons.waving_hand, Icons.favorite_outline, Icons.lightbulb_outline,
  ];
  static const _emojiCats = [
    ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','😉','😊','😍','🥰','😘','😗','😚','😋','😛','🤪','😝','😜','🤑','🤗','😎','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳'],
    ['🐱','😸','😹','😻','🐶','🐭','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🙈','🙉','🙊','🐧','🦆','🦅','🦉','🦇','🐺','🐴','🦄','🐝','🦋','🐌','🦟','🕷','🐢','🐍','🐙','🦑','🦀','🐟','🐬'],
    ['👋','🤚','🖐','✋','🖖','👌','✌️','🤞','🤟','🤘','🤙','👍','👎','✊','👊','🤛','🤜','👏','🙌','🤝','🙏','💪','🦵','🦶'],
    ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💝','💘','💟'],
    ['💡','🔦','💰','💵','💸','🏆','🥇','⭐','🌟','✨','🔥','💯','💥','❄️','🌈','☀️','🌙','⚡','🌊'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      color: Colors.white,
      child: Column(children: [
        // Category tabs
        Container(
          height: 44,
          color: Colors.grey.shade100,
          child: Row(children: List.generate(_emojiCats.length, (i) =>
            GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                width: 56, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: _tab == i
                      ? Border(bottom: BorderSide(color: RC.pink, width: 2))
                      : null,
                ),
                child: Icon(_icons[i], size: 20,
                    color: _tab == i ? RC.pink : Colors.grey.shade500),
              ),
            ),
          )),
        ),
        // Emoji grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8),
            itemCount: _emojiCats[_tab].length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => widget.onEmojiSelected(_emojiCats[_tab][i]),
              child: Center(
                  child: Text(_emojiCats[_tab][i],
                      style: const TextStyle(fontSize: 22))),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  DROPDOWN MENU  (dark panel, top-right)
// ══════════════════════════════════════════════════════════
class RoomDropdownMenu extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onStatus;
  final VoidCallback? onSettings;
  final VoidCallback? onFavorite;
  final VoidCallback? onClearChat;
  final VoidCallback? onReport;
  final VoidCallback? onLeave;

  const RoomDropdownMenu({
    super.key,
    required this.onClose,
    this.onStatus,
    this.onSettings,
    this.onFavorite,
    this.onClearChat,
    this.onReport,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('الحالة',       onStatus),
      ('الاعدادات',    onSettings),
      ('اضف للمفضلة', onFavorite),
      ('مسح النص',    onClearChat),
      ('تبليغ',       onReport),
      ('خروج',        onLeave),
    ];

    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.only(top: 56, right: 6),
          width: 172,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 14, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((e) {
              final isLast = e == items.last;
              return InkWell(
                onTap: e.$2 == null ? null : () { onClose(); e.$2!(); },
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(10))
                    : BorderRadius.zero,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08)))
                        : null,
                  ),
                  child: Text(e.$1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: e.$2 == null ? Colors.grey : Colors.white,
                      fontSize: 14.5, fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                    )),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  LEAVE DIALOG
// ══════════════════════════════════════════════════════════
Future<bool?> showLeaveRoomDialog(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    title: const Text(
      'هل تريد مغادرة الغرفة ؟',
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
    ),
    actionsAlignment: MainAxisAlignment.spaceEvenly,
    actions: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD81B60),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(100, 42),
        ),
        onPressed: () => Navigator.pop(context, true),
        child: const Text('نعم', style: TextStyle(fontSize: 15, fontFamily: 'Cairo')),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD81B60),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(100, 42),
        ),
        onPressed: () => Navigator.pop(context, false),
        child: const Text('لا', style: TextStyle(fontSize: 15, fontFamily: 'Cairo')),
      ),
    ],
  ),
);

// ══════════════════════════════════════════════════════════
//  MEDIA OPTIONS  (bottom sheet: ارسال صورة / كاميرا / فيديو)
// ══════════════════════════════════════════════════════════
void showMediaOptionsSheet(
  BuildContext context, {
  required VoidCallback onGallery,
  required VoidCallback onCamera,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MediaOpt(icon: Icons.photo_library, label: 'ارسال صورة',
              iconColor: const Color(0xFF4CAF50), onTap: () { Navigator.pop(context); onGallery(); }),
          _MediaOpt(icon: Icons.camera_alt, label: 'كاميرا',
              iconColor: const Color(0xFF2196F3), onTap: () { Navigator.pop(context); onCamera(); }),
          _MediaOpt(icon: Icons.videocam, label: 'فيديو',
              iconColor: const Color(0xFFE91E8C), onTap: () => Navigator.pop(context)),
        ],
      ),
    ),
  );
}

class _MediaOpt extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  const _MediaOpt({required this.icon, required this.label,
      required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      const SizedBox(height: 7),
      Text(label, style: const TextStyle(
          fontSize: 12, color: Color(0xFF424242), fontFamily: 'Cairo')),
    ]),
  );
}

// ══════════════════════════════════════════════════════════
//  CLOSED ROOM SCREEN
// ══════════════════════════════════════════════════════════
class ClosedRoomView extends StatelessWidget {
  final VoidCallback onBack;
  const ClosedRoomView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFECECEC),
    appBar: AppBar(
      backgroundColor: RC.pinkHeader,
      title: const Text('الغرفة مغلقة',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('تم إغلاق الغرفة',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18)),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: RC.pink),
          onPressed: onBack,
          child: const Text('رجوع',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        ),
      ]),
    ),
  );
}
