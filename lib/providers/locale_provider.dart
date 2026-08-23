import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:budasswords/core/localization/app_strings.dart';

const _kLanguageKey = 'bud_app_language';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class LocaleNotifier extends StateNotifier<AppLocale> {
  final FlutterSecureStorage _storage;

  LocaleNotifier(this._storage) : super(AppLocale.es) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final saved = await _storage.read(key: _kLanguageKey);
      if (saved == 'en') {
        state = AppLocale.en;
      } else if (saved == 'es') {
        state = AppLocale.es;
      }
    } catch (_) {}
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    try {
      await _storage.write(
        key: _kLanguageKey,
        value: locale == AppLocale.en ? 'en' : 'es',
      );
    } catch (_) {}
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocaleNotifier(storage);
});

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings.of(locale);
});
