// lib/screens/private_chat_screen.dart
// محادثة خاصة — نفس مسار Firestore: private_chats / messages
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class PrivateChatScreen extends StatefulWidget {
  final ChatUser currentUser;
  final ChatUser peerUser;

  const PrivateChatScreen({
    super.key,
    required this.currentUser,
    required this.peerUser,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _svc = FirebaseService();
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<List<ChatMsg>>? _sub;
  List<ChatMsg> _msgs = [];
  bool _sending = false;

  String get _chatId => _svc.dmId(widget.currentUser.id, widget.peerUser.id);

  @override
  void initState() {
    super.initState();
    _sub = _svc.dmStream(_chatId).listen((m) {
      if (mounted) setState(() => _msgs = m);
      _scrollBottom();
    });
    _svc.markDmRead(_chatId, widget.currentUser.id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sid = widget.currentUser.id;
      final rid = widget.peerUser.id;
      await _svc.sendDm(
        _chatId,
        {
          'senderId': sid,
          'senderName': widget.currentUser.name,
          'senderAvatar': widget.currentUser.avatar,
          'senderRole': widget.currentUser.role.fsValue,
          'text': text,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        sid: sid,
        rid: rid,
        sName: widget.currentUser.name,
        rName: widget.peerUser.name,
        rAvatar: widget.peerUser.avatar,
        sAvatar: widget.currentUser.avatar,
      );
      _msgCtrl.clear();
      await _svc.markDmRead(_chatId, sid);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الإرسال', style: TextStyle(fontFamily: 'Cairo'))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        elevation: 0,
        title: Text(widget.peerUser.name,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final msg = _msgs[i];
                final mine = msg.senderId == widget.currentUser.id;
                return Align(
                  alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFFE8FBF5) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!mine)
                          Text(msg.senderName,
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal)),
                        if (msg.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(msg.imageUrl!, width: 160, fit: BoxFit.cover),
                          ),
                        if (msg.text != null && msg.text!.isNotEmpty)
                          Text(msg.text!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 10, right: 10, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة…',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
