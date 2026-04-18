// lib/services/firebase_service.dart
// ✅ مسارات مباشرة لقاعدة البيانات الخاصة بك (مطابقة لـ index.html):
//   users          ← أعضاء الغرف
//   rooms          ← الأقسام والغرف (كل doc قسم يحتوي على rooms[] array)
//   app_status     ← الإعدادات والتحكم
//   support_chat   ← الرسائل الخاصة
//   room_states    ← حالة كل غرفة (doc id = roomId)
//   room_games     ← ألعاب الغرف
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // ─── مراجع المجموعات الرئيسية (مطابقة لـ index.html) ──────────────────
  CollectionReference get _users       => _db.collection('users');
  CollectionReference get _rooms       => _db.collection('rooms');
  CollectionReference get _appStatus   => _db.collection('app_status');
  CollectionReference get _supportChat => _db.collection('support_chat');
  CollectionReference get _roomStates  => _db.collection('room_states');  // ✅ مثل index.html
  CollectionReference get _roomGames   => _db.collection('room_games');

  DocumentReference _userDoc(String uid)        => _users.doc(uid);
  DocumentReference _appStatusDoc(String docId) => _appStatus.doc(docId);

  // ─── Auth ────────────────────────────────────────────────────────────────
  Future<void> signIn() => _auth.signInAnonymously();

  // ─── Sections (يقرأ من rooms ← كل doc هو قسم يحتوي على rooms array) ──────
  Stream<List<RoomSection>> sectionsStream() =>
    _rooms.snapshots().map((s) =>
      s.docs.map((d) => RoomSection.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());

  // ─── Members (users collection) ─────────────────────────────────────────
  Future<void> joinRoom(ChatUser u) =>
    _userDoc(u.id).set(u.toMap(), SetOptions(merge: true));

  Future<void> leaveRoom(String uid) =>
    _userDoc(uid).update({'isOnline': false, 'roomId': null});

  Stream<List<ChatUser>> membersStream(String roomId) =>
    _users
      .where('roomId', isEqualTo: int.tryParse(roomId) ?? roomId)
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ChatUser.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());

  Stream<List<ChatUser>> allOnlineUsersStream() =>
    _users.where('isOnline', isEqualTo: true).snapshots()
      .map((s) => s.docs.map((d) => ChatUser.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());

  // ─── Messages (subcollection داخل كل room — مطابق لـ index.html) ────────
  // في index.html: messages_${roomId} → collection(db,'rooms',roomId,'messages')
  Stream<List<ChatMsg>> msgsStream(String roomId) =>
    _rooms.doc(roomId).collection('messages')
      .orderBy('timestamp').limitToLast(100).snapshots()
      .map((s) => s.docs.map((d) => ChatMsg.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());

  Future<void> sendMsg(String roomId, Map<String, dynamic> data) =>
    _rooms.doc(roomId).collection('messages').add(data);

  Future<void> deleteMsg(String roomId, String msgId) =>
    _rooms.doc(roomId).collection('messages').doc(msgId).delete();

  // ─── Room State (collection مستقلة room_states — مطابق لـ index.html) ───
  // في index.html: collection(db, 'room_states').doc(roomId)
  Stream<RoomState> roomStateStream(String roomId) =>
    _roomStates.doc(roomId).snapshots().map((s) =>
      s.exists ? RoomState.fromMap(s.data() as Map<String, dynamic>) : const RoomState());

  Future<void> updateRoomState(String roomId, Map<String, dynamic> data) =>
    _roomStates.doc(roomId).set(data, SetOptions(merge: true));

  // ─── Helper: دمج Map nested (مطابق لـ setDoc merge) ─────────────────────
  Future<void> setRoomStateField(String roomId, String field, dynamic value) =>
    _roomStates.doc(roomId).set({field: value}, SetOptions(merge: true));

  // ─── User field update (مطابق لـ index.html يحدث users مباشرة) ──────────
  Future<void> updateUserField(String uid, String field, dynamic value, {bool isRegistered = false}) async {
    await _userDoc(uid).set({field: value}, SetOptions(merge: true));
    // للمستخدمين المسجلين — نحدث saved_members كـ backup
    if (isRegistered) {
      await _appStatus.doc('saved_members').collection('list').doc(uid)
        .set({field: value}, SetOptions(merge: true));
    }
  }

  // ─── Login (مطابق لـ index.html تماماً) ─────────────────────────────────
  // index.html يبحث في users collection عن name+password
  Future<ChatUser?> loginRegistered(String name, String pass) async {
    // أولاً: جرب الـ users collection مباشرة (نفس index.html)
    final s = await _users
      .where('name', isEqualTo: name).limit(5).get();
    for (final doc in s.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['password'] == pass) {
        return ChatUser.fromMap(doc.id, d);
      }
    }
    // ثانياً: جرب saved_members كـ fallback قديم
    final s2 = await _appStatus.doc('saved_members').collection('list')
      .where('name', isEqualTo: name).limit(1).get();
    if (s2.docs.isEmpty) return null;
    final d2 = s2.docs.first.data();
    if (d2['password'] != pass) return null;
    return ChatUser.fromMap(s2.docs.first.id, d2);
  }

  // تسجيل دخول بحساب الغرفة (admin/super admin للغرفة)
  Future<ChatUser?> loginWithRoomAccount(String roomId, String name, String pass) async {
    // جرب users collection أولاً (نفس منطق index.html)
    final s = await _users
      .where('name', isEqualTo: name).limit(5).get();
    for (final doc in s.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['password'] == pass) {
        final role = UserRoleX.fromString(d['role']);
        return ChatUser.fromMap(doc.id, d).copyWith(role: role, roomId: int.tryParse(roomId));
      }
    }
    // fallback: accounts subcollection
    final s2 = await _rooms.doc(roomId).collection('accounts')
      .where('username', isEqualTo: name).limit(1).get();
    if (s2.docs.isEmpty) return null;
    final d2 = s2.docs.first.data();
    if (d2['password'] != pass) return null;
    final role = UserRoleX.fromString(d2['role']);
    return ChatUser(
      id: 'reg_${s2.docs.first.id}', name: name, role: role,
      permissions: Map<String, dynamic>.from(d2['permissions'] ?? {}),
      roomId: int.tryParse(roomId), joinedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ─── Private chats (support_chat collection) ─────────────────────────────
  String dmId(String a, String b) => ([a, b]..sort()).join('_');

  Stream<List<ChatMsg>> dmStream(String chatId) =>
    _supportChat.doc(chatId).collection('messages')
      .orderBy('timestamp').limitToLast(100).snapshots()
      .map((s) => s.docs.map((d) => ChatMsg.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());

  Future<void> sendDm(String chatId, Map<String, dynamic> data,
    {required String sid, required String rid, required String sName,
     String? rName, String? rAvatar, String? sAvatar}) async {
    await _supportChat.doc(chatId).collection('messages').add(data);
    await _supportChat.doc(chatId).set({
      'participants': [sid, rid],
      'lastMessage': data['text'] ?? '📷',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': sid, 'isRead': false,
      'users': {
        sid: {'name': sName, 'avatar': sAvatar},
        rid: {'name': rName ?? '؟', 'avatar': rAvatar},
      },
    }, SetOptions(merge: true));
  }

  Future<void> markDmRead(String chatId, String uid) async {
    final ref = _supportChat.doc(chatId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>?;
      final ra = Map<String, dynamic>.from(data?['readAt'] ?? {});
      ra[uid] = DateTime.now().millisecondsSinceEpoch;
      tx.set(ref, {'readAt': ra}, SetOptions(merge: true));
    });
  }

  Future<void> savePushToken(String userId, String token) async {
    await _userDoc(userId).set({'fcmToken': token}, SetOptions(merge: true));
  }

  // ─── App Status / Sys Config (app_status collection) ─────────────────────
  Future<Map<String, dynamic>> getSysConfigOnce(String docId) async {
    final snap = await _appStatusDoc(docId).get();
    return snap.data() as Map<String, dynamic>? ?? {};
  }

  Stream<Map<String, dynamic>> sysConfigStream(String docId) =>
    _appStatusDoc(docId).snapshots().map((s) =>
      s.exists ? s.data() as Map<String, dynamic> : <String, dynamic>{});

  Stream<List<Map<String, dynamic>>> inboxStream(String uid) =>
    _supportChat.where('participants', arrayContains: uid)
      .orderBy('lastTimestamp', descending: true).snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  // ─── Moderation (يكتب في room_states مثل index.html) ────────────────────
  Future<void> banUser(String roomId, String uid, String reason) async {
    await _roomStates.doc(roomId).set({
      'bannedUsers.$uid': {'reason': reason, 'expiry': 9999999999999},
    }, SetOptions(merge: true));
    await leaveRoom(uid);
  }

  Future<void> muteUser(String roomId, String uid, int minutes) async {
    final exp = DateTime.now().add(Duration(minutes: minutes)).millisecondsSinceEpoch;
    await _roomStates.doc(roomId).set(
      {'mutedUsers.$uid': {'expiry': exp}},
      SetOptions(merge: true));
  }

  Future<void> kickUser(String roomId, String uid) => leaveRoom(uid);

  // ─── Mic management (مطابق لـ index.html) ────────────────────────────────
  Future<void> updateActiveMic(String roomId, String? userId) =>
    _roomStates.doc(roomId).set({'activeMic': userId}, SetOptions(merge: true));

  Future<void> addToMicQueue(String roomId, String userId) =>
    _roomStates.doc(roomId).set({
      'micQueue': FieldValue.arrayUnion([userId]),
      'raisedHands': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));

  Future<void> removeFromMicQueue(String roomId, String userId) =>
    _roomStates.doc(roomId).set({
      'micQueue': FieldValue.arrayRemove([userId]),
      'raisedHands': FieldValue.arrayRemove([userId]),
    }, SetOptions(merge: true));
}
