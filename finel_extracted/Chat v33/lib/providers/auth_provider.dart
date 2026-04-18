// ============================================================
// Jordan Audio Forum — Auth Provider
// ✅ v24: إصلاح التعليق على شاشة التحميل
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService.instance;

  AuthStatus _status = AuthStatus.loading;
  UserModel? _profile;
  String? _error;
  StreamSubscription<User?>? _authSub;
  bool _bootstrapDone = false;

  AuthStatus get status => _status;
  UserModel? get profile => _profile;
  String? get error => _error;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _profile?.isAdminUser ?? false;
  bool get isBanned => _profile?.isBanned ?? false;
  // ✅ FIX: isGuest = صح بس لو المستخدم مجهول أو offline
  // مستخدم بإيميل وباسورد ≠ guest حتى لو displayName فاضي مؤقتاً
  bool get isGuest {
    if (_profile == null) return true;
    // offline fallback
    if (_profile!.uid == 'offline_user') return true;
    // anonymous firebase user with no displayName set
    if (_profile!.displayName == 'مجهول' || _profile!.displayName.isEmpty) return true;
    return false;
  }

  AuthProvider() {
    // البدء مباشرة كـ guest للويب لتجنب مشاكل Firebase
    _exitLoadingWithLocalGuest();
    
    _authSub = _service.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (_) => _exitLoadingWithLocalGuest(),
    );
  }

  void _exitLoadingWithLocalGuest() {
    if (_bootstrapDone || _status != AuthStatus.loading) return;
    _bootstrapDone = true;
    _profile = const UserModel(
      uid: 'offline_user',
      email: 'offline@local',
      displayName: 'مجهول',
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        try {
          _profile = await _service
              .signInAnonymously()
              .timeout(const Duration(seconds: 8));
          _status = AuthStatus.authenticated;
        } catch (_) {
          _forceLocalGuestProfile();
        }
      } else {
        try {
          _profile = await _service
              .getUserProfile(firebaseUser.uid)
              .timeout(const Duration(seconds: 8));
          if (_profile == null) {
            if (firebaseUser.isAnonymous) {
              _profile = await _service
                  .signInAnonymously()
                  .timeout(const Duration(seconds: 8));
            } else {
              _profile = UserModel(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? 'unknown',
                displayName: firebaseUser.displayName ?? 'مستخدم',
              );
            }
          }
          _status = AuthStatus.authenticated;
        } catch (_) {
          _profile = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.isAnonymous
                ? 'guest@jordan.forum'
                : (firebaseUser.email ?? 'unknown'),
            displayName: firebaseUser.isAnonymous
                ? 'مجهول'
                : (firebaseUser.displayName ?? 'مستخدم'),
          );
          _status = AuthStatus.authenticated;
        }
      }
    } catch (_) {
      _forceLocalGuestProfile();
    }
    _bootstrapDone = true;
    notifyListeners();
  }

  void _forceLocalGuestProfile() {
    _profile = const UserModel(
      uid: 'offline_user',
      email: 'offline@local',
      displayName: 'مجهول',
    );
    _status = AuthStatus.authenticated;
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    setState(() {});
    try {
      _profile = await _service
          .login(email, password)
          .timeout(const Duration(seconds: 15));
      _status = AuthStatus.authenticated;
      _bootstrapDone = true;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مجدداً';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    File? profileImage,
    String bio = '',
  }) async {
    _error = null;
    try {
      _profile = await _service
          .register(
            email: email,
            password: password,
            displayName: displayName,
            profileImage: profileImage,
            bio: bio,
          )
          .timeout(const Duration(seconds: 20));
      _status = AuthStatus.authenticated;
      _bootstrapDone = true;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مجدداً';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _profile = null;
    _status = AuthStatus.unauthenticated;
    _bootstrapDone = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    File? newImage,
  }) async {
    if (_profile == null) return false;
    _error = null;
    try {
      _profile = await _service.updateProfile(
        _profile!.uid,
        displayName: displayName,
        bio: bio,
        newImage: newImage,
      );

      // إذا كان المستخدم زائر، تأكد من تحديث الاسم المحلي أيضاً
      if (_profile!.displayName == 'مجهول' && displayName != null) {
        _profile = UserModel(
          uid: _profile!.uid,
          email: _profile!.email,
          displayName: displayName,
          photoURL: _profile!.photoURL,
          bio: _profile!.bio,
          isAdmin: _profile!.isAdmin,
          createdAt: _profile!.createdAt,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
