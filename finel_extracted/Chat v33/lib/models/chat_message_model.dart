// ─────────────────────────────────────────────
//  ChatMessage Model
// ─────────────────────────────────────────────

enum MessageType { text, system }

class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  /// The hex color string for this user's name (e.g. '#8B4513').
  /// Callers can pick a stable color from userId hash.
  final Color nameColor;

  /// Thin vertical bar color — driven by role/rank.
  final Color rankColor;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    required this.nameColor,
    required this.rankColor,
  });
}
