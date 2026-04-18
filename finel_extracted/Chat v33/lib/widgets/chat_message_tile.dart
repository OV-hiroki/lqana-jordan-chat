import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/chat_message_model.dart';

// ─────────────────────────────────────────────
//  1.  SYSTEM MESSAGE WIDGET
//      Centered · transparent · green bold text
// ─────────────────────────────────────────────

class SystemMessageTile extends StatelessWidget {
  final ChatMessage message;

  const SystemMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Center(
        child: Text(
          message.content,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: Color(0xFF2E7D32), // green[800]
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  2.  CHAT MESSAGE TILE  (Lgana / Wolf style)
//      • Always left-aligned (CrossAxisAlignment.start)
//      • CircleAvatar on far left
//      • Thin vertical rank bar
//      • White bubble — name + timestamp header, then body
// ─────────────────────────────────────────────

class ChatMessageTile extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageTile({super.key, required this.message});

  // Format "02:50 م"  using the device locale
  String _formatTime(DateTime dt) {
    // Uses Arabic am/pm when device locale is Arabic; falls back gracefully.
    return DateFormat('hh:mm a', 'ar').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return SystemMessageTile(message: message);
    }

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ───────────────────────────────────
          _Avatar(avatarUrl: message.avatarUrl, username: message.username),

          const SizedBox(width: 6),

          // ── Rank indicator bar ────────────────────────
          _RankBar(color: message.rankColor),

          const SizedBox(width: 8),

          // ── Message bubble ────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: _Bubble(message: message, formatTime: _formatTime),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRIVATE SUB-WIDGETS
// ─────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;

  const _Avatar({required this.avatarUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.purple.shade200,
      backgroundImage:
          avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
      child:
          (avatarUrl == null || avatarUrl!.isEmpty)
              ? Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
              : null,
    );
  }
}

class _RankBar extends StatelessWidget {
  final Color color;

  const _RankBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 52, // aligns nicely with a two-line bubble
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final String Function(DateTime) formatTime;

  const _Bubble({required this.message, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: name + timestamp ──────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.username,
                style: TextStyle(
                  color: message.nameColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 12),
              Text(
                formatTime(message.timestamp),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // ── Body ──────────────────────────────────────
          Text(
            message.content,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF212121),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
