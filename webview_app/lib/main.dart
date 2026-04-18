// lib/main.dart — لقانا WebView App
// يشغّل index.html بالكامل جوا WebView مع دعم FCM
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🔑  ضع هنا إعدادات Firebase الخاصة بك
// ─────────────────────────────────────────────────────────────────────────────
const _firebaseOptions = FirebaseOptions(
  apiKey:            'AIzaSyBM9INHqmXL5q9FGsjhAyhrQqGD2Nf5oRc',
  appId:             '1:862693534141:android:XXXXXXXXXXXXXXXX',  // ← غيّر هذا
  messagingSenderId: '862693534141',
  projectId:         'jordan-audio-final',
  storageBucket:     'jordan-audio-final.appspot.com',
);

// Background FCM Handler
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(options: _firebaseOptions);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة شاشة الجهاز (Portrait فقط)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Firebase
  try {
    await Firebase.initializeApp(options: _firebaseOptions);
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
  } catch (_) {}

  runApp(const LqanaApp());
}

class LqanaApp extends StatelessWidget {
  const LqanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لقانا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF26C6DA)),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash Screen
// ─────────────────────────────────────────────────────────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();

    // بعد 2 ثانية انتقل للـ WebView
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WebViewPage(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        ));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF26C6DA), Color(0xFF0097A7), Color(0xFF006064)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شعار التطبيق
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Center(
                      child: Text('لقانا', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: Color(0xFF006064),
                        fontFamily: 'Cairo',
                      )),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('لقانا الأردن شات',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white, fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  const Text('شات صوتي عربي 🎤',
                    style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Cairo')),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 32, height: 32,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WebView Page — يشغّل index.html
// ─────────────────────────────────────────────────────────────────────────────
class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _setupFCM();
  }

  Future<void> _initWebView() async {
    // قراءة index.html من الـ assets
    final htmlContent = await rootBundle.loadString('assets/web/index.html');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { _loading = true; _hasError = false; }),
        onProgress: (p) => setState(() => _loadProgress = p),
        onPageFinished: (_) {
          setState(() => _loading = false);
          // أرسل FCM token للـ JS
          _sendFcmTokenToWeb();
        },
        onWebResourceError: (e) {
          setState(() { _loading = false; _hasError = true; });
        },
        // السماح للروابط الخارجية
        onNavigationRequest: (req) {
          if (req.url.startsWith('http') && !req.url.contains('localhost')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.navigate;
        },
      ))
      // ─── JavaScript Channels ───────────────────────────────────────────
      // يسمح للـ JS بالتواصل مع Flutter
      ..addJavaScriptChannel('FlutterBridge', onMessageReceived: _handleJsMessage)
      // تحميل الـ HTML مباشرة من الـ assets (بدون سيرفر)
      ..loadHtmlString(htmlContent, baseUrl: 'https://jordan-audio-final.web.app');

    if (mounted) setState(() {});
  }

  // ─── إرسال FCM Token للويب ─────────────────────────────────────────────────
  Future<void> _sendFcmTokenToWeb() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _controller.runJavaScript(
          "window.fcmToken = '$token'; "
          "if(window.onFcmTokenReceived) window.onFcmTokenReceived('$token');"
        );
      }
    } catch (_) {}
  }

  // ─── استقبال رسائل من JS ───────────────────────────────────────────────────
  void _handleJsMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message);
      final action = data['action'] as String?;

      switch (action) {
        case 'showNotification':
          _showLocalNotification(data['title'] ?? '', data['body'] ?? '');
          break;
        case 'vibrate':
          HapticFeedback.mediumImpact();
          break;
        case 'copyText':
          Clipboard.setData(ClipboardData(text: data['text'] ?? ''));
          break;
        case 'fullscreen':
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          break;
        case 'exitFullscreen':
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          break;
      }
    } catch (_) {}
  }

  void _showLocalNotification(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            Text(body, style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          ],
        ),
        backgroundColor: const Color(0xFF26C6DA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── FCM Setup ─────────────────────────────────────────────────────────────
  Future<void> _setupFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

      // رسائل Foreground
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n != null) _showLocalNotification(n.title ?? '', n.body ?? '');
      });

      // عند النقر على الإشعار
      FirebaseMessaging.instance.getInitialMessage().then((msg) {
        if (msg != null) _handleFcmTap(msg);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmTap);
    } catch (_) {}
  }

  void _handleFcmTap(RemoteMessage msg) {
    // يمكنك هنا navigate لغرفة معينة
    final roomId = msg.data['roomId'];
    if (roomId != null && mounted) {
      _controller.runJavaScript("window.openRoom && window.openRoom('$roomId');");
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // زر الرجوع يتحكم به الويب أولاً
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          await _controller.goBack();
        } else {
          // اسأل المستخدم للخروج
          if (mounted) _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ─── WebView ──────────────────────────────────────────────────
            if (!_hasError)
              WebViewWidget(controller: _controller),

            // ─── شاشة الخطأ ───────────────────────────────────────────────
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('لا يوجد اتصال بالإنترنت',
                        style: TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('تأكد من اتصالك بالإنترنت وأعد المحاولة',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Cairo')),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _controller.reload(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26C6DA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Loading Progress Bar ──────────────────────────────────────
            if (_loading)
              Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  value: _loadProgress / 100,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF26C6DA),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('الخروج من التطبيق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: const Text('هل تريد الخروج من لقانا؟', style: TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لا', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26C6DA)),
              child: const Text('نعم، خروج', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
