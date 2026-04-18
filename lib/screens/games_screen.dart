// lib/screens/games_screen.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';
import 'mini_game_screens.dart';

class GamesScreen extends StatelessWidget {
  final ChatRoom room;
  final ChatUser me;
  const GamesScreen({super.key, required this.room, required this.me});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ),
                  const Spacer(),
                  const Text('ساحة الألعاب الواقعية',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(width: 10),
                  const Text('🎮', style: TextStyle(fontSize: 20)),
                  const Spacer(),
                  // Invites toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.teal),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('الدعوات: متاح',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.teal)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('اختر اللعبة لتحدي المتواجدين',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white60)),
            ),
            const SizedBox(height: 24),
            // Games list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _gameBtn(
                      context: context,
                      title: 'أونو 3D',
                      subtitle: 'طاولة مخملية وكروت حقيقية',
                      emoji: 'U',
                      emojiStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.red),
                      bg: AppColors.gameUno,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UnoLiteScreen()));
                      },
                    ),
                    const SizedBox(height: 14),
                    _gameBtn(
                      context: context,
                      title: 'لودو الخشبية',
                      subtitle: 'لوحة محفورة ونرد مجسم',
                      emoji: '🎲',
                      bg: AppColors.gameLudo,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LudoLiteScreen()));
                      },
                    ),
                    const SizedBox(height: 14),
                    _gameBtn(
                      context: context,
                      title: 'حجرة ورقة مقص',
                      subtitle: 'تحدي المهارة الكلاسيكي',
                      emoji: '✌️',
                      bg: AppColors.gameRPS,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RpsGameScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _gameBtn({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String emoji,
    TextStyle? emojiStyle,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: bg.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: 0, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: emojiStyle != null
                  ? Text(emoji, style: emojiStyle)
                  : Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(subtitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
