import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budasswords/data/local/database.dart';
import 'package:budasswords/data/local/daos/vault_dao.dart';
import 'package:budasswords/data/remote/firebase_vault_api.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/ui/router/app_router.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

class _MockApi extends Mock implements FirebaseVaultApi {}

void main() {
  test('a failed unlock keeps the same router (login screen is not rebuilt)', () async {
    final storage = _MockStorage();
    // Existing vault: salt present, so the app starts locked.
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => 'aa');
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      authProvider.overrideWith((ref) => AuthNotifier(storage, VaultDao(db), _MockApi())),
    ]);
    addTearDown(container.dispose);

    container.read(authProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authProvider).status, AuthStatus.locked);

    final routerBefore = container.read(appRouterProvider);

    // Wrong master password: only the error changes, status stays locked.
    expect(await container.read(authProvider.notifier).unlock('wrong'), isFalse);
    expect(container.read(authProvider).status, AuthStatus.locked);

    expect(identical(container.read(appRouterProvider), routerBefore), isTrue);
  });
}
