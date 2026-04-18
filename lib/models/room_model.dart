// lib/models/room_model.dart

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String? password;
  final String sectionId;
  final String? sectionName;
  final int maxCapacity;
  final int maxMasters;
  final int maxAdmins;
  final int maxMembers;
  final bool isLocked;
  final int? onlineCount;
  final String? background;
  final String? youtubeUrl;
  final String? welcomeMessage;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    this.password,
    required this.sectionId,
    this.sectionName,
    this.maxCapacity = 50,
    this.maxMasters = 5,
    this.maxAdmins = 15,
    this.maxMembers = 15,
    this.isLocked = false,
    this.onlineCount,
    this.background,
    this.youtubeUrl,
    this.welcomeMessage,
  });

  factory ChatRoom.fromMap(String id, Map<String, dynamic> data, {String? sectionId, String? sectionName}) {
    return ChatRoom(
      id: id,
      name: data['name'] ?? 'غرفة',
      description: data['description'],
      avatar: data['avatar'],
      password: data['password'],
      sectionId: sectionId ?? data['sectionId'] ?? '',
      sectionName: sectionName ?? data['sectionName'],
      maxCapacity: (data['maxCapacity'] ?? 50) as int,
      maxMasters: (data['maxMasters'] ?? 5) as int,
      maxAdmins: (data['maxAdmins'] ?? 15) as int,
      maxMembers: (data['maxMembers'] ?? 15) as int,
      isLocked: data['isLocked'] == true,
      onlineCount: data['onlineCount'],
      background: data['background'],
      youtubeUrl: data['youtubeUrl'],
      welcomeMessage: data['welcomeMessage'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'avatar': avatar,
    'password': password,
    'sectionId': sectionId,
    'maxCapacity': maxCapacity,
    'maxMasters': maxMasters,
    'maxAdmins': maxAdmins,
    'maxMembers': maxMembers,
    'isLocked': isLocked,
  };
}

class RoomSection {
  final String id;
  final String name;
  final String? icon;
  final List<ChatRoom> rooms;

  const RoomSection({
    required this.id,
    required this.name,
    this.icon,
    this.rooms = const [],
  });

  factory RoomSection.fromMap(String id, Map<String, dynamic> data) {
    final roomsData = (data['rooms'] as List<dynamic>?) ?? [];
    final rooms = roomsData.map((r) {
      final rMap = Map<String, dynamic>.from(r);
      return ChatRoom.fromMap(rMap['id']?.toString() ?? '', rMap, sectionId: id, sectionName: data['name']);
    }).toList();

    return RoomSection(
      id: id,
      name: data['name'] ?? 'قسم',
      icon: data['icon'],
      rooms: rooms,
    );
  }
}

// ─── Message Model ─────────────────────────────────────────────────────────────

enum MessageType { text, image, audio, system, poll, game, gift }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? senderRole;
  final String? senderNameColor;
  final String? senderBadge;
  final String? senderFrame;
  final MessageType type;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final bool isSystem;
  final String? replyToId;
  final String? replyToName;
  final String? replyToText;
  final Map<String, List<String>> reactions;
  final int timestamp;
  final bool isPinned;
  final Map<String, dynamic>? pollData;
  final Map<String, dynamic>? gameData;
  final bool isLocal;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.senderRole,
    this.senderNameColor,
    this.senderBadge,
    this.senderFrame,
    this.type = MessageType.text,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.isSystem = false,
    this.replyToId,
    this.replyToName,
    this.replyToText,
    this.reactions = const {},
    required this.timestamp,
    this.isPinned = false,
    this.pollData,
    this.gameData,
    this.isLocal = false,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    MessageType type = MessageType.text;
    if (data['imageUrl'] != null) type = MessageType.image;
    if (data['audioUrl'] != null) type = MessageType.audio;
    if (data['isSystem'] == true) type = MessageType.system;
    if (data['pollData'] != null) type = MessageType.poll;
    if (data['gameData'] != null) type = MessageType.game;

    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'مجهول',
      senderAvatar: data['senderAvatar'],
      senderRole: data['senderRole'],
      senderNameColor: data['senderNameColor'],
      senderBadge: data['senderBadge'],
      senderFrame: data['senderFrame'],
      type: type,
      text: data['text'],
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      isSystem: data['isSystem'] == true,
      replyToId: data['replyToId'],
      replyToName: data['replyToName'],
      replyToText: data['replyToText'],
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ) ?? {},
      timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      isPinned: data['isPinned'] == true,
      pollData: data['pollData'],
      gameData: data['gameData'],
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'senderRole': senderRole,
    'senderNameColor': senderNameColor,
    'senderBadge': senderBadge,
    'senderFrame': senderFrame,
    'text': text,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'isSystem': isSystem,
    'replyToId': replyToId,
    'replyToName': replyToName,
    'replyToText': replyToText,
    'reactions': reactions,
    'timestamp': timestamp,
    'isPinned': isPinned,
    'pollData': pollData,
    'gameData': gameData,
  };
}

