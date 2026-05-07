import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/constants/app_constants.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _lockTimeout = AppConstants.autoLockMinutes;

  @override
  Widget build(BuildContext context) {
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
            subtitle: '$_lockTimeout minutes',
            child: Slider(
              value: _lockTimeout.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.accent,
              label: '$_lockTimeout min',
              onChanged: (v) => setState(() => _lockTimeout = v.toInt()),
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

          // Sign out
          _SettingCard(
            icon: Icons.logout,
            title: 'Sign out',
            subtitle: 'Clears all local data and keys',
            titleColor: AppColors.danger,
            onTap: () => _confirmSignOut(context),
          ).animate(delay: 120.ms).fadeIn(),
          const Gap(32),

          // App info
          Center(
            child: Text(
              'Budasswords v1.0.0\nEnd-to-end encrypted · AES-256-GCM · Argon2id',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
