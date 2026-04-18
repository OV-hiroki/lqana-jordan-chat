import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection(AppConstants.colRooms);
  CollectionReference<Map<String, dynamic>> get _users => _db.collection(AppConstants.colUsers);
  CollectionReference<Map<String, dynamic>> _bans(String roomId) => _rooms.doc(roomId).collection('bans');
  CollectionReference<Map<String, dynamic>> _logs(String roomId) => _rooms.doc(roomId).collection('logs');
  CollectionReference<Map<String, dynamic>> _reports(String roomId) => _rooms.doc(roomId).collection('reports');

  // ── Rooms ─────────────────────────────────────────────────

  Future<RoomModel> createRoom({
    required String title,
    String description = '',
    required String category,
    required UserModel host,
    bool isPublic = true,
    int maxCapacity = 50,
    String? coverImage,
  }) async {
    // look up in countries first, then legacy roomCategories
    final catData = AppConstants.countries.firstWhere(
        (c) => c['id'] == category,
        orElse: () => AppConstants.countries.last);

    final firstSpeaker = ParticipantModel(
      uid: host.uid,
      displayName: host.displayName,
      photoURL: host.photoURL,
      role: AppConstants.roleMaster,
      isMuted: false,
    );

    final room = RoomModel(
      id: '',
      title: title,
      description: description,
      category: category,
      categoryIcon: catData['flag'] ?? catData['icon'] ?? '💬',
      coverImage: coverImage,
      hostUid: host.uid,
      hostName: host.displayName,
      hostPhoto: host.photoURL,
      isLive: true,
      isPublic: isPublic,
      speakersCount: 1,
      speakers: [firstSpeaker],
      maxCapacity: maxCapacity,
    );

    final ref = await _rooms.add(room.toFirestore());
    return RoomModel.fromFirestore(await ref.get());
  }

  /// قائمة الغرف للشاشة الرئيسية — بدون شرط isLive في الاستعلام حتى لا نستبعد
  /// مستندات بلا الحقل أو بسبب فهرس مركّب ناقص، ثم نفلتر محلياً.
  Stream<List<RoomModel>> listenToRooms({String? category}) {
    Query<Map<String, dynamic>> q = category != null && category.isNotEmpty
        ? _rooms.where('category', isEqualTo: category).limit(100)
        : _rooms.limit(100);
    return q.snapshots().map((snap) {
      final rooms =
          snap.docs.map((d) => RoomModel.fromFirestore(d)).toList();
      rooms.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return rooms
          .where((r) => r.isPublic && r.isLive)
          .take(50)
          .toList();
    });
  }

  Stream<RoomModel?> listenToRoom(String roomId) => _rooms
      .doc(roomId)
      .snapshots()
      .map((snap) => snap.exists ? RoomModel.fromFirestore(snap) : null);

  Future<RoomModel?> getRoomOnce(String roomId) async {
    final d = await _rooms.doc(roomId).get();
    if (!d.exists) return null;
    return RoomModel.fromFirestore(d);
  }

  /// حذف مستند الغرفة (المجلدات الفرعية قد تبقى — احذفها من Console عند الحاجة)
  Future<void> deleteRoom(String roomId) => _rooms.doc(roomId).delete();

  Future<void> closeRoom(String roomId) => _rooms.doc(roomId).update({
        'isLive': false,
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> forceCloseRoom(String roomId) => _rooms.doc(roomId).update({
        'isLive': false,
        'forceClosed': true,
        'closedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateRoomSettings(String roomId, RoomSettings settings) =>
      _rooms.doc(roomId).update({
        'settings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Participants ──────────────────────────────────────────

  Future<void> joinAsListener(String roomId) => _rooms.doc(roomId).update({
        'listenersCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> leaveAsListener(String roomId) => _rooms.doc(roomId).update({
        'listenersCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> addSpeaker(String roomId, ParticipantModel speaker) async {
    final snap = await _rooms.doc(roomId).get();
    final data = snap.data() as Map<String, dynamic>;
    final speakers = (data['speakers'] as List)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    // Remove if already exists
    speakers.removeWhere((s) => s['uid'] == speaker.uid);
    speakers.add(speaker.toMap());
    await _rooms.doc(roomId).update({
      'speakers': speakers,
      'speakersCount': speakers.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeSpeaker(String roomId, String uid) async {
    final snap = await _rooms.doc(roomId).get();
    final data = snap.data() as Map<String, dynamic>;
    final speakers = (data['speakers'] as List)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .where((s) => s['uid'] != uid)
        .toList();
    await _rooms.doc(roomId).update({
      'speakers': speakers,
      'speakersCount': speakers.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSpeaker(
      String roomId, String uid, Map<String, dynamic> updates) async {
    final snap = await _rooms.doc(roomId).get();
    final data = snap.data() as Map<String, dynamic>;
    final speakers = (data['speakers'] as List)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .map((s) => s['uid'] == uid ? {...s, ...updates} : s)
        .toList();
    await _rooms.doc(roomId).update({
      'speakers': speakers,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleMute(String roomId, String uid, bool isMuted) async {
    // التأكد من أن المستخدم موجود في قائمة speakers قبل تغيير isMuted
    final snap = await _rooms.doc(roomId).get();
    final data = snap.data() as Map<String, dynamic>;
    final speakers = (data['speakers'] as List)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();

    final speakerExists = speakers.any((s) => s['uid'] == uid);

    if (!speakerExists) {
      // إذا لم يكن المستخدم موجوداً، لا نفعل شيئاً
      return;
    }

    await updateSpeaker(roomId, uid, {'isMuted': isMuted});
  }

  Future<void> raiseHand(String roomId, String uid, bool raised) =>
      updateSpeaker(roomId, uid, {'hasRaisedHand': raised});

  /// Change speaker role (member/admin/superadmin/master)
  Future<void> changeSpeakerRole(
      String roomId, String uid, String newRole) =>
      updateSpeaker(roomId, uid, {'role': newRole});

  /// Update speaker permissions
  Future<void> updateSpeakerPermissions(
      String roomId, String uid, List<String> permissions) =>
      updateSpeaker(roomId, uid, {'permissions': permissions});

  // ── Add Account Dialog (إضافة حساب) ──────────────────────

  /// Adds a new named account to speakers with given role & permissions
  Future<void> addAccount(
    String roomId, {
    required String displayName,
    required String role,
    required List<String> permissions,
    bool lockDevice = false,
    String? deviceId,
    String? addedBy,
  }) async {
    final speaker = ParticipantModel(
      uid: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      role: role,
      isMuted: true,
      permissions: permissions,
      deviceId: deviceId,
    );
    await addSpeaker(roomId, speaker);
    if (addedBy != null) {
      await _logAdminAction(
        roomId,
        adminName: addedBy,
        action: 'اضافة حساب',
        targetName: displayName,
        targetDeviceId: deviceId,
      );
    }
  }

  // ── Ban Management ────────────────────────────────────────

  Stream<List<BannedEntry>> listenToBans(String roomId, {bool pcBans = true}) =>
      _bans(roomId)
          .where('isBannedPC', isEqualTo: pcBans)
          .orderBy('bannedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) =>
                  BannedEntry.fromMap(d.data() as Map<String, dynamic>))
              .toList());

  Future<void> banFromRoom(
    String roomId, {
    required String displayName,
    String? country,
    String? deviceId,
    String? ip,
    required String bannedBy,
    String duration = 'Forever',
    bool isBannedPC = true,
  }) async {
    final entry = BannedEntry(
      displayName: displayName,
      country: country,
      deviceId: deviceId,
      ip: ip,
      bannedBy: bannedBy,
      duration: duration,
      bannedAt: DateTime.now(),
      isBannedPC: isBannedPC,
    );
    await _bans(roomId).add(entry.toMap());
    await _logAdminAction(
      roomId,
      adminName: bannedBy,
      action: 'حظر مستخدم',
      targetName: displayName,
      targetDeviceId: deviceId,
    );
  }

  Future<void> unbanFromRoom(String roomId, String docId) =>
      _bans(roomId).doc(docId).delete();

  // ── Room Log ──────────────────────────────────────────────

  Stream<List<RoomLogEntry>> listenToRoomLog(String roomId) =>
      _logs(roomId)
          .orderBy('joinedAt', descending: true)
          .limit(200)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) =>
                  RoomLogEntry.fromMap(d.data() as Map<String, dynamic>))
              .toList());

  Future<String> logJoin(String roomId, ParticipantModel p) async {
    final ref = await _logs(roomId).add({
      'displayName': p.displayName,
      'country': p.country,
      'deviceId': p.deviceId,
      'role': p.role,
      'joinedAt': FieldValue.serverTimestamp(),
      'leftAt': null,
    });
    return ref.id;
  }

  Future<void> logLeave(String roomId, String logDocId) =>
      _logs(roomId).doc(logDocId).update({
        'leftAt': FieldValue.serverTimestamp(),
      });

  /// إرسال رسالة نظام في الدردشة
  Future<void> sendSystemMessage(String roomId, String message) async {
    await _rooms.doc(roomId).collection('messages').add({
      'text': message,
      'senderId': 'system',
      'senderName': 'النظام',
      'senderPhoto': null,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystem': true,
    });
  }

  // ── Favorites ───────────────────────────────────────────────
  CollectionReference _favorites(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  Future<void> addFavorite(String uid, String roomId) async {
    await _favorites(uid).doc(roomId).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String uid, String roomId) async {
    await _favorites(uid).doc(roomId).delete();
  }

  Future<bool> isFavorite(String uid, String roomId) async {
    final doc = await _favorites(uid).doc(roomId).get();
    return doc.exists;
  }

  Stream<List<String>> listenToFavorites(String uid) {
    return _favorites(uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Future<List<RoomModel>> getFavoriteRooms(String uid) async {
    final favSnap = await _favorites(uid).get();
    final roomIds = favSnap.docs.map((d) => d.id).toList();

    if (roomIds.isEmpty) return [];

    // Firestore whereIn limit is 10, so fetch in batches
    final List<RoomModel> allRooms = [];
    for (int i = 0; i < roomIds.length; i += 10) {
      final batch = roomIds.skip(i).take(10).toList();
      final roomsSnap = await _rooms
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      allRooms.addAll(roomsSnap.docs.map((d) => RoomModel.fromFirestore(d)).toList());
    }

    return allRooms;
  }

  // ── Admin Reports ─────────────────────────────────────────

  Stream<List<AdminReportEntry>> listenToAdminReports(String roomId) =>
      _reports(roomId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) =>
                  AdminReportEntry.fromMap(d.data() as Map<String, dynamic>))
              .toList());

  Future<void> _logAdminAction(
    String roomId, {
    required String adminName,
    required String action,
    required String targetName,
    String? targetDeviceId,
  }) =>
      _reports(roomId).add(AdminReportEntry(
        adminName: adminName,
        action: action,
        targetName: targetName,
        targetDeviceId: targetDeviceId,
        timestamp: DateTime.now(),
      ).toMap());

  // ── Users (Admin) ─────────────────────────────────────────

  Future<List<UserModel>> searchUsers(String query) async {
    final snap = await _users
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(15)
        .get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  Future<void> banUser(String uid, String reason) => _users.doc(uid).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
      });

  Future<void> unbanUser(String uid) => _users.doc(uid).update({
        'isBanned': false,
        'banReason': null,
        'bannedAt': null,
      });

  Future<List<RoomModel>> getAllRooms() async {
    final snap = await _rooms.limit(120).get();
    final list = snap.docs.map((d) => RoomModel.fromFirestore(d)).toList();
    list.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return list;
  }

  /// تحديث بيانات أساسية للغرفة من لوحة المالك
  Future<void> updateRoomBasicInfo(
    String roomId, {
    String? title,
    String? description,
    String? category,
    int? maxCapacity,
    String? coverImage,
    String? designatedRoomAdminUid,
    String? designatedRoomAdminName,
    bool clearDesignatedRoomAdmin = false,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (title != null && title.trim().isNotEmpty) {
      updates['title'] = title.trim();
    }
    if (description != null) updates['description'] = description.trim();
    if (maxCapacity != null && maxCapacity > 0) {
      updates['maxCapacity'] = maxCapacity;
    }
    if (category != null && category.isNotEmpty) {
      updates['category'] = category;
      final catData = AppConstants.countries.firstWhere(
        (c) => c['id'] == category,
        orElse: () => AppConstants.countries.last,
      );
      updates['categoryIcon'] = catData['flag'] ?? '💬';
    }
    if (coverImage != null) {
      updates['coverImage'] = coverImage.isEmpty ? null : coverImage;
    }
    if (clearDesignatedRoomAdmin) {
      updates['designatedRoomAdminUid'] = null;
      updates['designatedRoomAdminName'] = null;
    } else {
      if (designatedRoomAdminUid != null) {
        updates['designatedRoomAdminUid'] =
            designatedRoomAdminUid.isEmpty ? null : designatedRoomAdminUid;
      }
      if (designatedRoomAdminName != null) {
        updates['designatedRoomAdminName'] =
            designatedRoomAdminName.isEmpty ? null : designatedRoomAdminName;
      }
    }
    if (updates.length == 1) return;
    await _rooms.doc(roomId).update(updates);
  }

  // ── Messages ──────────────────────────────────────────────

  Future<void> sendRoomMessage(
    String roomId,
    UserModel sender, {
    String text = '',
    String? imageUrl,
  }) async {
    final t = text.trim();
    final img = imageUrl?.trim();
    if (t.isEmpty && (img == null || img.isEmpty)) return;
    await _rooms.doc(roomId).collection('messages').add({
      'senderId': sender.uid,
      'senderName': sender.displayName,
      'senderPhoto': sender.photoURL,
      'text': t.isEmpty ? (img != null ? '📷' : '') : t,
      if (img != null && img.isNotEmpty) 'imageUrl': img,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MessageModel>> listenToRoomMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  Future<void> clearRoomMessages(String roomId) async {
    final snap =
        await _rooms.doc(roomId).collection('messages').limit(500).get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  /// تحديث إعدادات التطبيق العامة
  Future<void> updateAppConfig(Map<String, dynamic> updates) =>
      _db.collection(AppConstants.killSwitchCollection)
          .doc(AppConstants.killSwitchDocument)
          .set({...updates, 'updatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true));

  // ── Support / Admin Chat (محادثة خاصة لكل مستخدم مع الدعم) ──

  /// مستند المحادثة قبل الاستماع (قواعد الأمان تعتمد على bindingAuthUid).
  Future<void> ensureSupportConversationShell({
    required String conversationId,
    required UserModel sender,
  }) async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || conversationId.isEmpty) return;
    final isDedicated = conversationId != sender.uid;
    await _db.collection('support_chat').doc(conversationId).set({
      'userId': sender.uid,
      'bindingAuthUid': authUid,
      'conversationThreadId': conversationId,
      'isDedicatedThread': isDedicated,
      'userName': isDedicated
          ? '${sender.displayName} (محادثة خاصة)'
          : sender.displayName,
      'userPhoto': sender.photoURL,
    }, SetOptions(merge: true));
  }

  /// يرسل رسالة في محادثة الدعم الخاصة بالمستخدم
  Future<void> sendSupportMessage(String text, UserModel sender, {String? conversationId}) async {
    final convId = conversationId ?? sender.uid;
    final isDedicated = convId != sender.uid;
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final inboxName = isDedicated
        ? '${sender.displayName} (محادثة خاصة)'
        : sender.displayName;
    await _db.collection('support_chat').doc(convId).set({
      'userId': sender.uid,
      if (authUid != null) 'bindingAuthUid': authUid,
      'conversationThreadId': convId,
      'isDedicatedThread': isDedicated,
      'userName': inboxName,
      'userPhoto': sender.photoURL,
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadByAdmin': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await _db.collection('support_chat').doc(convId).collection('messages').add({
      'senderId': sender.uid,
      'senderName': sender.displayName,
      'senderPhoto': sender.photoURL,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isFromAdmin': false,
    });
  }

  /// يرسل رسالة من مشرف الدعم إلى مستخدم معين
  Future<void> sendSupportReply({
    required String conversationId,
    required String text,
    required UserModel adminSender,
  }) async {
    await _db.collection('support_chat').doc(conversationId).collection('messages').add({
      'senderId': adminSender.uid,
      'senderName': adminSender.displayName,
      'senderPhoto': adminSender.photoURL,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isFromAdmin': true,
    });
    await _db.collection('support_chat').doc(conversationId).set({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadByAdmin': 0,
    }, SetOptions(merge: true));
  }

  /// يجلب رسائل محادثة دعم مستخدم معين
  Stream<List<MessageModel>> listenToSupportMessages({String? conversationId, String? myUid}) {
    final convId = conversationId ?? myUid ?? '';
    return _db
        .collection('support_chat')
        .doc(convId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  /// يجلب قائمة كل محادثات الدعم (للمشرف فقط)
  Stream<List<Map<String, dynamic>>> listenToAllSupportConversations() {
    return _db
        .collection('support_chat')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// alias مختصر للـ admin screen
  Stream<List<Map<String, dynamic>>> streamSupportConversations() =>
      listenToAllSupportConversations();

  /// تعيين المحادثة كمقروءة للمشرف
  Future<void> markSupportConversationRead(String conversationId) =>
      _db.collection('support_chat').doc(conversationId).update({
        'unreadByAdmin': 0,
      });

  // ── Private Messages (داخل الغرفة) ───────────────────────

  /// يولّد معرّفاً ثابتاً للمحادثة بين مستخدمَين (مرتّب أبجدياً)
  String _privateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// يرسل رسالة خاصة بين مستخدمَين داخل غرفة
  Future<void> sendPrivateMessage(
    String roomId, {
    required String fromUid,
    required String fromName,
    required String toUid,
    required String text,
  }) async {
    final chatId = _privateChatId(fromUid, toUid);
    await _rooms
        .doc(roomId)
        .collection('private')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId':   fromUid,
      'senderName': fromName,
      'text':       text.trim(),
      'createdAt':  FieldValue.serverTimestamp(),
    });
  }

  /// يستمع إلى رسائل المحادثة الخاصة بين مستخدمَين
  Stream<List<MessageModel>> listenToPrivateMessages(
      String roomId, String uid1, String uid2) {
    final chatId = _privateChatId(uid1, uid2);
    return _rooms
        .doc(roomId)
        .collection('private')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }
}
