import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/ui/screens/splash/splash_screen.dart';
import 'package:budasswords/ui/screens/auth/login_screen.dart';
import 'package:budasswords/ui/screens/auth/setup_screen.dart';
import 'package:budasswords/ui/screens/vault/vault_screen.dart';
import 'package:budasswords/ui/screens/entry/entry_detail_screen.dart';
import 'package:budasswords/ui/screens/entry/entry_form_screen.dart';
import 'package:budasswords/ui/screens/settings/settings_screen.dart';
import 'package:budasswords/ui/screens/settings/import_screen.dart';
import 'package:budasswords/ui/screens/settings/export_screen.dart';
import 'package:budasswords/ui/screens/admin/admin_screen.dart';
import 'package:budasswords/domain/models/vault_entry.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild only when navigation-relevant fields change; error messages
  // must not recreate the router (that would remount the login screen).
  final (status, isAdmin) = ref.watch(authProvider
      .select((s) => (s.status, s.session?.isAdmin ?? false)));

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.matchedLocation;

      switch (status) {
        case AuthStatus.loading:
          return path == '/splash' ? null : '/splash';
        case AuthStatus.setup:
          return path == '/setup' ? null : '/setup';
        case AuthStatus.locked:
          return path == '/login' ? null : '/login';
        case AuthStatus.unlocked:
          if (path == '/splash' || path == '/login' || path == '/setup') {
            return '/vault';
          }
          if (path == '/admin' && !isAdmin) {
            return '/vault';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
      GoRoute(
        path: '/entry/:id',
        builder: (_, state) {
          final entry = state.extra as VaultEntry;
          return EntryDetailScreen(entry: entry);
        },
      ),
      GoRoute(
        path: '/entry-form',
        builder: (_, state) {
          final entry = state.extra as VaultEntry?;
          return EntryFormScreen(existingEntry: entry);
        },
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
      GoRoute(path: '/export', builder: (_, __) => const ExportScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    ],
  );
});
