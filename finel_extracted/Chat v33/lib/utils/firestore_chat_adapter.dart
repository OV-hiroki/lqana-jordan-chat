// ─────────────────────────────────────────────
//  FirestoreChatAdapter
//
//  Paste this into your existing chat provider /
//  repository.  It converts a Firestore snapshot
//  into the List<ChatMessage> the new UI needs.
// ─────────────────────────────────────────────
//
//  USAGE IN YOUR PROVIDER / REPOSITORY:
//
//    Stream<List<ChatMessage>> messagesStream(String roomId) {
//      return FirebaseFirestore.instance
//          .collection('rooms')
//          .doc(roomId)
//          .collection('messages')
//          .orderBy('timestamp', descending: false)
//          .snapshots()
//          .map(FirestoreChatAdapter.fromSnapshot);
//    }
//
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../utils/chat_color_utils.dart';
import 'package:flutter/material.dart';

class FirestoreChatAdapter {
  FirestoreChatAdapter._();

  /// Map a Firestore QuerySnapshot → List<ChatMessage>
  static List<ChatMessage> fromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map(_fromDoc).toList();
  }

  static ChatMessage _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final isSystem = (data['type'] as String?) == 'system';
    final userId = (data['userId'] as String?) ?? '';
    final role = (data['role'] as String?) ?? 'guest';

    final colors = ChatColorUtils.colorsForUser(
      userId: userId,
      role: role,
    );

    return ChatMessage(
      id: doc.id,
      userId: userId,
      username: (data['username'] as String?) ?? 'مجهول',
      avatarUrl: data['avatarUrl'] as String?,
      content: (data['content'] as String?) ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: isSystem ? MessageType.system : MessageType.text,
      nameColor: colors.nameColor,
      rankColor: colors.rankColor,
    );
  }
}

// ─────────────────────────────────────────────
//  FIRESTORE DOCUMENT SHAPE (for reference)
// ─────────────────────────────────────────────
//
//  Collection: rooms/{roomId}/messages/{msgId}
//  {
//    "userId":    "uid_abc123",
//    "username":  "Kiro",
//    "avatarUrl": "https://...",   // optional
//    "content":   "أهلاً بالجميع",
//    "role":      "admin",         // master | superadmin | admin | member | guest
//    "type":      "text",          // text | system
//    "timestamp": Timestamp,
//  }
