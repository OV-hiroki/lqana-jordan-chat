import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/support_conversation_id.dart';
import '../../widgets/shared_widgets.dart';

// ─── واجهة المستخدم: محادثة دعم خاصة به ─────────────────────
class SupportChatSheet extends StatefulWidget {
  const SupportChatSheet({super.key});

  @override
  State<SupportChatSheet> createState() => _SupportChatSheetState();
}

class _SupportChatSheetState extends State<SupportChatSheet> {
  final _msgCtrl = TextEditingController();
  bool _isSending = false;
  String? _conversationId;
  Stream<List<MessageModel>>? _messagesStream;

  static String _privacyCaption(String? convId, String myUid) {
    if (convId == null) {
      return 'جاري فتح محادثة خاصة مع الدعم…';
    }
    if (convId != myUid) {
      return 'خيط خاص بهذا الجهاز — مستخدم أو جهاز آخر لا يرى نفس المحادثة.';
    }
    return 'محادثتك مع الإدارة مرتبطة بحسابك ولا تظهر لغيرك.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapThread());
  }

  Future<void> _bootstrapThread() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return;
    final id = await SupportConversationId.resolve(authUid: profile.uid);
    await FirestoreService.instance.ensureSupportConversationShell(
      conversationId: id,
      sender: profile,
    );
    if (!mounted) return;
    setState(() {
      _conversationId = id;
      _messagesStream =
          FirestoreService.instance.listenToSupportMessages(conversationId: id);
    });
  }

  void _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;

    final convId = _conversationId;
    if (convId == null) return;

    setState(() => _isSending = true);
    final profile = context.read<AuthProvider>().profile!;
    try {
      await FirestoreService.instance.sendSupportMessage(
        txt,
        profile,
        conversationId: convId,
      );
      _msgCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<AuthProvider>().profile;
    final myUid   = profile?.uid ?? '';
    final stream  = _messagesStream;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.headset_mic, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text('محادثة الدعم الفني', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 16,
            fontWeight: FontWeight.bold, fontFamily: 'Cairo',
          )),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            _privacyCaption(_conversationId, myUid),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
        ),
        const Divider(color: AppColors.borderDefault),
        Expanded(
          child: stream == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : StreamBuilder<List<MessageModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.support_agent, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'هنا يمكنك التواصل مع الإدارة\nسنجيبك في أقرب وقت!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ]),
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == myUid;
                  return _MessageBubble(msg: msg, isMe: isMe, isAdmin: !isMe);
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
                  hintText: 'اكتب رسالتك للإدارة...',
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
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: _isSending
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── واجهة مشرف الدعم: قائمة كل المحادثات ───────────────────
class SupportAdminInbox extends StatelessWidget {
  const SupportAdminInbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: const Row(children: [
          Icon(Icons.support_agent, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text('صندوق الدعم الفني', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.listenToAllSupportConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const Center(
              child: Text('لا توجد محادثات بعد', style: TextStyle(
                color: AppColors.textMuted, fontFamily: 'Cairo')),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.borderDefault, height: 1),
            itemBuilder: (_, i) {
              final conv = conversations[i];
              final unread = (conv['unreadByAdmin'] ?? 0) as int;
              final cid = conv['id'] as String? ?? '';
              final idTail = cid.length > 8 ? '…${cid.substring(cid.length - 8)}' : cid;
              return ListTile(
                isThreeLine: true,
                leading: Stack(children: [
                  UserAvatar(imageUrl: conv['userPhoto'], name: conv['userName'] ?? '?', size: 44),
                  if (unread > 0) Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Center(child: Text('$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ]),
                title: Text(conv['userName'] ?? '—', style: const TextStyle(
                    color: AppColors.textPrimary, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('خيط #$idTail', style: const TextStyle(
                      color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 10)),
                    Text(conv['lastMessage'] ?? '', style: const TextStyle(
                        color: AppColors.textMuted, fontFamily: 'Cairo', fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (unread > 0) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread رسالة', style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontFamily: 'Cairo')),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ]),
                onTap: () {
                  FirestoreService.instance.markSupportConversationRead(conv['id']);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SupportAdminConversation(
                      conversationId: conv['id'],
                      userName: conv['userName'] ?? '?',
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── واجهة المشرف: داخل محادثة واحدة ────────────────────────
class SupportAdminConversation extends StatefulWidget {
  final String conversationId;
  final String userName;
  const SupportAdminConversation({
    super.key,
    required this.conversationId,
    required this.userName,
  });

  @override
  State<SupportAdminConversation> createState() => _SupportAdminConversationState();
}

class _SupportAdminConversationState extends State<SupportAdminConversation> {
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  void _reply() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;

    setState(() => _isSending = true);
    final profile = context.read<AuthProvider>().profile!;
    try {
      await FirestoreService.instance.sendSupportReply(
        conversationId: widget.conversationId,
        text: txt,
        adminSender: profile,
      );
      _msgCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().profile?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgHeader,
        title: Text('محادثة مع ${widget.userName}',
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: FirestoreService.instance.listenToSupportMessages(
              conversationId: widget.conversationId),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const Center(child: Text('لا توجد رسائل',
                  style: TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo')));
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == myUid;
                  return _MessageBubble(msg: msg, isMe: isMe, isAdmin: isMe);
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
                  hintText: 'رد على ${widget.userName}...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: AppColors.bgTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                onSubmitted: (_) => _reply(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _reply,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: _isSending
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── فقاعة الرسالة ───────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final bool isAdmin;
  const _MessageBubble({required this.msg, required this.isMe, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Stack(children: [
              UserAvatar(imageUrl: msg.senderPhoto, name: msg.senderName, size: 28),
              if (isAdmin) Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
              ),
            ]),
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
                    Row(children: [
                      if (isAdmin) ...[
                        const Icon(Icons.verified, size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                      ],
                      Text(msg.senderName, style: TextStyle(
                        color: isAdmin ? AppColors.success : AppColors.primaryMuted,
                        fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo',
                      )),
                    ]),
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
