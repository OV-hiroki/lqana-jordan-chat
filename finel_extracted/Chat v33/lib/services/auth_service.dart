// ============================================================
// Jordan Audio Forum — Auth Service
// ============================================================

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'cloudinary_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  // ── Register ──────────────────────────────────────────────
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    File? profileImage,
    String bio = '',
  }) async {
    // 1. إنشاء الحساب
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    // 2. رفع الصورة
    String? photoURL;
    if (profileImage != null) {
      final result = await CloudinaryService.instance
          .uploadProfileImage(profileImage, user.uid);
      if (result.success) photoURL = result.url;
    }

    // 3. تحديث Firebase Auth
    await user.updateDisplayName(displayName.trim());
    if (photoURL != null) await user.updatePhotoURL(photoURL);

    // 4. حفظ في Firestore
    final profile = UserModel(
      uid:         user.uid,
      email:       user.email!.toLowerCase(),
      displayName: displayName.trim(),
      photoURL:    photoURL,
      bio:         bio.trim(),
      isAdmin:     false, // مُدار من Firestore — لا تحقق هنا
    );
    await _db.collection(AppConstants.colUsers)
        .doc(user.uid)
        .set(profile.toFirestore());

    return profile;
  }

  // ── Anonymous Login ───────────────────────────────────────
  Future<UserModel> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final user = cred.user!;
    final doc = await _db.collection(AppConstants.colUsers).doc(user.uid).get();
    if (!doc.exists) {
      final profile = UserModel(
        uid: user.uid,
        email: 'guest@jordan.forum',
        displayName: 'مجهول',
      );
      await _db.collection(AppConstants.colUsers).doc(user.uid).set(profile.toFirestore());
      return profile;
    }
    return UserModel.fromFirestore(doc);
  }

  // ── Login ─────────────────────────────────────────────────
  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    await _updateLastSeen(cred.user!.uid);
    return (await getUserProfile(cred.user!.uid))!;
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() => _auth.signOut();

  // ── Get Profile ───────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Update Profile ────────────────────────────────────────
  Future<UserModel> updateProfile(
    String uid, {
    String? displayName,
    String? bio,
    File? newImage,
  }) async {
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (newImage != null) {
      final result = await CloudinaryService.instance
          .uploadProfileImage(newImage, uid);
      if (result.success) {
        updates['photoURL'] = result.url;
        await _auth.currentUser?.updatePhotoURL(result.url);
      }
    }
    if (displayName != null) {
      updates['displayName'] = displayName.trim();
      await _auth.currentUser?.updateDisplayName(displayName.trim());
    }
    if (bio != null) updates['bio'] = bio.trim();

    await _db.collection(AppConstants.colUsers).doc(uid).update(updates);
    return (await getUserProfile(uid))!;
  }

  // ── Reset Password ────────────────────────────────────────
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Auth State Stream ─────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Error Messages ────────────────────────────────────────
  static String getErrorMessage(FirebaseAuthException e) {
    const messages = {
      'email-already-in-use':   'هذا البريد مسجل مسبقاً',
      'invalid-email':          'البريد الإلكتروني غير صالح',
      'user-not-found':         'لا يوجد حساب بهذا البريد',
      'wrong-password':         'كلمة المرور غير صحيحة',
      'invalid-credential':     'البريد أو كلمة المرور غير صحيحة',
      'too-many-requests':      'تجاوزت عدد المحاولات. حاول لاحقاً',
      'network-request-failed': 'فشل الاتصال. تحقق من الإنترنت',
      'weak-password':          'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل',
      'user-disabled':          'هذا الحساب محظور',
    };
    return messages[e.code] ?? e.message ?? 'حدث خطأ غير متوقع';
  }

  Future<void> _updateLastSeen(String uid) async {
    try {
      await _db.collection(AppConstants.colUsers).doc(uid)
          .update({'lastSeenAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }
}
