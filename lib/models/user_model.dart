// lib/models/user_model.dart

enum UserRole { guest, member, admin, superAdmin, master, owner, root, sales }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.guest:      return 'زائر';
      case UserRole.member:     return 'عضو';
      case UserRole.admin:      return 'مشرف';
      case UserRole.superAdmin: return 'مشرف عام';
      case UserRole.master:     return 'ماستر';
      case UserRole.owner:      return 'مالك';
      case UserRole.root:       return 'روت';
      case UserRole.sales:      return 'مبيعات';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.guest:      return '👤';
      case UserRole.member:     return '⭐';
      case UserRole.admin:      return '🛡️';
      case UserRole.superAdmin: return '💎';
      case UserRole.master:     return '👑';
      case UserRole.owner:      return '🏆';
      case UserRole.root:       return '🔑';
      case UserRole.sales:      return '💼';
    }
  }

  int get weight {
    switch (this) {
      case UserRole.guest:      return 0;
      case UserRole.member:     return 1;
      case UserRole.admin:      return 2;
      case UserRole.superAdmin: return 3;
      case UserRole.master:     return 4;
      case UserRole.owner:      return 5;
      case UserRole.root:       return 6;
      case UserRole.sales:      return 7;
    }
  }

  static UserRole fromString(String? s) {
    switch (s) {
      case 'Member':      return UserRole.member;
      case 'Admin':       return UserRole.admin;
      case 'SuperAdmin':
      case 'Super Admin': return UserRole.superAdmin;
      case 'Master':      return UserRole.master;
      case 'Owner':       return UserRole.owner;
      case 'Root':        return UserRole.root;
      case 'Sales':       return UserRole.sales;
      default:            return UserRole.guest;
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserRole.guest:      return 'Guest';
      case UserRole.member:     return 'Member';
      case UserRole.admin:      return 'Admin';
      case UserRole.superAdmin: return 'SuperAdmin';
      case UserRole.master:     return 'Master';
      case UserRole.owner:      return 'Owner';
      case UserRole.root:       return 'Root';
      case UserRole.sales:      return 'Sales';
    }
  }
}

class ChatUser {
  final String id;
  final String name;
  final String? avatar;
  final UserRole role;
  final int level;
  final bool isVip;
  final bool isOnline;
  final String? status;
  final String? nameColor;
  final String? nameAnimation;
  final String? frameStyle;
  final String? badge;
  final String? bio;
  final List<String> gallery;
  final int? roomId;
  final String? country;
  final String? deviceId;
  final Map<String, dynamic> permissions;
  final int joinedAt;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.role = UserRole.guest,
    this.level = 1,
    this.isVip = false,
    this.isOnline = true,
    this.status,
    this.nameColor,
    this.nameAnimation,
    this.frameStyle,
    this.badge,
    this.bio,
    this.gallery = const [],
    this.roomId,
    this.country,
    this.deviceId,
    this.permissions = const {},
    required this.joinedAt,
  });

  factory ChatUser.fromMap(String id, Map<String, dynamic> data) {
    return ChatUser(
      id: id,
      name: data['name'] ?? 'مجهول',
      avatar: data['avatar'],
      role: UserRoleExt.fromString(data['role']),
      level: (data['level'] ?? 1) as int,
      isVip: data['isVip'] == true,
      isOnline: data['isOnline'] == true,
      status: data['status'],
      nameColor: data['nameColor'],
      nameAnimation: data['nameAnimation'],
      frameStyle: data['frameStyle'],
      badge: data['badge'],
      bio: data['bio'],
      gallery: List<String>.from(data['gallery'] ?? []),
      roomId: data['roomId'],
      country: data['country'],
      deviceId: data['deviceId'],
      permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
      joinedAt: data['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'role': role.firestoreValue,
    'level': level,
    'isVip': isVip,
    'isOnline': isOnline,
    'status': status,
    'nameColor': nameColor,
    'nameAnimation': nameAnimation,
    'frameStyle': frameStyle,
    'badge': badge,
    'bio': bio,
    'gallery': gallery,
    'roomId': roomId,
    'country': country,
    'deviceId': deviceId,
    'permissions': permissions,
    'joinedAt': joinedAt,
  };

  ChatUser copyWith({
    String? name,
    String? avatar,
    UserRole? role,
    int? level,
    bool? isVip,
    bool? isOnline,
    String? status,
    String? nameColor,
    String? nameAnimation,
    String? frameStyle,
    String? badge,
    String? bio,
    List<String>? gallery,
    int? roomId,
  }) {
    return ChatUser(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      level: level ?? this.level,
      isVip: isVip ?? this.isVip,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
      nameColor: nameColor ?? this.nameColor,
      nameAnimation: nameAnimation ?? this.nameAnimation,
      frameStyle: frameStyle ?? this.frameStyle,
      badge: badge ?? this.badge,
      bio: bio ?? this.bio,
      gallery: gallery ?? this.gallery,
      roomId: roomId ?? this.roomId,
      country: country,
      deviceId: deviceId,
      permissions: permissions,
      joinedAt: joinedAt,
    );
  }
}
