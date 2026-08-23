import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final vaultState = ref.watch(vaultNotifierProvider);

    final (icon, color, label, tooltip) = vaultState.when(
      data: (_) => (
        Icons.cloud_done_outlined,
        AppColors.success,
        strings.cloudActive,
        strings.tooltipCloudActive,
      ),
      loading: () => (
        Icons.sync,
        AppColors.accent,
        strings.syncing,
        strings.tooltipSyncing,
      ),
      error: (_, __) => (
        Icons.cloud_off_outlined,
        AppColors.danger,
        strings.localMode,
        strings.tooltipLocalMode,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            ref.read(vaultNotifierProvider.notifier).pushDirtyToRemote().then((_) {
              ref.read(vaultNotifierProvider.notifier).pullFromRemote();
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


