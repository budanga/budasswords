import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class PinnedNotifier extends StateNotifier<Map<String, int>> {
  final FlutterSecureStorage _storage;

  PinnedNotifier(this._storage) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final str = await _storage.read(key: AppConstants.kPinnedKey);
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
    await _storage.write(key: AppConstants.kPinnedKey, value: jsonEncode(newState));
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
    await _storage.write(key: AppConstants.kPinnedKey, value: jsonEncode(newState));
  }
}

final pinnedProvider = StateNotifierProvider<PinnedNotifier, Map<String, int>>((ref) {
  return PinnedNotifier(const FlutterSecureStorage());
});
