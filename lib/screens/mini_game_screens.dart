// lib/screens/mini_game_screens.dart
// نسخ مبسطة: حجرة ورقة مقص (قابل للعب) + لودو (نرد + نقاط) + أونو (سحب/لعب مبسط)
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

// ─── حجرة ورقة مقص ─────────────────────────────────────────────────────────
class RpsGameScreen extends StatefulWidget {
  const RpsGameScreen({super.key});
  @override
  State<RpsGameScreen> createState() => _RpsGameScreenState();
}

class _RpsGameScreenState extends State<RpsGameScreen> {
  final _rng = Random();
  int _you = 0, _cpu = 0;
  String? _lastYou, _lastCpu, _msg;

  static const _labels = {'rock': 'حجرة ✊', 'paper': 'ورقة ✋', 'scissors': 'مقص ✌️'};

  void _play(String choice) {
    const opts = ['rock', 'paper', 'scissors'];
    final cpu = opts[_rng.nextInt(3)];
    String res;
    if (choice == cpu) {
      res = 'تعادل!';
    } else if (
        (choice == 'rock' && cpu == 'scissors') ||
        (choice == 'paper' && cpu == 'rock') ||
        (choice == 'scissors' && cpu == 'paper')) {
      res = 'فزت 🎉';
      _you++;
    } else {
      res = 'خسرت 😅';
      _cpu++;
    }
    setState(() {
      _lastYou = _labels[choice];
      _lastCpu = _labels[cpu];
      _msg = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('حجرة ورقة مقص', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _score('أنت', _you, AppColors.teal),
                _score('الخصم', _cpu, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            if (_lastYou != null)
              Text('$_lastYou  ←→  $_lastCpu',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white)),
            if (_msg != null) ...[
              const SizedBox(height: 12),
              Text(_msg!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
            const Spacer(),
            const Text('اختر حركتك', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn('rock', '✊'),
                _btn('paper', '✋'),
                _btn('scissors', '✌️'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _score(String t, int v, Color c) {
    return Column(
      children: [
        Text(t, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
        Text('$v', style: TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w900, color: c)),
      ],
    );
  }

  Widget _btn(String key, String emoji) {
    return GestureDetector(
      onTap: () => _play(key),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.gameRPS,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
      ),
    );
  }
}

// ─── لودو: نرد + مجموع النقاط ────────────────────────────────────────────────
class LudoLiteScreen extends StatefulWidget {
  const LudoLiteScreen({super.key});
  @override
  State<LudoLiteScreen> createState() => _LudoLiteScreenState();
}

class _LudoLiteScreenState extends State<LudoLiteScreen> {
  final _rng = Random();
  int _die = 1, _score = 0, _rolls = 0;

  void _roll() {
    setState(() {
      _die = _rng.nextInt(6) + 1;
      _score += _die;
      _rolls++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لودو (نرد + نقاط)', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('مجموع النقاط: $_score',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('عدد الرميات: $_rolls',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white60)),
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.gameLudo.withValues(alpha: 0.5), blurRadius: 20)],
              ),
              child: Text('$_die', style: TextStyle(fontFamily: 'Cairo', fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.gameLudo)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _roll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gameLudo,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text('رمي النرد 🎲', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() { _die = 1; _score = 0; _rolls = 0; }),
              child: const Text('تصفير', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── أونو مبسط: يد + سحب + لعب إن تطابق اللون أو الرقم ─────────────────────
class UnoLiteScreen extends StatefulWidget {
  const UnoLiteScreen({super.key});
  @override
  State<UnoLiteScreen> createState() => _UnoLiteScreenState();
}

class _UnoCard {
  final String color; // R G B Y
  final int n; // 0-9
  _UnoCard(this.color, this.n);
}

class _UnoLiteScreenState extends State<UnoLiteScreen> {
  final _rng = Random();
  late _UnoCard _top;
  final List<_UnoCard> _hand = [];

  static const _cols = ['R', 'G', 'B', 'Y'];

  _UnoCard _randomCard() => _UnoCard(_cols[_rng.nextInt(4)], _rng.nextInt(10));

  @override
  void initState() {
    super.initState();
    _top = _randomCard();
    for (var i = 0; i < 7; i++) _hand.add(_randomCard());
  }

  void _draw() => setState(() => _hand.add(_randomCard()));

  void _tryPlay(int i) {
    final c = _hand[i];
    if (c.color == _top.color || c.n == _top.n) {
      setState(() {
        _top = c;
        _hand.removeAt(i);
      });
    }
  }

  Color _col(String c) {
    switch (c) {
      case 'R': return Colors.red.shade600;
      case 'G': return Colors.green.shade600;
      case 'B': return Colors.blue.shade600;
      default: return Colors.amber.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('أونو (مبسط)', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text('الكرت على الطاولة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
          const SizedBox(height: 8),
          _cardBig(_top),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _draw,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameUno),
                child: const Text('سحب ➕', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          const Text('يدك — اضغط كرتاً يطابق اللون أو الرقم', style: TextStyle(fontFamily: 'Cairo', color: Colors.white60)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              itemCount: _hand.length,
              itemBuilder: (_, i) {
                final c = _hand[i];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _tryPlay(i),
                    child: _cardSmall(c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBig(_UnoCard c) {
    return Container(
      width: 100,
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _col(c.color),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text('${c.n}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }

  Widget _cardSmall(_UnoCard c) {
    return Container(
      width: 72,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _col(c.color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('${c.n}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}
