// ============================================================
//  Chat Room Screen — Lgana Style (rebuilt from design images)
// ============================================================

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════
//  CONSTANTS / THEME
// ═══════════════════════════════════════════════════════════

class _C {
  // Primary purple (header / input bar)
  static const purple = Color(0xFF9C27B0);
  static const purpleHeader = Color(0xFF9B27AF); // exact header shade from img

  // Background purples (chat area gradient)
  static const bgLight = Color(0xFFDDA0DD); // plum
  static const bgDark = Color(0xFFBA68C8);

  // Rank colors (left bar + username)
  static const rankMaster = Color(0xFFE53935); // red
  static const rankAdmin = Color(0xFFFFB300);  // amber/gold ★
  static const rankMember = Color(0xFF42A5F5); // blue ✓
  static const rankGuest = Color(0xFF9E9E9E);  // grey

  // Username text colors (cycled by userId hash)
  static const List<Color> nameColors = [
    Color(0xFF6A1B9A),
    Color(0xFF1565C0),
    Color(0xFF8B4513),
    Color(0xFF2E7D32),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF4527A0),
    Color(0xFFAD1457),
    Color(0xFFE65100),
  ];

  static Color nameFor(String uid) {
    final h = uid.codeUnits.fold(0, (a, b) => a + b);
    return nameColors[h % nameColors.length];
  }

  static Color rankFor(String role) {
    switch (role.toLowerCase()) {
      case 'master': return rankMaster;
      case 'admin':  return rankAdmin;
      case 'member': return rankMember;
      default:       return rankGuest;
    }
  }

  static IconData rankIconFor(String role) {
    switch (role.toLowerCase()) {
      case 'master': return Icons.star;
      case 'admin':  return Icons.military_tech;
      case 'member': return Icons.verified;
      default:       return Icons.person;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════

enum MessageType { text, system }
enum MemberStatus { speaking, muted, handRaised }

class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final Color nameColor;
  final Color rankColor;
  final bool isDeleted;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    required this.nameColor,
    required this.rankColor,
    this.isDeleted = false,
  });
}

class RoomMember {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String role;
  final MemberStatus status;
  final Color rankColor;
  final bool isBanned;

  const RoomMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.rankColor,
    this.isBanned = false,
  });
}

// ═══════════════════════════════════════════════════════════
//  BACKGROUND  — lavender with white geometric tile pattern
//  (matches img: rounded rectangles/squares scattered over
//   light purple/lavender gradient)
// ═══════════════════════════════════════════════════════════

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rng = Random(42);
    final count = 28;
    for (int i = 0; i < count; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final sz = 28 + rng.nextDouble() * 32;
      final angle = rng.nextDouble() * 0.6 - 0.3;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: sz, height: sz),
        const Radius.circular(8),
      );
      canvas.drawRRect(rr, paint);
      canvas.restore();
    }

    // Subtle sparkle dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter _) => false;
}

class _ChatBackground extends StatelessWidget {
  final Widget child;
  const _ChatBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCE93D8), Color(0xFFAB47BC)],
          ),
        ),
      ),
      Positioned.fill(child: CustomPaint(painter: _BgPainter())),
      child,
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  TOP BAR
// ═══════════════════════════════════════════════════════════

class _RoomTopBar extends StatelessWidget {
  final String roomName;
  final bool isMuted;
  final String elapsed;
  final bool chatTabActive;
  final VoidCallback onRoomTap;
  final VoidCallback onMembersTap;
  final VoidCallback onChatTap;
  final VoidCallback onMenuTap;

