import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/router/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'package:budasswords/providers/auth_provider.dart';

class BudasswordsApp extends ConsumerWidget {
  const BudasswordsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return Listener(
      onPointerDown: (_) => ref.read(authProvider.notifier).resetAutolock(),
      child: MaterialApp.router(
        title: 'Budasswords',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
