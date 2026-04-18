// lib/screens/inbox_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import 'private_chat_screen.dart';

int _lastTsMs(Map<String, dynamic> data) {
  final ts = data['lastTimestamp'];
  if (ts is Timestamp) return ts.millisecondsSinceEpoch;
  if (ts is int) return ts;
  return 0;
}

/// للواجهة وشارة غير المقروء في اللوبي.
bool dmThreadIsUnread(Map<String, dynamic> data, String myId) {
  final lastMs = _lastTsMs(data);
  final readAt = Map<String, dynamic>.from(data['readAt'] ?? {});
  final myRead = (readAt[myId] as num?)?.toInt() ?? 0;
  final lastSender = data['lastSenderId'] as String?;
  return lastSender != null && lastSender != myId && lastMs > myRead;
}

class InboxScreen extends StatefulWidget {
  final ChatUser me;
  const InboxScreen({super.key, required this.me});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _svc = FirebaseService();

  ChatUser _peerFromDoc(String chatId, Map<String, dynamic> data) {
    final parts = List<String>.from(data['participants'] ?? []);
    final otherId = parts.firstWhere((id) => id != widget.me.id, orElse: () => '');
    final users = Map<String, dynamic>.from(data['users'] ?? {});
    final u = Map<String, dynamic>.from(users[otherId] ?? {});
    return ChatUser(
      id: otherId.isEmpty ? chatId : otherId,
      name: u['name']?.toString() ?? 'مجهول',
      avatar: u['avatar']?.toString(),
      role: UserRole.guest,
      joinedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lobbyBg,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        elevation: 0,
        title: const Text('الرسائل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _svc.inboxStream(widget.me.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل المحادثات.\nقد تحتاج فهرس Firestore: participants + lastTimestamp\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(
              child: Text('لا توجد محادثات بعد',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.grey)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final row = rows[i];
              final id = row['id'] as String? ?? '';
              final peer = _peerFromDoc(id, row);
              final unread = dmThreadIsUnread(row, widget.me.id);
              final last = row['lastMessage']?.toString() ?? '';
              return ListTile(
                tileColor: Colors.white,
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundImage: peer.avatar != null ? NetworkImage(peer.avatar!) : null,
                      child: peer.avatar == null ? const Icon(Icons.person) : null,
                    ),
                    if (unread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                title: Text(peer.name,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                  )),
                subtitle: Text(last,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PrivateChatScreen(currentUser: widget.me, peerUser: peer),
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