  const _RoomTopBar({
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
      color: _C.purpleHeader,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── Room name pill (mic + timer) ──────────────────
            GestureDetector(
              onTap: onRoomTap,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 160),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        roomName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      elapsed,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Members icon ──────────────────────────────────
            _TopBtn(
              icon: Icons.people_alt_outlined,
              active: !chatTabActive,
              onTap: onMembersTap,
            ),
            const SizedBox(width: 2),

            // ── Chat icon ─────────────────────────────────────
            _TopBtn(
              icon: Icons.chat_bubble_outline,
              active: chatTabActive,
              onTap: onChatTap,
            ),
            const SizedBox(width: 2),

            // ── Hamburger ─────────────────────────────────────
            _TopBtn(
              icon: Icons.menu,
              active: false,
              onTap: onMenuTap,
            ),
          ],
        ),
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
          width: 40,
          height: 36,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: active ? _C.purple : Colors.white,
            size: 22,
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  DROPDOWN MENU  (matches img 6: dark panel from top-right)
//  Items: الحالة / الاعدادات / اضف للمفضلة / مسح النص / تبليغ / خروج
// ═══════════════════════════════════════════════════════════

class _DropdownMenu extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onStatus;
  final VoidCallback onSettings;
  final VoidCallback onFavorite;
  final VoidCallback onClearChat;
  final VoidCallback onReport;
  final VoidCallback onLeave;

