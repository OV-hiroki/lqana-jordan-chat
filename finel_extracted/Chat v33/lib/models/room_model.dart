import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String role;
  final bool isMuted;
  final bool hasRaisedHand;
  final String? country;
  final String? deviceId;
  final List<String> permissions;
  final String statusEmoji; // ✅ حالة المستخدم داخل الغرفة

  const ParticipantModel({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.role,
    this.isMuted = true,
    this.hasRaisedHand = false,
    this.country,
    this.deviceId,
    this.permissions = const [],
    this.statusEmoji = '',
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> map) => ParticipantModel(
        uid: map['uid'] ?? '',
        displayName: map['displayName'] ?? '',
        photoURL: map['photoURL'],
        role: map['role'] ?? 'listener',
        isMuted: map['isMuted'] ?? true,
        hasRaisedHand: map['hasRaisedHand'] ?? false,
        country: map['country'],
        deviceId: map['deviceId'],
        permissions: List<String>.from(map['permissions'] ?? []),
        statusEmoji: map['statusEmoji'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': role,
        'isMuted': isMuted,
        'hasRaisedHand': hasRaisedHand,
        'country': country,
        'deviceId': deviceId,
        'permissions': permissions,
        'statusEmoji': statusEmoji,
      };

  ParticipantModel copyWith({
    bool? isMuted,
    bool? hasRaisedHand,
    String? role,
    List<String>? permissions,
    String? statusEmoji,
  }) =>
      ParticipantModel(
        uid: uid,
        displayName: displayName,
        photoURL: photoURL,
        role: role ?? this.role,
        isMuted: isMuted ?? this.isMuted,
        hasRaisedHand: hasRaisedHand ?? this.hasRaisedHand,
        country: country,
        deviceId: deviceId,
        permissions: permissions ?? this.permissions,
        statusEmoji: statusEmoji ?? this.statusEmoji,
      );
}

// ─── Room Settings ───────────────────────────────────────────
class RoomSettings {
  final String welcomeMessage;
  final String whoCanSpeak; // 'all' | 'members_admins' | 'admins' | 'none'
  final Map<String, int> speakDuration;
  final bool cameraEnabled;
  final String lockStatus; // 'open' | 'members' | 'locked'
  final String lockReason;
  final bool hasGateway;
  final bool allowImages;
  final bool allowMasterAddMaster;
  final bool allowMasterChangeSettings;

  const RoomSettings({
    this.welcomeMessage = '',
    this.whoCanSpeak = 'all',
    this.speakDuration = const {
      'guest': 350,
      'member': 350,
      'admin': 350,
      'superadmin': 350,
      'master': 350,
    },
    this.cameraEnabled = false,
    this.lockStatus = 'open',
    this.lockReason = '',
    this.hasGateway = false,
    this.allowImages = true,
    this.allowMasterAddMaster = true,
    this.allowMasterChangeSettings = false,
  });

  factory RoomSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RoomSettings();
    final dur = (map['speakDuration'] as Map<String, dynamic>?) ?? {};
    return RoomSettings(
      welcomeMessage: map['welcomeMessage'] ?? '',
      whoCanSpeak: map['whoCanSpeak'] ?? 'all',
      speakDuration: {
        'guest': dur['guest'] ?? 350,
        'member': dur['member'] ?? 350,
        'admin': dur['admin'] ?? 350,
        'superadmin': dur['superadmin'] ?? 350,
        'master': dur['master'] ?? 350,
      },
      cameraEnabled: map['cameraEnabled'] ?? false,
      lockStatus: map['lockStatus'] ?? 'open',
      lockReason: map['lockReason'] ?? '',
      hasGateway: map['hasGateway'] ?? false,
      allowImages: map['allowImages'] ?? true,
      allowMasterAddMaster: map['allowMasterAddMaster'] ?? true,
      allowMasterChangeSettings: map['allowMasterChangeSettings'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'welcomeMessage': welcomeMessage,
        'whoCanSpeak': whoCanSpeak,
        'speakDuration': speakDuration,
        'cameraEnabled': cameraEnabled,
        'lockStatus': lockStatus,
        'lockReason': lockReason,
        'hasGateway': hasGateway,
        'allowImages': allowImages,
        'allowMasterAddMaster': allowMasterAddMaster,
        'allowMasterChangeSettings': allowMasterChangeSettings,
      };
}

// ─── Banned Entry ────────────────────────────────────────────
class BannedEntry {
  final String displayName;
  final String? country;
  final String? deviceId;
  final String? ip;
  final String bannedBy;
  final String duration;
  final DateTime bannedAt;
  final bool isBannedPC;

  const BannedEntry({
    required this.displayName,
    this.country,
    this.deviceId,
    this.ip,
    required this.bannedBy,
    this.duration = 'Forever',
    required this.bannedAt,
    this.isBannedPC = true,
  });

  factory BannedEntry.fromMap(Map<String, dynamic> map) => BannedEntry(
        displayName: map['displayName'] ?? '',
        country: map['country'],
        deviceId: map['deviceId'],
        ip: map['ip'],
        bannedBy: map['bannedBy'] ?? '',
        duration: map['duration'] ?? 'Forever',
        bannedAt: (map['bannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isBannedPC: map['isBannedPC'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'country': country,
        'deviceId': deviceId,
        'ip': ip,
        'bannedBy': bannedBy,
        'duration': duration,
        'bannedAt': Timestamp.fromDate(bannedAt),
        'isBannedPC': isBannedPC,
      };
}

// ─── Room Log Entry ──────────────────────────────────────────
class RoomLogEntry {
  final String displayName;
  final String? country;
  final String? deviceId;
  final String? role;
  final DateTime joinedAt;
  final DateTime? leftAt;

  const RoomLogEntry({
    required this.displayName,
    this.country,
    this.deviceId,
    this.role,
    required this.joinedAt,
    this.leftAt,
  });

  Duration? get duration =>
      leftAt != null ? leftAt!.difference(joinedAt) : null;

  String get durationLabel {
    final d = duration;
    if (d == null) return '';
    if (d.inMinutes < 1) return '${d.inSeconds} Secs';
    return '${d.inMinutes} mins';
  }

  factory RoomLogEntry.fromMap(Map<String, dynamic> map) => RoomLogEntry(
        displayName: map['displayName'] ?? '',
        country: map['country'],
        deviceId: map['deviceId'],
        role: map['role'],
        joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        leftAt: (map['leftAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'country': country,
        'deviceId': deviceId,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'leftAt': leftAt != null ? Timestamp.fromDate(leftAt!) : null,
      };
}

// ─── Admin Report Entry ──────────────────────────────────────
class AdminReportEntry {
  final String adminName;
  final String action;
  final String targetName;
  final String? targetDeviceId;
  final DateTime timestamp;

  const AdminReportEntry({
    required this.adminName,
    required this.action,
    required this.targetName,
    this.targetDeviceId,
    required this.timestamp,
  });

  factory AdminReportEntry.fromMap(Map<String, dynamic> map) =>
      AdminReportEntry(
        adminName: map['adminName'] ?? '',
        action: map['action'] ?? '',
        targetName: map['targetName'] ?? '',
        targetDeviceId: map['targetDeviceId'],
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'adminName': adminName,
        'action': action,
        'targetName': targetName,
        'targetDeviceId': targetDeviceId,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

// ─── Room Model ──────────────────────────────────────────────
class RoomModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryIcon;
  final String? coverImage;
  final String hostUid;
  final String hostName;
  final String? hostPhoto;
  final bool isLive;
  final bool isPublic;
  final int speakersCount;
  final int listenersCount;
  final List<ParticipantModel> speakers;
  final DateTime? createdAt;
  final RoomSettings settings;
  final int maxCapacity;
  final int? expiresInDays;
  // ── Rental fields ─────────────────────────────────────────
  final DateTime? rentalStartAt;
  final DateTime? rentalExpiresAt;
  final String? renterUid;     // UID صاحب الغرفة
  final String? renterName;    // اسم صاحب الغرفة
  /// مالك الإيجار يعيّن من لوحة المالك: يدخل برتبة أدمن تلقائياً
  final String? designatedRoomAdminUid;
  final String? designatedRoomAdminName;

  const RoomModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.categoryIcon = '💬',
    this.coverImage,
    required this.hostUid,
    required this.hostName,
    this.hostPhoto,
    this.isLive = true,
    this.isPublic = true,
    this.speakersCount = 0,
    this.listenersCount = 0,
    this.speakers = const [],
    this.createdAt,
    this.settings = const RoomSettings(),
    this.maxCapacity = 50,
    this.expiresInDays,
    this.rentalStartAt,
    this.rentalExpiresAt,
    this.renterUid,
    this.renterName,
    this.designatedRoomAdminUid,
    this.designatedRoomAdminName,
  });

  // ── Rental helpers ────────────────────────────────────────
  bool get isRented => rentalExpiresAt != null;
  bool get isRentalExpired =>
      rentalExpiresAt != null && DateTime.now().isAfter(rentalExpiresAt!);
  Duration get rentalTimeLeft =>
      rentalExpiresAt != null
          ? rentalExpiresAt!.difference(DateTime.now())
          : Duration.zero;

  int get totalParticipants => speakersCount + listenersCount;

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'other',
      categoryIcon: d['categoryIcon'] ?? '💬',
      coverImage: d['coverImage'],
      hostUid: d['hostUid'] ?? '',
      hostName: d['hostName'] ?? '',
      hostPhoto: d['hostPhoto'],
      // إذا الحقل غير موجود في Firestore نفترض أن الغرفة مفتوحة (توافق مع غرف قديمة)
      isLive: d['isLive'] ?? true,
      isPublic: d['isPublic'] ?? true,
      speakersCount: d['speakersCount'] ?? 0,
      listenersCount: d['listenersCount'] ?? 0,
      speakers: (d['speakers'] as List<dynamic>? ?? [])
          .map((s) => ParticipantModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      settings: RoomSettings.fromMap(d['settings'] as Map<String, dynamic>?),
      maxCapacity: d['maxCapacity'] ?? 50,
      expiresInDays: d['expiresInDays'],
      rentalStartAt:   (d['rentalStartAt']   as Timestamp?)?.toDate(),
      rentalExpiresAt: (d['rentalExpiresAt'] as Timestamp?)?.toDate(),
      renterUid:  d['renterUid'],
      renterName: d['renterName'],
      designatedRoomAdminUid: d['designatedRoomAdminUid'] as String?,
      designatedRoomAdminName: d['designatedRoomAdminName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'category': category,
        'categoryIcon': categoryIcon,
        'coverImage': coverImage,
        'hostUid': hostUid,
        'hostName': hostName,
        'hostPhoto': hostPhoto,
        'isLive': isLive,
        'isPublic': isPublic,
        'speakersCount': speakersCount,
        'listenersCount': listenersCount,
        'speakers': speakers.map((s) => s.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': settings.toMap(),
        'maxCapacity': maxCapacity,
        'expiresInDays': expiresInDays,
        'rentalStartAt':   rentalStartAt != null ? Timestamp.fromDate(rentalStartAt!) : null,
        'rentalExpiresAt': rentalExpiresAt != null ? Timestamp.fromDate(rentalExpiresAt!) : null,
        'renterUid':  renterUid,
        'renterName': renterName,
        'designatedRoomAdminUid': designatedRoomAdminUid,
        'designatedRoomAdminName': designatedRoomAdminName,
      };
}
