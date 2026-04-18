import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared_widgets.dart';

class RoomChatSheet extends StatefulWidget {
  final String roomId;
  const RoomChatSheet({super.key, required this.roomId});

  @override State<RoomChatSheet> createState() => _RoomChatSheetState();
}

class _RoomChatSheetState extends State<RoomChatSheet> {
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  void _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;
    
    setState(() => _isSending = true);
    final profile = context.read<AuthProvider>().profile!;
    try {
      await FirestoreService.instance.sendRoomMessage(widget.roomId, profile, text: txt);
      _msgCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().profile?.uid ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 5, decoration: BoxDecoration(
          color: AppColors.borderDefault, borderRadius: BorderRadius.circular(3),
        )),
        const SizedBox(height: 12),
        const Text('الدردشة الكتابية', style: TextStyle(
          color: AppColors.textPrimary, fontSize: 16,
          fontWeight: FontWeight.bold, fontFamily: 'Cairo',
        )),
        const Divider(color: AppColors.borderDefault),
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: FirestoreService.instance.listenToRoomMessages(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Text('لا توجد رسائل بعد.\nكن أول من يشارك!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 13),
                  )
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == myUid;
                  return _MessageBubble(msg: msg, isMe: isMe);
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(top: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: AppColors.bgTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _send,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(imageUrl: msg.senderPhoto, name: msg.senderName, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.bgTertiary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(msg.senderName, style: const TextStyle(
                      color: AppColors.primaryMuted, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo',
                    )),
                    const SizedBox(height: 2),
                  ],
                  Text(msg.text, style: const TextStyle(
                    color: AppColors.white, fontSize: 14, fontFamily: 'Cairo',
                  )),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8) else const SizedBox(width: 28),
        ],
      ),
    );
  }
}
