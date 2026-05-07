import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

final _syncStatusProvider = StateProvider<_SyncStatus>((ref) => _SyncStatus.synced);

enum _SyncStatus { synced, syncing, error }

/// Small badge in the AppBar showing real-time sync state.
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(_syncStatusProvider);

    final (icon, color) = switch (status) {
      _SyncStatus.synced  => (Icons.cloud_done_outlined, AppColors.success),
      _SyncStatus.syncing => (Icons.sync, AppColors.accentSoft),
      _SyncStatus.error   => (Icons.cloud_off_outlined, AppColors.danger),
    };

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
