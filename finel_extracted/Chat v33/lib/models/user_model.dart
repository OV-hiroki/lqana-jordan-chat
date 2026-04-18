// ============================================================
// Jordan Audio Forum — User Model
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String bio;
  final bool isAdmin;
  final bool isBanned;
  final int followersCount;
  final int followingCount;
  final int roomsHosted;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.bio = '',
    this.isAdmin = false,
    this.isBanned = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.roomsHosted = 0,
    this.createdAt,
  });

  // ✔ Admin determined ONLY via Firestore 'isAdmin' field — no hardcoded UIDs
  bool get isAdminUser => isAdmin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:            doc.id,
      email:          data['email'] ?? '',
      displayName:    data['displayName'] ?? '',
      photoURL:       data['photoURL'],
      bio:            data['bio'] ?? '',
      isAdmin:        data['isAdmin'] ?? false,
      isBanned:       data['isBanned'] ?? false,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      roomsHosted:    data['roomsHosted'] ?? 0,
      createdAt:      (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid':            uid,
    'email':          email,
    'displayName':    displayName,
    'photoURL':       photoURL,
    'bio':            bio,
    'isAdmin':        isAdmin,
    'isBanned':       isBanned,
    'followersCount': followersCount,
    'followingCount': followingCount,
    'roomsHosted':    roomsHosted,
    'createdAt':      FieldValue.serverTimestamp(),
    'updatedAt':      FieldValue.serverTimestamp(),
  };

  UserModel copyWith({
    String? displayName, String? photoURL, String? bio,
    bool? isAdmin, bool? isBanned,
  }) => UserModel(
    uid: uid, email: email,
    displayName: displayName ?? this.displayName,
    photoURL: photoURL ?? this.photoURL,
    bio: bio ?? this.bio,
    isAdmin: isAdmin ?? this.isAdmin,
    isBanned: isBanned ?? this.isBanned,
    followersCount: followersCount,
    followingCount: followingCount,
    roomsHosted: roomsHosted,
    createdAt: createdAt,
  );
}
