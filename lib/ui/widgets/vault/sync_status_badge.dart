import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'connect_cloud_dialog.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final vaultState = ref.watch(vaultNotifierProvider);
    final firebaseUser = ref.watch(firebaseUserProvider).asData?.value ?? FirebaseAuth.instance.currentUser;
    final isCloudConnected = firebaseUser != null;

    final IconData icon;
    final Color color;
    final String label;
    final String tooltip;

    if (!isCloudConnected) {
      icon = Icons.cloud_off_outlined;
      color = AppColors.warning;
      label = strings.localMode;
      tooltip = strings.tooltipLocalMode;
    } else {
      (icon, color, label, tooltip) = vaultState.when(
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
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            if (!isCloudConnected) {
              showConnectCloudDialog(context);
            } else {
              ref.read(vaultNotifierProvider.notifier).syncNow();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: !isCloudConnected ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: !isCloudConnected ? AppColors.warning : AppColors.textSecondary,
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


