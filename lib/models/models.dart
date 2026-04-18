// lib/models/models.dart
import 'package:flutter/material.dart';

enum UserRole { guest, member, admin, superAdmin, master, root, sales }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.guest:      return 'زائر';
      case UserRole.member:     return 'عضو';
      case UserRole.admin:      return 'مشرف';
      case UserRole.superAdmin: return 'مشرف عام';
      case UserRole.master:     return 'ماستر';
      case UserRole.root:       return 'روت';
      case UserRole.sales:      return 'مبيعات';
    }
  }

  int get weight {
    switch (this) {
      case UserRole.guest:      return 0;
      case UserRole.member:     return 1;
      case UserRole.admin:      return 2;
      case UserRole.superAdmin: return 3;
      case UserRole.master:     return 4;
      case UserRole.root:       return 5;
      case UserRole.sales:      return 6;
    }
  }

  static UserRole fromString(String? s) {
    switch (s) {
      case 'Member':      return UserRole.member;
      case 'Admin':       return UserRole.admin;
      case 'SuperAdmin':
      case 'Super Admin': return UserRole.superAdmin;
      case 'Master':      return UserRole.master;
      case 'Root':        return UserRole.root;
      case 'Sales':       return UserRole.sales;
      default:            return UserRole.guest;
    }
  }

  String get fsValue {
    switch (this) {
      case UserRole.guest:      return 'Guest';
      case UserRole.member:     return 'Member';
      case UserRole.admin:      return 'Admin';
      case UserRole.superAdmin: return 'SuperAdmin';
      case UserRole.master:     return 'Master';
      case UserRole.root:       return 'Root';
      case UserRole.sales:      return 'Sales';
    }
  }
}

// ─── User Status ──────────────────────────────────────────────────────────────
enum UserStatus { available, away, busy, phone, driving, eating }

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.available: return 'متاح';
      case UserStatus.away:      return 'بالخارج';
      case UserStatus.busy:      return 'مشغول';
      case UserStatus.phone:     return 'هاتف';
      case UserStatus.driving:   return 'سيارة';
      case UserStatus.eating:    return 'طعام';
    }
  }

  String get emoji {
    switch (this) {
      case UserStatus.available: return '🟢';
      case UserStatus.away:      return '🟡';
      case UserStatus.busy:      return '🔴';
      case UserStatus.phone:     return '📱';
      case UserStatus.driving:   return '🚗';
      case UserStatus.eating:    return '🍔';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.available: return const Color(0xFF43A047);
      case UserStatus.away:      return const Color(0xFFFFA000);
      case UserStatus.busy:      return const Color(0xFFE53935);
      case UserStatus.phone:     return const Color(0xFF7B1FA2);
      case UserStatus.driving:   return const Color(0xFF1565C0);
      case UserStatus.eating:    return const Color(0xFFE65100);
    }
  }
}