  const _DropdownMenu({
    required this.onClose,
    required this.onStatus,
    required this.onSettings,
    required this.onFavorite,
    required this.onClearChat,
    required this.onReport,
    required this.onLeave,
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
        onTap: () {}, // prevent dismiss on menu tap
        child: Container(
          margin: const EdgeInsets.only(top: 58, right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ],
          ),
          width: 170,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((e) {
              final isLast = e == items.last;
              return InkWell(
                onTap: () {
                  onClose();
                  e.$2();
                },
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(10))
                    : BorderRadius.zero,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ))
                        : null,
                  ),
                  child: Text(
                    e.$1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LEAVE ROOM DIALOG  (matches img 1: "هل تريد مغادرة الغرفة؟")
// ═══════════════════════════════════════════════════════════

Future<bool?> showLeaveDialog(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'هل تريد مغادرة الغرفة ؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(100, 42),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(100, 42),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );

// ═══════════════════════════════════════════════════════════
//  CHAT MESSAGE TILE
//  Layout (RTL):  Avatar | RankBar | White bubble
//  Bubble header: time (left) — Username (right)
//  Bubble body:   message text (RTL)
// ═══════════════════════════════════════════════════════════

class _SystemTile extends StatelessWidget {
  final String content;
  const _SystemTile({required this.content});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        child: Center(
          child: Text(
            content,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
      );
}

class _MsgTile extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback? onLongPress;

  const _MsgTile({required this.msg, this.onLongPress});

  String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (msg.type == MessageType.system) {
      return _SystemTile(content: msg.content);
    }

    final maxW = MediaQuery.of(context).size.width * 0.78;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.purple.shade200,
              backgroundImage: msg.avatarUrl != null && msg.avatarUrl!.isNotEmpty
                  ? NetworkImage(msg.avatarUrl!)
                  : null,
              child: msg.avatarUrl == null || msg.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 4),

            // Rank bar (left vertical stripe)
            Container(
              width: 3,
              height: 52,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: msg.rankColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),

            // White bubble
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row: time | spacer | username
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmt(msg.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          msg.username,
                          style: TextStyle(
                            color: msg.nameColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Message body
                    msg.isDeleted
                        ? Text(
                            'تم الحذف~',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Text(
                            msg.content,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF212121),
                              height: 1.4,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MEMBERS PANEL  (matches img 3 — white bg, avatar, icon)
// ═══════════════════════════════════════════════════════════

class _MembersPanel extends StatelessWidget {
  final List<RoomMember> members;
  final VoidCallback onBackToChat;

  const _MembersPanel({required this.members, required this.onBackToChat});

  @override
  Widget build(BuildContext context) {
    // "All" item at top (العودة الى الدردشة العامة)
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // All / back row
          InkWell(
            onTap: onBackToChat,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt, color: Colors.grey.shade600, size: 26),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        'العودة الى الدردشة العامة.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Members list
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (_, i) => _MemberRow(member: members[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final RoomMember member;
  const _MemberRow({required this.member});

  IconData _statusIcon(MemberStatus s) {
    switch (s) {
      case MemberStatus.speaking:  return Icons.mic;
      case MemberStatus.muted:     return Icons.mic_off;
      case MemberStatus.handRaised: return Icons.front_hand;
    }
  }

  Color _statusColor(MemberStatus s) {
    switch (s) {
      case MemberStatus.speaking:  return Colors.green;
      case MemberStatus.muted:     return Colors.grey;
      case MemberStatus.handRaised: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.purple.shade100,
                backgroundImage: member.avatarUrl != null &&
                        member.avatarUrl!.isNotEmpty
                    ? NetworkImage(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                    ? Icon(Icons.person, color: Colors.purple.shade400)
                    : null,
              ),
              if (member.isBanned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove,
                        color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Name + rank icon
          Expanded(
            child: Text(
              member.username,
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: member.rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Status mic icon
          Icon(
            _statusIcon(member.status),
            color: _statusColor(member.status),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EMOJI PICKER  (matches img 7/9/11)
//  Categories: custom emojis row + grid of emojis
// ═══════════════════════════════════════════════════════════

class _EmojiPicker extends StatefulWidget {
  final void Function(String emoji) onEmojiSelected;

  const _EmojiPicker({required this.onEmojiSelected});

  @override
  State<_EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<_EmojiPicker> {
  int _tabIndex = 0;

  static const List<List<String>> _categories = [
    // Faces
    [
      '😀','😃','😄','😁','😆','😅','🤣','🤗',
      '😉','😍','🥰','😘','😗','😙','😚','😋',
      '😛','🤪','😝','🤑','🤔','🤨','😐','😑',
      '😶','🙄','😏','😒','😞','😔','😟','😕',
      '🙁','☹️','😣','😖','😫','😩','🥺','😢',
      '😭','😤','😠','😡','🤬','🤯','😳','🥵',
      '🥶','😱','😨','😰','😥','😓','🤗','🤭',
    ],
    // Animals
    [
      '🐱','😸','😹','😻','😺','😼','😽','🙀',
      '😿','😾','🐶','🐱','🐭','🐹','🐰','🦊',
      '🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸',
      '🐵','🙈','🙉','🙊','🐔','🐧','🐦','🦆',
      '🐧','🦅','🦉','🦇','🐺','🐗','🐴','🦄',
      '🐝','🐛','🦋','🐌','🐞','🐜','🦟','🦗',
      '🕷','🦂','🐢','🐍','🦎','🦖','🦕','🐙',
      '🦑','🦐','🦞','🦀','🐡','🐠','🐟','🐬',
    ],
    // Hands/gestures
    [
      '👋','🤚','🖐','✋','🖖','👌','🤌','🤏',
      '✌️','🤞','🤟','🤘','🤙','👈','👉','👆',
      '🖕','👇','☝️','👍','👎','✊','👊','🤛',
      '🤜','👏','🙌','👐','🤲','🤝','🙏','✍️',
      '💪','🦾','🦵','🦶','👂','🦻','👃','🫀',
    ],
    // Hearts
    [
      '❤️','🧡','💛','💚','💙','💜','🖤','🤍',
      '🤎','💔','❣️','💕','💞','💓','💗','💖',
      '💝','💘','💟','☮️','✝️','☪️','🕉','☯️',
    ],
    // Other
    [
      '💡','🔦','🕯','🪔','💰','💴','💵','💶',
      '💷','💸','💳','🪙','💹','📈','📉','📊',
      '📋','📌','📍','📎','🖇','📐','📏','✂️',
    ],
  ];

  static const List<String> _quickEmojis = ['😀', '👋', '❤️', '💡'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 260,
      child: Column(
        children: [
          // Quick emoji / category tabs row
          Container(
            height: 44,
            color: Colors.grey.shade100,
            child: Row(
              children: [
                // Quick emoji buttons
                ..._quickEmojis.map((e) => GestureDetector(
                      onTap: () => widget.onEmojiSelected(e),
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    )),
                // Category tabs
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final icons = [
                        Icons.emoji_emotions_outlined,
                        Icons.pets,
                        Icons.waving_hand,
                        Icons.favorite_outline,
                        Icons.lightbulb_outline,
                      ];
                      return GestureDetector(
                        onTap: () => setState(() => _tabIndex = i),
                        child: Container(
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: _tabIndex == i
                                ? Border(
                                    bottom: BorderSide(
                                      color: _C.purple,
                                      width: 2,
                                    ))
                                : null,
                          ),
                          child: Icon(
                            icons[i],
                            size: 20,
                            color: _tabIndex == i
                                ? _C.purple
                                : Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
              ),
              itemCount: _categories[_tabIndex].length,
              itemBuilder: (_, i) {
                final em = _categories[_tabIndex][i];
                return GestureDetector(
                  onTap: () => widget.onEmojiSelected(em),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(em, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MEDIA OPTIONS  (matches img 7: ارسال صورة / كاميرا / فيديو)
// ═══════════════════════════════════════════════════════════

void _showMediaSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MediaOption(
            icon: Icons.photo_library,
            label: 'ارسال صورة',
            onTap: () => Navigator.pop(context),
          ),
          _MediaOption(
            icon: Icons.camera_alt,
            label: 'كاميرا',
            onTap: () => Navigator.pop(context),
          ),
          _MediaOption(
            icon: Icons.videocam,
            label: 'فيديو',
            iconColor: const Color(0xFFE91E8C),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon,
                  color: iconColor ?? Colors.grey.shade700, size: 28),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF424242)),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  INPUT BAR  (matches img: purple bar with mic/•••/field/emoji/send)
// ═══════════════════════════════════════════════════════════

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isMuted;
  final bool showEmoji;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onEmojiToggle;
  final VoidCallback onMediaTap;

  const _InputBar({
    required this.controller,
    required this.isMuted,
    required this.showEmoji,
    required this.onSend,
    required this.onMicToggle,
    required this.onEmojiToggle,
    required this.onMediaTap,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
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
      color: _C.purple,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(
        children: [
          // Mic button
          _Ico(
            icon: widget.isMuted ? Icons.mic_off : Icons.mic,
            color: widget.isMuted ? Colors.redAccent : Colors.white,
            onTap: widget.onMicToggle,
          ),
          const SizedBox(width: 4),

          // More options (•••)
          _Ico(
            icon: Icons.more_horiz,
            color: Colors.white,
            onTap: widget.onMediaTap,
          ),
          const SizedBox(width: 6),

          // Text field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: widget.controller,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  // Show keyboard icon when emoji is showing
                  suffixIcon: widget.showEmoji
                      ? GestureDetector(
                          onTap: widget.onEmojiToggle,
                          child: const Icon(Icons.keyboard,
                              color: Colors.grey, size: 20),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Emoji button (or send)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _hasText
                ? _Ico(
                    key: const ValueKey('send'),
                    icon: Icons.send,
                    color: Colors.white,
                    onTap: widget.onSend,
                  )
                : _Ico(
                    key: const ValueKey('emoji'),
                    icon: Icons.emoji_emotions_outlined,
                    color: Colors.amber,
                    onTap: widget.onEmojiToggle,
                  ),
          ),

          // Hand raise (always visible when no text)
          if (!_hasText) ...[
            const SizedBox(width: 4),
            _Ico(
              icon: Icons.front_hand_outlined,
              color: Colors.white,
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _Ico extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Ico({super.key, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: color, size: 22),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
//  PRIVATE MESSAGES PANEL  (matches img 4: "All" + list)
// ═══════════════════════════════════════════════════════════

class _PrivateMsgRow {
  final String name;
  final String preview;
  final int unread;
  final Color nameColor;
  _PrivateMsgRow(this.name, this.preview, this.unread, this.nameColor);
}

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  // ── UI state ───────────────────────────────────────────
  bool _chatTabActive = true; // false → members panel
  bool _isMuted = false;
  bool _showMenu = false;
  bool _showEmoji = false;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ── Timer ──────────────────────────────────────────────
  late Timer _timer;
  int _elapsedSeconds = 0;

  // ── Data ──────────────────────────────────────────────
  late List<ChatMessage> _messages;
  late List<RoomMember> _members;

  // ── Init ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _messages = _buildDemoMessages();
    _members = _buildDemoMembers();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _elapsedSeconds++),
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
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────
  String get _elapsed {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'me',
        username: 'أنا',
        content: text,
        timestamp: DateTime.now(),
        nameColor: _C.rankAdmin,
        rankColor: _C.rankAdmin,
      ));
    });
    _inputCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onEmojiSelected(String emoji) {
    final cur = _inputCtrl.value;
    final sel = cur.selection;
    final text = sel.isValid
        ? cur.text.replaceRange(sel.start, sel.end, emoji)
        : cur.text + emoji;
    _inputCtrl.value = cur.copyWith(
      text: text,
      selection: TextSelection.collapsed(
        offset: sel.isValid ? sel.start + emoji.length : text.length,
      ),
    );
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _showEmoji = true);
      });
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () {
            if (_showMenu) setState(() => _showMenu = false);
            if (_showEmoji) setState(() => _showEmoji = false);
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── Background + content column ───────────
              _ChatBackground(
                child: Column(
                  children: [
                    // TOP BAR
                    _RoomTopBar(
                      roomName: widget.roomName,
                      isMuted: _isMuted,
                      elapsed: _elapsed,
                      chatTabActive: _chatTabActive,
                      onRoomTap: () =>
                          setState(() => _isMuted = !_isMuted),
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

                    // CONTENT AREA
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _chatTabActive
                            ? _buildChatList()
                            : _MembersPanel(
                                members: _members,
                                onBackToChat: () => setState(
                                    () => _chatTabActive = true),
                              ),
                      ),
                    ),

                    // INPUT BAR
                    _InputBar(
                      controller: _inputCtrl,
                      isMuted: _isMuted,
                      showEmoji: _showEmoji,
                      onSend: _send,
                      onMicToggle: () =>
                          setState(() => _isMuted = !_isMuted),
                      onEmojiToggle: _toggleEmoji,
                      onMediaTap: () => _showMediaSheet(context),
                    ),

                    // EMOJI PICKER (above keyboard)
                    if (_showEmoji)
                      _EmojiPicker(onEmojiSelected: _onEmojiSelected),
                  ],
                ),
              ),

              // ── Dropdown menu overlay ─────────────────
              if (_showMenu)
                Positioned.fill(
                  child: _DropdownMenu(
                    onClose: () =>
                        setState(() => _showMenu = false),
                    onStatus: () {},
                    onSettings: () {},
                    onFavorite: () {},
                    onClearChat: () =>
                        setState(() => _messages.clear()),
                    onReport: () {},
                    onLeave: () async {
                      final leave = await showLeaveDialog(context);
                      if (leave == true && context.mounted) {
                        Navigator.maybePop(context);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return _ChatBackground(
        child: const Center(
          child: Text(
            'لا توجد رسائل بعد',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey('chat'),
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MsgTile(
        msg: _messages[i],
        onLongPress: () => _showMsgOptions(_messages[i], i),
      ),
    );
  }

  void _showMsgOptions(ChatMessage msg, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          if (msg.userId == 'me') ...[
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف الرسالة',
                  textDirection: TextDirection.rtl),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages[index] = ChatMessage(
                    id: msg.id,
                    userId: msg.userId,
                    username: msg.username,
                    content: msg.content,
                    timestamp: msg.timestamp,
                    nameColor: msg.nameColor,
                    rankColor: msg.rankColor,
                    isDeleted: true,
                  );
                });
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('نسخ', textDirection: TextDirection.rtl),
            onTap: () {
              Clipboard.setData(ClipboardData(text: msg.content));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Demo data ─────────────────────────────────────────
  List<ChatMessage> _buildDemoMessages() {
    final now = DateTime.now();
    return [
      // Welcome card
      ChatMessage(
        id: 'welcome',
        userId: 'sys-welcome',
        username: 'System',
        content:
            'أهلاً وسهلاً بكم،\nفوجودكم هو فخر واعتزاز وسعادة لنا.\nبمجرد وصولكم، تغمرنا السعادة والفرح.\n❤️kk❤️',
        timestamp: now.subtract(const Duration(minutes: 30)),
        type: MessageType.system,
        nameColor: Colors.black,
        rankColor: Colors.transparent,
      ),
      // Join event
      ChatMessage(
        id: 'join1',
        userId: 'sys-join',
        username: 'System',
        content: 'انضم الى الغرفة FáRiD',
        timestamp: now.subtract(const Duration(minutes: 20)),
        type: MessageType.system,
        nameColor: const Color(0xFF2E7D32),
        rankColor: Colors.transparent,
      ),
      ChatMessage(
        id: '1',
        userId: 'u1',
        username: '»•١٠•مـداهـم•٢«🌟',
        content: 'انا وخير',
        timestamp: now.subtract(const Duration(minutes: 11)),
        nameColor: const Color(0xFFFF6F00),
        rankColor: const Color(0xFFFFB300),
      ),
      ChatMessage(
        id: '2',
        userId: 'u1',
        username: '»•١٠•مـداهـم•٢«🌟',
        content: '😂😂😂😂😂',
        timestamp: now.subtract(const Duration(minutes: 11)),
        nameColor: const Color(0xFFFF6F00),
        rankColor: const Color(0xFFFFB300),
      ),
      ChatMessage(
        id: '3',
        userId: 'u2',
        username: 'عثمان بيه',
        content: '🖐 سامح،',
        timestamp: now.subtract(const Duration(minutes: 11)),
        nameColor: const Color(0xFF1565C0),
        rankColor: const Color(0xFF42A5F5),
      ),
      ChatMessage(
        id: '4',
        userId: 'u3',
        username: 'ع ـ\u0027آآلي المـ\u0027زآآج',
        content: 'ولع ولع',
        timestamp: now.subtract(const Duration(minutes: 11)),
        nameColor: const Color(0xFF8B4513),
        rankColor: const Color(0xFF9E9E9E),
      ),
      ChatMessage(
        id: '5',
        userId: 'u1',
        username: '»•١٠•مـداهـم•٢«🌟',
        content: 'الله يسمحك',
        timestamp: now.subtract(const Duration(minutes: 11)),
        nameColor: const Color(0xFFFF6F00),
        rankColor: const Color(0xFFFFB300),
      ),
      ChatMessage(
        id: '6',
        userId: 'u4',
        username: 'Prada',
        content: 'كاكا ولكم',
        timestamp: now.subtract(const Duration(minutes: 11)),
        nameColor: const Color(0xFF2E7D32),
        rankColor: const Color(0xFF9E9E9E),
      ),
    ];
  }

  List<RoomMember> _buildDemoMembers() => [
        const RoomMember(
          userId: 'm1',
          username: 'سامح',
          role: 'master',
          status: MemberStatus.speaking,
          rankColor: _C.rankMaster,
        ),
        RoomMember(
          userId: 'm2',
          username: '»•١٠•مـداهـم•٢«',
          role: 'admin',
          status: MemberStatus.muted,
          rankColor: _C.rankAdmin,
        ),
        const RoomMember(
          userId: 'm3',
          username: 'Prada',
          role: 'member',
          status: MemberStatus.muted,
          rankColor: _C.rankMember,
        ),
        const RoomMember(
          userId: 'm4',
          username: '»عيونك آحلي صدفة«١»',
          role: 'member',
          status: MemberStatus.handRaised,
          rankColor: _C.rankMember,
        ),
        RoomMember(
          userId: 'm5',
          username: 'ع ـ\u0027آآلي المـ\u0027زآآج',
          role: 'guest',
          status: MemberStatus.muted,
          rankColor: _C.rankGuest,
          isBanned: true,
        ),
      ];
}
