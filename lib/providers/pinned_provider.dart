import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class PinnedNotifier extends StateNotifier<Map<String, int>> {
  PinnedNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var str = prefs.getString(AppConstants.kPinnedKey);

    // Auto-migrate legacy entries from FlutterSecureStorage
    if (str == null) {
      try {
        const secureStorage = FlutterSecureStorage();
        str = await secureStorage.read(key: AppConstants.kPinnedKey);
        if (str != null) {
          await prefs.setString(AppConstants.kPinnedKey, str);
          await secureStorage.delete(key: AppConstants.kPinnedKey);
        }
      } catch (_) {}
    }

    if (str != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(str);
        final typedMap = map.map((k, v) => MapEntry(k, v as int));
        state = typedMap;
      } catch (_) {}
    }
  }

  Future<void> togglePin(String id) async {
    final newState = Map<String, int>.from(state);
    if (newState.containsKey(id)) {
      newState.remove(id);
    } else {
      newState[id] = DateTime.now().millisecondsSinceEpoch;
    }
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kPinnedKey, jsonEncode(newState));
  }

  Future<void> toggleMultiple(List<String> ids) async {
    final newState = Map<String, int>.from(state);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var id in ids) {
      if (newState.containsKey(id)) {
        newState.remove(id);
      } else {
        newState[id] = now;
      }
    }
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kPinnedKey, jsonEncode(newState));
  }
}

final pinnedProvider = StateNotifierProvider<PinnedNotifier, Map<String, int>>((ref) {
  return PinnedNotifier();
});
