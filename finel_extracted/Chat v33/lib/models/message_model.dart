import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.text,
    this.imageUrl,
    this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id:          doc.id,
      senderId:    d['senderId'] ?? '',
      senderName:  d['senderName'] ?? 'مجهول',
      senderPhoto: d['senderPhoto'],
      text:        d['text'] ?? '',
      imageUrl:    d['imageUrl'] as String?,
      createdAt:   (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId':    senderId,
    'senderName':  senderName,
    'senderPhoto': senderPhoto,
    'text':        text,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'createdAt':   FieldValue.serverTimestamp(),
  };
}
