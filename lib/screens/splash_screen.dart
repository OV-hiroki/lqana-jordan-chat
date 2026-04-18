// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/firebase_service.dart';
import 'lobby_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;
  StreamSubscription<Map<String, dynamic>>? _remoteSub;
  bool _blocked = false;
  String _blockMsg = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _ring = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    final svc = FirebaseService();
    _remoteSub = svc.sysConfigStream('global_config').listen((d) {
      if (!mounted || d.isEmpty) return;
      final blocked = d['isLocked'] == true;
      if (blocked) {
        setState(() {
          _blocked = true;
          _blockMsg = (d['lockMessage'] ?? 'التطبيق في وضع الصيانة').toString();
        });
      }
    });
    _init();
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
    final once = await FirebaseService().getSysConfigOnce('global_config');
    if (once['isLocked'] == true) {
      if (mounted) {
        setState(() {
          _blocked = true;
          _blockMsg = (once['lockMessage'] ?? 'التطبيق في وضع الصيانة').toString();
        });
      }
      return;
    }
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _blocked) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LobbyScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 56),
                const SizedBox(height: 20),
                Text(_blockMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 17, color: Colors.white, height: 1.4)),
                const SizedBox(height: 16),
                Text(
                  'أنشئ المستند remote_app في المجموعة sys_config (نفس مسار بياناتك) للتحكم من المشروع الأصلي.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated pulse circle (نفس الشاشة بالضبط)
            SizedBox(
              width: 130,
              height: 130,
              child: AnimatedBuilder(
                animation: _ring,
                builder: (_, __) => CustomPaint(
                  painter: _PulsePainter(_ring.value),
                  child: Container(
                    margin: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navyMid,
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.monitor_heart_outlined,
                        color: AppColors.teal,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'جاري الاتصال...',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'يتم تجميع البيانات وتشفير الاتصال',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.teal.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  _PulsePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rotating arc
    final paint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -1.5708 + progress * 6.2832,
      1.2,
      false,
      paint,
    );

    // Dim arc
    final dimPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 4, dimPaint);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}
