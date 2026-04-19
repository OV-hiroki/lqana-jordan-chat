import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شاشة كاملة بدون status bar — نفس إحساس التطبيق الأصلي
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Portrait فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LqanaApp());
}

class LqanaApp extends StatelessWidget {
  const LqanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لقانا الأردن شات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SplashGate(),
    );
  }
}

// ─── Splash: نطلب الصلاحيات قبل ما نفتح الـ WebView ──────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // نطلب المايك هنا على مستوى Android — مش WebView
    await Permission.microphone.request();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatWebViewPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF7ED9C3),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لقانا',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── الصفحة الرئيسية: WebView محسّن بالكامل ──────────────────────────────────
class ChatWebViewPage extends StatefulWidget {
  const ChatWebViewPage({super.key});

  @override
  State<ChatWebViewPage> createState() => _ChatWebViewPageState();
}

class _ChatWebViewPageState extends State<ChatWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  void _setupWebView() {
    _controller = WebViewController()
      // JavaScript ضروري للـ React
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // خلفية سوداء عشان ما يومضش أبيض وقت التحميل
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      // منع الـ navigation لروابط خارجية
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (req) {
            // خليه يفتح الـ HTML بس — أي رابط تاني يتجاهله
            if (req.url.startsWith('file://') ||
                req.url.startsWith('about:') ||
                req.url.contains('assets/html')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      // ─── إعدادات Android المهمة ───────────────────────────────────────────
      ..loadFlutterAsset('assets/html/index.html');

    // الإعدادات الخاصة بـ Android — دي اللي بتحل مشكلة الأنيميشن والمايك
    if (_controller.platform is AndroidWebViewController) {
      final androidCtrl = _controller.platform as AndroidWebViewController;

      // ✅ 1. تشغيل الصوت بدون ما المستخدم يضغط زرار
      androidCtrl.setMediaPlaybackRequiresUserGesture(false);

      // ✅ 2. السماح بصلاحيات المايك من داخل الـ WebView
      androidCtrl.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back button يرجع لصفحة سابقة في الـ WebView مش يخرج من التطبيق
      canPop: false,
      onPopInvoked: (didPop) async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              // Loading indicator أثناء تحميل الـ HTML
              if (_isLoading)
                const ColoredBox(
                  color: Color(0xFF7ED9C3),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'لقانا',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        CircularProgressIndicator(color: Colors.white),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
