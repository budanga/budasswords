import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/vault_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultNotifierProvider);

    final (icon, color) = vaultState.when(
      data: (_) => (Icons.cloud_done_outlined, AppColors.success),
      loading: () => (Icons.sync, AppColors.accentSoft),
      error: (_, __) => (Icons.cloud_off_outlined, AppColors.danger),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: vaultState.maybeWhen(
          error: (e, _) => 'Sync error: $e',
          loading: () => 'Syncing...',
          orElse: () => 'Synchronized',
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