// ─── Chat User ────────────────────────────────────────────────────────────────
class ChatUser {
  final String id;
  final String name;
  final String? avatar;
  final UserRole role;
  final UserStatus status;
  final int level;
  final double levelProgress; // 0.0 - 1.0
  final bool isVip;
  final bool isOnline;
  final String? nameColor;
  final String? frameStyle;
  final String? badge;
  final String? bio;
  final String? job;
  final String? location;
  final String? country;
  final List<String> gallery;
  final int? roomId;
  final String? deviceId;
  final Map<String, dynamic> permissions;
  final int joinedAt;
  final int visitCount;
  final int talkDuration; // seconds
  final int banCount;
  final double presencePercent;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.role = UserRole.guest,
    this.status = UserStatus.available,
    this.level = 1,
    this.levelProgress = 0.0,
    this.isVip = false,
    this.isOnline = true,
    this.nameColor,
    this.frameStyle,
    this.badge,
    this.bio,
    this.job,
    this.location,
    this.country,
    this.gallery = const [],
    this.roomId,
    this.deviceId,
    this.permissions = const {},
    required this.joinedAt,
    this.visitCount = 0,
    this.talkDuration = 0,
    this.banCount = 0,
    this.presencePercent = 0.0,
  });

  factory ChatUser.fromMap(String id, Map<String, dynamic> d) => ChatUser(
    id: id,
    name: d['name'] ?? 'مجهول',
    avatar: d['avatar'],
    role: UserRoleX.fromString(d['role']),
    level: (d['level'] ?? 1) as int,
    levelProgress: ((d['levelProgress'] ?? 0) as num).toDouble(),
    isVip: d['isVip'] == true,
    isOnline: d['isOnline'] == true,
    nameColor: d['nameColor'],
    frameStyle: d['frameStyle'],
    badge: d['badge'],
    bio: d['bio'],
    job: d['job'],
    location: d['location'],
    country: d['country'],
    gallery: List<String>.from(d['gallery'] ?? []),
    roomId: d['roomId'],
    deviceId: d['deviceId'],
    permissions: Map<String, dynamic>.from(d['permissions'] ?? {}),
    joinedAt: d['joinedAt'] ?? 0,
    visitCount: (d['visitCount'] ?? 0) as int,
    talkDuration: (d['talkDuration'] ?? 0) as int,
    banCount: (d['banCount'] ?? 0) as int,
    presencePercent: ((d['presencePercent'] ?? 0) as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'avatar': avatar,
    'role': role.fsValue, 'level': level, 'levelProgress': levelProgress,
    'isVip': isVip, 'isOnline': isOnline, 'nameColor': nameColor,
    'frameStyle': frameStyle, 'badge': badge, 'bio': bio,
    'job': job, 'location': location, 'country': country,
    'gallery': gallery, 'roomId': roomId, 'deviceId': deviceId,
    'permissions': permissions, 'joinedAt': joinedAt,
    'visitCount': visitCount, 'talkDuration': talkDuration,
    'banCount': banCount, 'presencePercent': presencePercent,
  };

  ChatUser copyWith({String? name, String? avatar, UserRole? role,
    UserStatus? status, bool? isOnline, int? roomId,
    String? nameColor, String? frameStyle, String? badge,
    String? bio, String? job, String? location}) => ChatUser(
    id: id, name: name ?? this.name, avatar: avatar ?? this.avatar,
    role: role ?? this.role, status: status ?? this.status,
    level: level, levelProgress: levelProgress, isVip: isVip,
    isOnline: isOnline ?? this.isOnline, nameColor: nameColor ?? this.nameColor,
    frameStyle: frameStyle ?? this.frameStyle, badge: badge ?? this.badge,
    bio: bio ?? this.bio, job: job ?? this.job,
    location: location ?? this.location, country: country,
    gallery: gallery, roomId: roomId ?? this.roomId,
    deviceId: deviceId, permissions: permissions, joinedAt: joinedAt,
    visitCount: visitCount, talkDuration: talkDuration,
    banCount: banCount, presencePercent: presencePercent,
  );
}

// ─── Room ─────────────────────────────────────────────────────────────────────
class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String sectionId;
  final String? sectionName;
  final int maxCapacity;
  final bool isLocked;
  final int onlineCount;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.sectionId,
    this.sectionName,
    this.maxCapacity = 50,
    this.isLocked = false,
    this.onlineCount = 0,
  });

  factory ChatRoom.fromMap(String id, Map<String, dynamic> d, {String? sectionId, String? sectionName}) =>
    ChatRoom(
      id: id, name: d['name'] ?? 'غرفة',
      description: d['description'], avatar: d['avatar'],
      sectionId: sectionId ?? d['sectionId'] ?? '',
      sectionName: sectionName ?? d['sectionName'],
      maxCapacity: (d['maxCapacity'] ?? 50) as int,
      isLocked: d['isLocked'] == true,
      onlineCount: (d['onlineCount'] ?? 0) as int,
    );
}

class RoomSection {
  final String id;
  final String name;
  final String? icon;
  final List<ChatRoom> rooms;

  const RoomSection({required this.id, required this.name, this.icon, this.rooms = const []});

  factory RoomSection.fromMap(String id, Map<String, dynamic> d) {
    final roomsRaw = (d['rooms'] as List?) ?? [];
    final rooms = roomsRaw.map((r) {
      final rm = Map<String, dynamic>.from(r);
      return ChatRoom.fromMap(rm['id']?.toString() ?? '', rm,
          sectionId: id, sectionName: d['name']);
    }).toList();
    return RoomSection(id: id, name: d['name'] ?? 'قسم', icon: d['icon'], rooms: rooms);
  }
}

// ─── Message ──────────────────────────────────────────────────────────────────
enum MsgType { text, image, system, poll, game }

class ChatMsg {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? senderRole;
  final String? senderNameColor;
  final MsgType type;
  final String? text;
  final String? imageUrl;
  final bool isSystem;
  final String? replyToId;
  final String? replyToName;
  final String? replyToText;
  final Map<String, List<String>> reactions;
  final int timestamp;
  final bool isPinned;

  const ChatMsg({
    required this.id, required this.senderId, required this.senderName,
    this.senderAvatar, this.senderRole, this.senderNameColor,
    this.type = MsgType.text, this.text, this.imageUrl,
    this.isSystem = false, this.replyToId, this.replyToName, this.replyToText,
    this.reactions = const {}, required this.timestamp, this.isPinned = false,
  });

