// ============================================================
// Private Chat Overlay — v31
// نافذة دردشة خاصة متراكبة داخل غرفة الصوت
// ============================================================

import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';

class PrivateChatOverlay extends StatefulWidget {
  final String roomId;
  final String myUid;
  final String myName;
  final String otherUid;
  final String otherName;
  final VoidCallback onClose;

  const PrivateChatOverlay({
    super.key,
    required this.roomId,
    required this.myUid,
    required this.myName,
    required this.otherUid,
    required this.otherName,
    required this.onClose,
  });

  @override
  State<PrivateChatOverlay> createState() => _PrivateChatOverlayState();
}

class _PrivateChatOverlayState extends State<PrivateChatOverlay>
    with SingleTickerProviderStateMixin {
  final _msgCtrl      = TextEditingController();
  final _scrollCtrl   = ScrollController();
  late AnimationController _animCtrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;
    FirestoreService.instance.sendPrivateMessage(
      widget.roomId,
      fromUid:  widget.myUid,
      fromName: widget.myName,
      toUid:    widget.otherUid,
      text:     txt,
    );
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _close() async {
    await _animCtrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final overlayH = screenH * 0.45;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _slide,
        child: Container(
          height: overlayH,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1630),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          child: Column(children: [
            // ── Header ─────────────────────────────────────
            _buildHeader(),

            // ── Messages ───────────────────────────────────
            Expanded(child: _buildMessages()),

            // ── Input ──────────────────────────────────────
            _buildInput(),
          ]),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF7B1FA2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Row(children: [
          // Close
          GestureDetector(
            onTap: _close,
            child: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white70, size: 26),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF4A148C),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(
                widget.otherName.isNotEmpty
                    ? widget.otherName[0].toUpperCase()
                    : '؟',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + label
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.otherName,
                  style: const TextStyle(fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const Text('محادثة خاصة',
                  style: TextStyle(fontFamily: 'Cairo',
                      color: Colors.white60, fontSize: 11)),
            ]),
          ),

          // Lock icon
          const Icon(Icons.lock_outline, color: Colors.white60, size: 16),
        ]),
      );

  // ── Messages stream ───────────────────────────────────────
  Widget _buildMessages() => StreamBuilder<List<MessageModel>>(
        stream: FirestoreService.instance.listenToPrivateMessages(
          widget.roomId, widget.myUid, widget.otherUid),
        builder: (context, snapshot) {
          final msgs = snapshot.data ?? [];

          // Auto-scroll
          if (msgs.isNotEmpty) _scrollToBottom();

          if (msgs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_outline, size: 40,
                    color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                const Text('ابدأ المحادثة الخاصة',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white24,
                        fontSize: 13)),
              ]),
            );
          }

          return ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              final isMe = m.senderId == widget.myUid;
              return _PrivateMsg(msg: m, isMe: isMe);
            },
          );
        },
      );

  // ── Input bar ─────────────────────────────────────────────
  Widget _buildInput() => Container(
        padding: EdgeInsets.fromLTRB(
            12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 10),
        color: const Color(0xFF120F25),
        child: Row(children: [
          // Text field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF251F40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3D3358)),
              ),
              child: TextField(
                controller: _msgCtrl,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                    color: Colors.white),
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.white38,
                      fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFF7B1FA2), shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// Private message bubble
// ─────────────────────────────────────────────────────────────
class _PrivateMsg extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _PrivateMsg({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF4A148C),
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '؟',
                style: const TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF7B1FA2)
                  : const Color(0xFF251F40),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              if (!isMe)
                Text(msg.senderName,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                        color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
              Text(msg.text,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                      color: Colors.white)),
            ]),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}
