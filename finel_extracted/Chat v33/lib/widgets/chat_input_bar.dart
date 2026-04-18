import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ChatInputBar
//  Rounded white TextField with:
//    • Mic toggle on the left
//    • Options (⋯) button
//    • Emoji picker toggle
//    • Send button on the right
// ─────────────────────────────────────────────

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onEmojiToggle;
  final VoidCallback onOptionsToggle;
  final bool isMuted;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMicToggle,
    required this.onEmojiToggle,
    required this.onOptionsToggle,
    this.isMuted = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Row(
        children: [
          // ── Mic button ────────────────────────────────
          _CircleIconButton(
            icon: widget.isMuted ? Icons.mic_off : Icons.mic,
            color:
                widget.isMuted
                    ? Colors.red.shade400
                    : const Color(0xFF7B1FA2),
            onTap: widget.onMicToggle,
          ),

          const SizedBox(width: 6),

          // ── Options (⋯) ───────────────────────────────
          _CircleIconButton(
            icon: Icons.more_horiz,
            color: const Color(0xFF7B1FA2),
            onTap: widget.onOptionsToggle,
          ),

          const SizedBox(width: 8),

          // ── Text field ────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.amber),
                    onPressed: widget.onEmojiToggle,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Send button ───────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                _hasText
                    ? _CircleIconButton(
                        key: const ValueKey('send'),
                        icon: Icons.send,
                        color: const Color(0xFF7B1FA2),
                        onTap: widget.onSend,
                      )
                    : const SizedBox(width: 36),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
