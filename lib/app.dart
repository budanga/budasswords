import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/router/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/core/localization/app_strings.dart';

class BudasswordsApp extends ConsumerStatefulWidget {
  const BudasswordsApp({super.key});

  @override
  ConsumerState<BudasswordsApp> createState() => _BudasswordsAppState();
}

class _BudasswordsAppState extends ConsumerState<BudasswordsApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.unlocked) {
          ref.read(authProvider.notifier).lock();
        }
      },
      onHide: () {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.unlocked) {
          ref.read(authProvider.notifier).lock();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return Listener(
      onPointerDown: (_) => ref.read(authProvider.notifier).resetAutolock(),
      child: MaterialApp.router(
        title: 'Budasswords',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: Locale(locale == AppLocale.en ? 'en' : 'es'),
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}


