import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/constants/app_constants.dart';
import 'package:budasswords/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _localTimeout;

  final List<int> _intervals = [1, 5, 10, 15, 30, 45, 60, 90, 120, 180];

  String _formatTimeout(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes == 60) return '1 hour';
    if (minutes == 90) return '1.5 hours';
    if (minutes == 120) return '2 hours';
    if (minutes == 180) return '3 hours';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider.notifier);
    final timeout = _localTimeout ?? auth.timeoutMinutes;

    // Find closest interval index for the slider
    int currentIndex = _intervals.indexOf(timeout);
    if (currentIndex == -1) {
      // Fallback: find nearest
      currentIndex = 0;
      int minDiff = (timeout - _intervals[0]).abs();
      for (int i = 1; i < _intervals.length; i++) {
        int diff = (timeout - _intervals[i]).abs();
        if (diff < minDiff) {
          minDiff = diff;
          currentIndex = i;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto-lock
          _SettingCard(
            icon: Icons.lock_clock_outlined,
            title: 'Auto-lock timeout',
            subtitle: _formatTimeout(timeout),
            child: Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (_intervals.length - 1).toDouble(),
              divisions: _intervals.length - 1,
              activeColor: AppColors.accent,
              label: _formatTimeout(_intervals[currentIndex]),
              onChanged: (v) {
                setState(() => _localTimeout = _intervals[v.toInt()]);
              },
              onChangeEnd: (v) {
                auth.updateTimeout(_intervals[v.toInt()]);
              },
            ),
          ).animate().fadeIn(),
          const Gap(8),

          // Lock now
          _SettingCard(
            icon: Icons.lock_outline,
            title: 'Lock vault now',
            subtitle: 'Require master password to re-open',
            onTap: () {
              ref.read(authProvider.notifier).lock();
              context.go('/login');
            },
          ).animate(delay: 60.ms).fadeIn(),
          const Gap(8),

          // Import from Bitwarden
          _SettingCard(
            icon: Icons.download_outlined,
            title: 'Import from Bitwarden',
            subtitle: 'Migrate passwords via JSON file',
            onTap: () => context.push('/import'),
          ).animate(delay: 120.ms).fadeIn(),
          const Gap(8),

          // Sign out
          _SettingCard(
            icon: Icons.logout,
            title: 'Sign out',
            subtitle: 'Clears all local data and keys',
            titleColor: AppColors.danger,
            onTap: () => _confirmSignOut(context),
          ).animate(delay: 180.ms).fadeIn(),
          const Gap(32),

          // App info
          const Center(
            child: Text(
              'Budasswords v1.0.0\nEnd-to-end encrypted · AES-256-GCM · Argon2id',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Sign out?'),
        content: const Text(
          'This will delete all local data and keys. '
          'Your encrypted vault remains on Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Widget? child;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor = AppColors.textPrimary,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.textSecondary, size: 22),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const Gap(2),
                        Text(subtitle,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right,
                        color: AppColors.textDisabled),
                ],
              ),
              if (child != null) ...[
                const Gap(8),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
