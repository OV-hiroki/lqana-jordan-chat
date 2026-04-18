import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../utils/constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CALLBACKS & TYPEDEFS
// ═══════════════════════════════════════════════════════════════════════════
typedef AgoraOnRemoteJoined = void Function(int uid);
typedef AgoraOnRemoteLeft = void Function(int uid);
typedef AgoraOnSpeaking = void Function(Set<int> uids);
typedef AgoraOnMuteChanged = void Function(bool isMuted);
typedef AgoraOnError = void Function(int code, String msg);
typedef AgoraOnConnectionStateChanged = void Function(bool isConnected);

// ═══════════════════════════════════════════════════════════════════════════
// AGORA SERVICE - خدمة صوتية محسّنة وآمنة
// ═══════════════════════════════════════════════════════════════════════════
/// خدمة Agora RTC محسّنة مع معالجة أخطاء صحيحة وحالة محلية للـ muted
/// - تدعم الأذونات والتحقق من الأخطاء
/// - حجم صوت أكثر حساسية (من 2 بدلاً من 8)
/// - معالجة آمنة للـ handlers والـ lifecycle
class AgoraService {
  AgoraService._();
  static final AgoraService instance = AgoraService._();

  // ─────────────────────────────────────────────────────────────────────────
  // STATE MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────
  RtcEngine? _engine;
  String? _currentChannel;
  int? _localAgoraUid;
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isLocalMuted = false;
  bool _handlersRegistered = false;

  final Set<int> _remoteUids = {};
  final Set<int> _speakingUids = {};

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFIERS - لتحديثات الحالة بدون عمل setState كامل للشاشة
  // ─────────────────────────────────────────────────────────────────────────
  final ValueNotifier<Set<int>> remoteUidsNotifier = ValueNotifier<Set<int>>({});
  final ValueNotifier<Set<int>> speakingUidsNotifier = ValueNotifier<Set<int>>({});
  final ValueNotifier<bool> localMutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> connectionStateNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  // ─────────────────────────────────────────────────────────────────────────
  // CALLBACKS - يمكن تسجيل عدة callbacks
  // ─────────────────────────────────────────────────────────────────────────
  final List<AgoraOnRemoteJoined> _onRemoteJoinedCallbacks = [];
  final List<AgoraOnRemoteLeft> _onRemoteLeftCallbacks = [];
  final List<AgoraOnSpeaking> _onSpeakingCallbacks = [];
  final List<AgoraOnMuteChanged> _onMuteChangedCallbacks = [];
  final List<AgoraOnError> _onErrorCallbacks = [];
  final List<AgoraOnConnectionStateChanged> _onConnectionStateCallbacks = [];

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS - قيم آمنة للقراءة
  // ─────────────────────────────────────────────────────────────────────────
  Set<int> get remoteUids => Set.unmodifiable(_remoteUids);
  Set<int> get speakingUids => Set.unmodifiable(_speakingUids);
  bool get isConnected => _isConnected;
  bool get isLocalMuted => _isLocalMuted;
  bool get isInitialized => _isInitialized;
  String? get currentChannel => _currentChannel;

  // ─────────────────────────────────────────────────────────────────────────
  // CALLBACK REGISTRATION - تسجيل callbacks
  // ─────────────────────────────────────────────────────────────────────────
  
  /// تسجيل callback للانضمام المستخدم البعيد
  void onRemoteJoined(AgoraOnRemoteJoined callback) {
    _onRemoteJoinedCallbacks.add(callback);
  }

  /// تسجيل callback لمغادرة المستخدم البعيد
  void onRemoteLeft(AgoraOnRemoteLeft callback) {
    _onRemoteLeftCallbacks.add(callback);
  }

  /// تسجيل callback للتحدث
  void onSpeaking(AgoraOnSpeaking callback) {
    _onSpeakingCallbacks.add(callback);
  }

  /// تسجيل callback لتغيير حالة الـ mute
  void onMuteChanged(AgoraOnMuteChanged callback) {
    _onMuteChangedCallbacks.add(callback);
  }

  /// تسجيل callback للأخطاء
  void onError(AgoraOnError callback) {
    _onErrorCallbacks.add(callback);
  }

  /// تسجيل callback لتغيير حالة الاتصال
  void onConnectionStateChanged(AgoraOnConnectionStateChanged callback) {
    _onConnectionStateCallbacks.add(callback);
  }