// ─── Room State ────────────────────────────────────────────────────────────────

class RoomState {
  final String welcomeMessage;
  final bool isChatLocked;
  final bool isMicLocked;
  final bool isRoomLocked;
  final bool isImagesLocked;
  final bool isDMLocked;
  final String? activeMic;
  final List<String> micQueue;
  final List<String> raisedHands;
  final Map<String, dynamic> bannedUsers;
  final Map<String, dynamic> mutedUsers;
  final Map<String, String> nameColors;
  final String? background;
  final String? roomAvatar;
  final String? youtubeUrl;
  final String? pinnedMessage;
  final bool slowMode;
  final Map<String, dynamic> guestPolicies;
  final int chatClearedAt;

  const RoomState({
    this.welcomeMessage = 'أهلاً بكم 🌹',
    this.isChatLocked = false,
    this.isMicLocked = false,
    this.isRoomLocked = false,
    this.isImagesLocked = false,
    this.isDMLocked = false,
    this.activeMic,
    this.micQueue = const [],
    this.raisedHands = const [],
    this.bannedUsers = const {},
    this.mutedUsers = const {},
    this.nameColors = const {},
    this.background,
    this.roomAvatar,
    this.youtubeUrl,
    this.pinnedMessage,
    this.slowMode = false,
    this.guestPolicies = const {
      'allowChat': true,
      'allowMic': true,
      'allowAvatar': false,
      'allowDm': false,
      'allowImages': true,
    },
    this.chatClearedAt = 0,
  });

  factory RoomState.fromMap(Map<String, dynamic> data) {
    return RoomState(
      welcomeMessage: data['welcomeMessage'] ?? 'أهلاً بكم 🌹',
      isChatLocked: data['isChatLocked'] == true,
      isMicLocked: data['isMicLocked'] == true,
      isRoomLocked: data['isRoomLocked'] == true,
      isImagesLocked: data['isImagesLocked'] == true,
      isDMLocked: data['isDMLocked'] == true,
      activeMic: data['activeMic'],
      micQueue: List<String>.from(data['micQueue'] ?? []),
      raisedHands: List<String>.from(data['raisedHands'] ?? []),
      bannedUsers: Map<String, dynamic>.from(data['bannedUsers'] ?? {}),
      mutedUsers: Map<String, dynamic>.from(data['mutedUsers'] ?? {}),
      nameColors: Map<String, String>.from(data['nameColors'] ?? {}),
      background: data['background'],
      roomAvatar: data['roomAvatar'],
      youtubeUrl: data['youtubeUrl'],
      pinnedMessage: data['pinnedMessage'],
      slowMode: data['slowMode'] == true,
      guestPolicies: Map<String, dynamic>.from(data['guestPolicies'] ?? {
        'allowChat': true,
        'allowMic': true,
        'allowAvatar': false,
        'allowDm': false,
        'allowImages': true,
      }),
      chatClearedAt: data['chatClearedAt'] ?? 0,
    );
  }
}
