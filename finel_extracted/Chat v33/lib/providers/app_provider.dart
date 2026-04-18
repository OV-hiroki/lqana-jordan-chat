// ============================================================
// Jordan Audio Forum — App Provider (Kill-Switch)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AppProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool   _isLocked           = false;
  String _lockMessage        = AppConstants.killSwitchDefaultMsg;
  bool   _isLoading          = true;
  bool   _isRegistrationOpen = true;
  StreamSubscription<DocumentSnapshot>? _configSub;

  bool   get isLocked           => _isLocked;
  String get lockMessage        => _lockMessage;
  bool   get isLoading          => _isLoading;
  bool   get isRegistrationOpen => _isRegistrationOpen;
  bool   get isReady            => !_isLoading;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    // ✅ Step 1: Fast one-shot fetch with tight timeout
    try {
      final snap = await _db
          .collection(AppConstants.killSwitchCollection)
          .doc(AppConstants.killSwitchDocument)
          .get()
          .timeout(const Duration(seconds: 4));

      if (snap.exists) {
        final data = snap.data()!;
        _isLocked           = data[AppConstants.killSwitchField]    as bool?   ?? false;
        _lockMessage        = data[AppConstants.killSwitchMsgField] as String? ?? AppConstants.killSwitchDefaultMsg;
        _isRegistrationOpen = data['isRegistrationOpen']            as bool?   ?? true;
      } else {
        _isLocked = false;
      }
    } catch (_) {
      // ✅ Network error or timeout → open the app, don't block
      _isLocked = false;
    }

    _isLoading = false;
    notifyListeners();

    // ✅ Step 2: After unblocking, start listening for live Kill-Switch changes
    _startListening();
  }

  void _startListening() {
    _configSub = _db
        .collection(AppConstants.killSwitchCollection)
        .doc(AppConstants.killSwitchDocument)
        .snapshots()
        .listen(
          (snap) {
            if (snap.exists) {
              final data = snap.data()!;
              _isLocked           = data[AppConstants.killSwitchField]    as bool?   ?? false;
              _lockMessage        = data[AppConstants.killSwitchMsgField] as String? ?? AppConstants.killSwitchDefaultMsg;
              _isRegistrationOpen = data['isRegistrationOpen']            as bool?   ?? true;
            } else {
              _isLocked = false;
            }
            notifyListeners();
          },
          onError: (_) {
            // Stream error → ignore, app already running
          },
        );
  }

  @override
  void dispose() {
    _configSub?.cancel();
    super.dispose();
  }

  Future<void> setLockState(bool locked, {String? message}) async {
    await _db
        .collection(AppConstants.killSwitchCollection)
        .doc(AppConstants.killSwitchDocument)
        .set({
      AppConstants.killSwitchField:    locked,
      AppConstants.killSwitchMsgField: message ?? AppConstants.killSwitchDefaultMsg,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
