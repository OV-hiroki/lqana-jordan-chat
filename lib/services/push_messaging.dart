// lib/services/push_messaging.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import 'firebase_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService instance = PushMessagingService._();

  String? _lastToken;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      _lastToken = await messaging.getToken();
    } catch (_) {}

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _lastToken = t;
    });
  }

  /// يُستدعى بعد معرفة معرف المستخدم في الغرفة (مثلاً guest_… أو reg_…).
  Future<void> syncTokenToProfile(String userId) async {
    final t = _lastToken ?? await FirebaseMessaging.instance.getToken();
    if (t == null || t.isEmpty) return;
    _lastToken = t;
    await FirebaseService().savePushToken(userId, t);
  }
}
