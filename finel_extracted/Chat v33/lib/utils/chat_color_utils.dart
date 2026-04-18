import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ChatColorUtils
//  Deterministic color assignment from a userId
//  so the same user always gets the same name
//  color, even across app restarts.
// ─────────────────────────────────────────────

class ChatColorUtils {
  ChatColorUtils._();

  /// Palette of distinct, readable name colors.
  static const List<Color> _nameColors = [
    Color(0xFF6A1B9A), // deep purple
    Color(0xFF1565C0), // deep blue
    Color(0xFF8B4513), // saddle brown
    Color(0xFF2E7D32), // dark green
    Color(0xFFC62828), // dark red
    Color(0xFF00838F), // teal
    Color(0xFF4527A0), // indigo
    Color(0xFFAD1457), // pink
    Color(0xFF558B2F), // olive green
    Color(0xFF0277BD), // light blue
  ];

  /// Rank/role → vertical bar color.
  static const Map<String, Color> rankColors = {
    'master':     Color(0xFFE53935), // red
    'superadmin': Color(0xFFFF6F00), // amber-orange
    'admin':      Color(0xFFFFB300), // gold
    'member':     Color(0xFF42A5F5), // blue
    'guest':      Color(0xFF9E9E9E), // grey
  };

  /// Returns a stable name color for [userId].
  static Color nameColorFor(String userId) {
    final hash = userId.codeUnits.fold(0, (a, b) => a + b);
    return _nameColors[hash % _nameColors.length];
  }

  /// Returns the bar color for a given [role] string.
  static Color rankColorFor(String role) {
    return rankColors[role.toLowerCase()] ?? const Color(0xFF9E9E9E);
  }

  /// Convenience: build a [ChatMessage]-ready color pair from
  /// a Firestore document map.
  static ({Color nameColor, Color rankColor}) colorsForUser({
    required String userId,
    required String role,
  }) {
    return (
      nameColor: nameColorFor(userId),
      rankColor: rankColorFor(role),
    );
  }
}