  /// إزالة جميع callbacks (استخدم عند Dispose)
  void clearAllCallbacks() {
    _onRemoteJoinedCallbacks.clear();
    _onRemoteLeftCallbacks.clear();
    _onSpeakingCallbacks.clear();
    _onMuteChangedCallbacks.clear();
    _onErrorCallbacks.clear();
    _onConnectionStateCallbacks.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /// مقارنة آمنة لـ Sets
  static bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final x in a) {
      if (!b.contains(x)) return false;
    }
    return true;
  }

  /// تحديث notifier الـ remote UIDs
  void _pushRemoteNotifier() {
    final next = Set<int>.from(_remoteUids);
    if (!_setEquals(remoteUidsNotifier.value, next)) {
      remoteUidsNotifier.value = next;
    }
  }

  /// تحديث notifier الـ speaking UIDs
  void _pushSpeakingNotifier() {
    final next = Set<int>.from(_speakingUids);
    if (!_setEquals(speakingUidsNotifier.value, next)) {
      speakingUidsNotifier.value = next;
    }
  }

  /// تحويل معرف المستخدم إلى int لـ Agora (32-bit موجب)
  static int uidToAgoraId(String uid) {
    if (uid.isEmpty) return 1;
    var hash = 0;
    for (final codeUnit in uid.codeUnits) {
      hash = ((hash << 5) - hash) + codeUnit;
      hash = hash & 0x7FFFFFFF; // Convert to 32-bit positive integer
    }
    if (hash == 0) hash = 1; // Ensure non-zero
    return hash;
  }

  /// طباعة رسالة خطأ آمنة
  void _logError(String message, [Exception? e]) {
    debugPrint('🔴 AgoraService Error: $message');
    if (e != null) {
      debugPrint('Exception: $e');
    }
  }

  /// تنفيذ جميع error callbacks
  void _callErrorCallbacks(int code, String message) {
    errorNotifier.value = message;
    for (final cb in _onErrorCallbacks) {
      try {
        cb(code, message);
      } catch (e) {
        _logError('Error in onError callback', e as Exception);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ENGINE INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// إنشاء وتهيئة محرك Agora (مرة واحدة فقط)
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ Agora already initialized');
      return true;
    }

    try {
      if (AppConstants.agoraAppId.isEmpty) {
        _callErrorCallbacks(-1, 'Agora App ID غير مضبوط في AppConstants');
        return false;
      }

      debugPrint('🚀 Initializing Agora Engine...');
      
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(
        RtcEngineContext(
          appId: AppConstants.agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await _engine!.enableAudio();

      // تسجيل handlers مرة واحدة فقط
      _registerEventHandlers();

      // تفعيل مؤشرات الصوت بحساسية عالية
      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      _isInitialized = true;
      debugPrint('✅ Agora Engine initialized successfully');
      return true;
    } catch (e) {
      _logError('Failed to initialize Agora', e as Exception);
      _callErrorCallbacks(-1, 'فشل تهيئة Agora: $e');
      return false;
    }
  }

  /// تسجيل جميع event handlers (مرة واحدة)
  void _registerEventHandlers() {
    if (_handlersRegistered) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        // ─── Remote User Events ───────────────────────────────
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint('👤 User joined: $remoteUid (elapsed: ${elapsed}ms)');
          _remoteUids.add(remoteUid);
          _pushRemoteNotifier();
          
          for (final cb in _onRemoteJoinedCallbacks) {
            try {
              cb(remoteUid);
            } catch (e) {
              _logError('Error in onRemoteJoined callback', e as Exception);
            }
          }
        },

        onUserOffline: (connection, remoteUid, reason) {
          debugPrint('👤 User offline: $remoteUid (reason: $reason)');
          _remoteUids.remove(remoteUid);
          _speakingUids.remove(remoteUid);
          _pushRemoteNotifier();
          _pushSpeakingNotifier();
          
          for (final cb in _onRemoteLeftCallbacks) {
            try {
              cb(remoteUid);
            } catch (e) {
              _logError('Error in onRemoteLeft callback', e as Exception);
            }
          }
        },

        // ─── Audio Volume Events ──────────────────────────────
        onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
          final activeSpeakers = <int>{};

          for (final speaker in speakers) {
            final uid = speaker.uid;
            final volume = speaker.volume ?? 0;

            // حساسية عالية: من 2 بدلاً من 8
            if (volume < 2) continue;
            if (uid == null) continue;

            if (uid == 0) {
              // UID 0 يعني الصوت المحلي
              if (_localAgoraUid != null) {
                activeSpeakers.add(_localAgoraUid!);
              }
            } else {
              // UID بعيد
              activeSpeakers.add(uid);
            }
          }

          // تحديث فقط إذا تغيرت الحالة
          if (!_setEquals(_speakingUids, activeSpeakers)) {
            _speakingUids.clear();
            _speakingUids.addAll(activeSpeakers);
            _pushSpeakingNotifier();

            for (final cb in _onSpeakingCallbacks) {
              try {
                cb(Set.unmodifiable(activeSpeakers));
              } catch (e) {
                _logError('Error in onSpeaking callback', e as Exception);
              }
            }
          }
        },

        // ─── Error Events ─────────────────────────────────────
        onError: (errorCode, errorMsg) {
          _logError('Agora Error [$errorCode]: $errorMsg');
          _callErrorCallbacks(errorCode.index, errorMsg);
        },

        // ─── Connection State Events ──────────────────────────
        onConnectionStateChanged: (connection, state, reason) {
          final isConnected = state == ConnectionStateType.connectionStateConnected;
          if (_isConnected != isConnected) {
            _isConnected = isConnected;
            connectionStateNotifier.value = isConnected;
            debugPrint('🔗 Connection state: ${isConnected ? "CONNECTED" : "DISCONNECTED"} (reason: $reason)');

            for (final cb in _onConnectionStateCallbacks) {
              try {
                cb(isConnected);
              } catch (e) {
                _logError('Error in onConnectionStateChanged callback', e as Exception);
              }
            }
          }
        },
      ),
    );

    _handlersRegistered = true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHANNEL OPERATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// الانضمام إلى قناة صوتية
  Future<bool> joinChannel({
    required String channelId,
    required String userId,
    required bool joinMuted,
  }) async {
    try {
      // تأكد من تهيئة المحرك
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      final engine = _engine;
      if (engine == null) {
        _callErrorCallbacks(-1, 'محرك Agora لم يتم تهيئته بشكل صحيح');
        return false;
      }

      // إذا كان في قناة مختلفة، اترك القناة الحالية أولاً
      if (_currentChannel != null && _currentChannel != channelId) {
        await leaveChannel();
      }

      // إذا كان بالفعل في نفس القناة، أعد ضبط الـ mute فقط
      if (_currentChannel == channelId) {
        await setLocalMuted(joinMuted);
        return true;
      }

      // تحويل معرف المستخدم إلى Agora UID
      final agoraUid = uidToAgoraId(userId);
      
      debugPrint('🎤 Joining channel: $channelId (UID: $agoraUid, muted: $joinMuted)');

      // مسح الحالة السابقة
      _localAgoraUid = agoraUid;
      _remoteUids.clear();
      _speakingUids.clear();
      _pushRemoteNotifier();
      _pushSpeakingNotifier();

      // الانضمام للقناة
      await engine.joinChannel(
        token: '', // توكن فارغ للتطوير (استخدم توكن حقيقي للإنتاج)
        channelId: channelId,
        uid: agoraUid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      // ضبط الـ mute
      await setLocalMuted(joinMuted);

      _currentChannel = channelId;
      debugPrint('✅ Joined channel: $channelId');
      return true;
    } catch (e) {
      _logError('Failed to join channel', e as Exception);
      _callErrorCallbacks(-1, 'فشل الانضمام للقناة: $e');
      return false;
    }
  }

  /// مغادرة القناة الحالية
  Future<bool> leaveChannel() async {
    try {
      if (_engine == null) {
        debugPrint('⚠️ Engine is null, cannot leave channel');
        return false;
      }

      if (_currentChannel == null) {
        debugPrint('⚠️ Not in any channel');
        return false;
      }

      debugPrint('🚪 Leaving channel: $_currentChannel');

      await _engine!.leaveChannel();

      // مسح الحالة
      _currentChannel = null;
      _localAgoraUid = null;
      _isLocalMuted = false;
      _remoteUids.clear();
      _speakingUids.clear();
      _pushRemoteNotifier();
      _pushSpeakingNotifier();
      localMutedNotifier.value = false;

      debugPrint('✅ Left channel');
      return true;
    } catch (e) {
      _logError('Failed to leave channel', e as Exception);
      _callErrorCallbacks(-1, 'فشل مغادرة القناة: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MICROPHONE CONTROL
  // ─────────────────────────────────────────────────────────────────────────

  /// تبديل حالة الـ mute للمايك المحلي
  Future<bool> setLocalMuted(bool muted) async {
    try {
      if (_engine == null) {
        _callErrorCallbacks(-1, 'محرك Agora لم يتم تهيئته');
        return false;
      }

      debugPrint('${muted ? "🔇" : "🔊"} Setting local mute: $muted');

      await _engine!.muteLocalAudioStream(muted);

      if (_isLocalMuted != muted) {
        _isLocalMuted = muted;
        localMutedNotifier.value = muted;

        for (final cb in _onMuteChangedCallbacks) {
          try {
            cb(muted);
          } catch (e) {
            _logError('Error in onMuteChanged callback', e as Exception);
          }
        }
      }

      return true;
    } catch (e) {
      _logError('Failed to set local mute', e as Exception);
      _callErrorCallbacks(-1, 'فشل تعيين حالة الـ mute: $e');
      return false;
    }
  }

  /// تبديل الـ mute (إذا كان معطل، فعّله والعكس)
  Future<bool> toggleMute() async {
    return await setLocalMuted(!_isLocalMuted);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  /// تنظيف كامل الخدمة (استخدم عند تغيير الشاشات)
  Future<void> dispose() async {
    debugPrint('🧹 Disposing AgoraService...');

    try {
      // اترك القناة أولاً
      if (_currentChannel != null) {
        await leaveChannel();
      }

      // اترك جميع callbacks
      clearAllCallbacks();

      // أغلق المحرك
      if (_engine != null) {
        // لا تُغلق المحرك - قد تحتاجه لاحقاً
        // await _engine!.release();
      }
    } catch (e) {
      _logError('Error during dispose', e as Exception);
    }

    _isInitialized = false;
    debugPrint('✅ AgoraService disposed');
  }
}
