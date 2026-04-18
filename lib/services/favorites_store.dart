// lib/services/favorites_store.dart
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const _key = 'favorite_room_ids';

  static Future<List<String>> load() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_key) ?? [];
  }

  static Future<void> save(List<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, ids);
  }

  static Future<bool> toggle(String roomId) async {
    final list = await load();
    if (list.contains(roomId)) {
      list.remove(roomId);
    } else {
      list.add(roomId);
    }
    await save(list);
    return list.contains(roomId);
  }

  static Future<bool> isFavorite(String roomId) async {
    final list = await load();
    return list.contains(roomId);
  }
}