  factory ChatMsg.fromMap(String id, Map<String, dynamic> d) => ChatMsg(
    id: id, senderId: d['senderId'] ?? '', senderName: d['senderName'] ?? '؟',
    senderAvatar: d['senderAvatar'], senderRole: d['senderRole'],
    senderNameColor: d['senderNameColor'],
    type: d['imageUrl'] != null ? MsgType.image : (d['isSystem'] == true ? MsgType.system : MsgType.text),
    text: d['text'], imageUrl: d['imageUrl'], isSystem: d['isSystem'] == true,
    replyToId: d['replyToId'], replyToName: d['replyToName'], replyToText: d['replyToText'],
    reactions: (d['reactions'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, List<String>.from(v))) ?? {},
    timestamp: (d['timestamp'] as num?)?.toInt() ?? 0,
    isPinned: d['isPinned'] == true,
  );

  Map<String, dynamic> toMap() => {
    'senderId': senderId, 'senderName': senderName, 'senderAvatar': senderAvatar,
    'senderRole': senderRole, 'senderNameColor': senderNameColor,
    'text': text, 'imageUrl': imageUrl, 'isSystem': isSystem,
    'replyToId': replyToId, 'replyToName': replyToName, 'replyToText': replyToText,
    'reactions': reactions, 'timestamp': timestamp, 'isPinned': isPinned,
  };
}

// ─── Room State ───────────────────────────────────────────────────────────────
class RoomState {
  final String welcomeMsg;
  final bool chatLocked;
  final bool micLocked;
  final bool imagesLocked;
  final bool dmLocked;
  final String? activeMic;
  final List<String> micQueue;
  final List<String> raisedHands;
  final Map<String, dynamic> bannedUsers;
  final Map<String, dynamic> mutedUsers;
  final String? background;
  final String? pinnedMsg;
  final bool slowMode;
  final int clearedAt;
  final Map<String, dynamic> guestPolicies;

  const RoomState({
    this.welcomeMsg = 'أهلاً بكم 🌹',
    this.chatLocked = false, this.micLocked = false,
    this.imagesLocked = false, this.dmLocked = false,
    this.activeMic, this.micQueue = const [],
    this.raisedHands = const [], this.bannedUsers = const {},
    this.mutedUsers = const {}, this.background, this.pinnedMsg,
    this.slowMode = false, this.clearedAt = 0,
    this.guestPolicies = const {'allowChat': true, 'allowMic': true, 'allowImages': true, 'allowDm': false},
  });

  factory RoomState.fromMap(Map<String, dynamic> d) {
    // activeMic في index.html هو object وليس String
    String? activeMicId;
    final rawMic = d['activeMic'];
    if (rawMic is Map) {
      activeMicId = rawMic['userId']?.toString() ?? rawMic['id']?.toString();
    } else if (rawMic is String) {
      activeMicId = rawMic;
    }

    // micQueue في index.html هو List<Map> كل عنصر {userId, name, ...}
    List<String> micQueueIds = [];
    final rawQueue = d['micQueue'];
    if (rawQueue is List) {
      micQueueIds = rawQueue.map((e) {
        if (e is Map) return e['userId']?.toString() ?? '';
        return e?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toList();
    }

    // raisedHands نفسه
    List<String> raisedHandIds = [];
    final rawHands = d['raisedHands'];
    if (rawHands is List) {
      raisedHandIds = rawHands.map((e) {
        if (e is Map) return e['userId']?.toString() ?? '';
        return e?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toList();
    }

    return RoomState(
      welcomeMsg:   d['welcomeMessage'] ?? 'أهلاً بكم 🌹',
      chatLocked:   d['isChatLocked'] == true,
      micLocked:    d['isMicLocked'] == true,
      imagesLocked: d['isImagesLocked'] == true || d['allowPublicImages'] == false,
      dmLocked:     d['isDMLocked'] == true,
      activeMic:    activeMicId,
      micQueue:     micQueueIds,
      raisedHands:  raisedHandIds,
      bannedUsers:  Map<String, dynamic>.from(d['bannedUsers'] ?? {}),
      mutedUsers:   Map<String, dynamic>.from(d['mutedUsers'] ?? {}),
      background:   d['background'], pinnedMsg: d['pinnedMessage'],
      slowMode:     d['slowMode'] == true,
      clearedAt:    (d['chatClearedAt'] ?? 0) as int,
      guestPolicies: Map<String, dynamic>.from(d['guestPolicies'] ?? {
        'allowChat': true, 'allowMic': true, 'allowImages': true, 'allowDm': false,
      }),
    );
  }

}
