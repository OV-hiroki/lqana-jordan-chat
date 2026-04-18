import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// معرف محادثة الدعم: لكل حساب Firebase أو لجهاز الزائر (`offline_user`) معرّف ثابت محلي.
class SupportConversationId {
  SupportConversationId._();

  static const _prefsKey = 'support_thread_conv_id_v1';

  static Future<String> resolve({required String authUid}) async {
    if (authUid.isNotEmpty && authUid != 'offline_user') {
      return authUid;
    }
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefsKey);
    if (id == null || id.isEmpty) {
      id = 'support_${_randomHex(16)}';
      await prefs.setString(_prefsKey, id);
    }
    return id;
  }

  static String _randomHex(int byteLength) {
    final r = Random.secure();
    final b = StringBuffer();
    for (var i = 0; i < byteLength; i++) {
      b.write(r.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return b.toString();
  }
}
