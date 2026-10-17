import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/ui/widgets/vault/connect_cloud_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _localTimeout;

  final List<int> _intervals = [1, 5, 10, 15, 30, 45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final activeLocale = ref.watch(localeProvider);
    final auth = ref.watch(authProvider.notifier);
    final timeout = _localTimeout ?? auth.timeoutMinutes;

    int currentIndex = _intervals.indexOf(timeout);
    if (currentIndex == -1) {
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Centered Header aligned with content
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: strings.back,
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          strings.settingsTitle,
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                    children: [
              // Cloud Sync Status & Linking
              _buildCloudSyncCard(context, ref, strings),
              const Gap(8),

              // Language Selector
              _SettingCard(
                icon: Icons.language_outlined,
                title: strings.languageSettingTitle,
                subtitle: activeLocale == AppLocale.es ? 'Español' : 'English',
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _languageButton(
                          label: 'Español',
                          isSelected: activeLocale == AppLocale.es,
                          onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.es),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: _languageButton(
                          label: 'English',
                          isSelected: activeLocale == AppLocale.en,
                          onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.en),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
              const Gap(8),

              // Auto-lock
              _SettingCard(
                icon: Icons.timer_outlined,
                title: strings.autoLockTitle,
                subtitle: strings.formatAutoLock(timeout),
                child: Slider(
                  value: currentIndex.toDouble(),
                  min: 0,
                  max: (_intervals.length - 1).toDouble(),
                  divisions: _intervals.length - 1,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.border,
                  label: strings.formatAutoLock(_intervals[currentIndex]),
                  onChanged: (v) {
                    setState(() => _localTimeout = _intervals[v.toInt()]);
                  },
                  onChangeEnd: (v) {
                    auth.updateTimeout(_intervals[v.toInt()]);
                  },
                ),
              ).animate(delay: 50.ms).fadeIn(),
              const Gap(8),

              // Lock now
              _SettingCard(
                icon: Icons.lock_outline,
                title: strings.lockNowTitle,
                subtitle: strings.lockNowSubtitle,
                onTap: () {
                  ref.read(authProvider.notifier).lock();
                  context.go('/login');
                },
              ).animate(delay: 100.ms).fadeIn(),
              const Gap(8),

              // Import from Bitwarden
              _SettingCard(
                icon: Icons.download_outlined,
                title: strings.importBitwardenTitle,
                subtitle: strings.importBitwardenSubtitle,
                onTap: () => context.push('/import'),
              ).animate(delay: 150.ms).fadeIn(),
              const Gap(8),

              // Export Vault
              _SettingCard(
                icon: Icons.upload_outlined,
                title: strings.exportVaultTitle,
                subtitle: strings.exportVaultSubtitle,
                onTap: () => context.push('/export'),
              ).animate(delay: 180.ms).fadeIn(),
              const Gap(8),

              // Admin Panel (exclusive for admin)
              if (ref.watch(authProvider).session?.isAdmin ?? false) ...[
                _SettingCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: strings.adminPanelTitle,
                  subtitle: strings.adminPanelSubtitle,
                  onTap: () => context.push('/admin'),
                ).animate(delay: 200.ms).fadeIn(),
                const Gap(8),
              ],

              // Sign out
              _SettingCard(
                icon: Icons.logout,
                title: strings.signOutTitle,
                subtitle: strings.signOutSubtitle,
                titleColor: AppColors.danger,
                onTap: () => _confirmSignOut(context, strings),
              ).animate(delay: 220.ms).fadeIn(),
              const Gap(36),

              // App info & GitHub link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        strings.appFooter,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textDisabled,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const Gap(14),
                    _GitHubButton(onTap: _launchGitHub),
                  ],
                ),
              ).animate(delay: 250.ms).fadeIn(),
            ],
          ),
        ),
      ],
    ),
  ),
),
),
);
}

  Widget _buildCloudSyncCard(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) {
    final firebaseUser = ref.watch(firebaseUserProvider).asData?.value ??
        FirebaseAuth.instance.currentUser;
    final isConnected = firebaseUser != null;

    if (!isConnected) {
      return _SettingCard(
        icon: Icons.cloud_off_outlined,
        title: strings.cloudSyncTitle,
        subtitle: strings.cloudDisconnected,
        titleColor: AppColors.warning,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showConnectCloudDialog(context),
              icon: const Icon(Icons.link, size: 18, color: AppColors.accent),
              label: Text(
                strings.connectCloudAction,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ).animate().fadeIn();
    }

    return _SettingCard(
      icon: Icons.cloud_done_outlined,
      title: strings.cloudSyncTitle,
      subtitle: strings.cloudConnectedAs(firebaseUser.email ?? ''),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(vaultNotifierProvider.notifier).syncNow();
              if (context.mounted) {
                AppToast.success(context, strings.cloudActive);
              }
            },
            icon: const Icon(Icons.sync, size: 18, color: AppColors.accent),
            label: Text(
              strings.syncNow,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _languageButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentDim : AppColors.bg0,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AppStrings strings) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(strings.signOutConfirmTitle),
        content: Text(strings.signOutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.signOutTitle, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _launchGitHub() async {
    const url = 'https://github.com/budanga/budasswords';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback if plugin channel not yet bound or on desktop platform
    if (Platform.isWindows) {
      try {
        await Process.run('cmd', ['/c', 'start', '', url]);
        return;
      } catch (_) {}
    } else if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [url]);
        return;
      } catch (_) {}
    } else if (Platform.isMacOS) {
      try {
        await Process.run('open', [url]);
        return;
      } catch (_) {}
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
      color: AppColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(12),
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
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 20),
                ],
              ),
              if (child != null) ...[
                const Gap(4),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GitHubButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GitHubButton({required this.onTap});

  @override
  State<_GitHubButton> createState() => _GitHubButtonState();
}

class _GitHubButtonState extends State<_GitHubButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'GitHub: budasswords',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuad,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.accent : AppColors.accentDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: GithubIcon(
                size: 20,
                color: _isHovered ? Colors.white : AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GithubIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GithubIcon({
    super.key,
    this.size = 20,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GithubPainter(color),
    );
  }
}

class _GithubPainter extends CustomPainter {
  final Color color;

  _GithubPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path = Path()
      ..moveTo(12, 0.297)
      ..cubicTo(5.37, 0.297, 0, 5.67, 0, 12.297)
      ..cubicTo(0, 17.6, 3.438, 22.097, 8.205, 23.682)
      ..cubicTo(8.805, 23.795, 9.025, 23.424, 9.025, 23.105)
      ..cubicTo(9.025, 22.82, 9.015, 22.065, 9.01, 21.065)
      ..cubicTo(5.672, 21.789, 4.968, 19.455, 4.968, 19.455)
      ..cubicTo(4.422, 18.07, 3.633, 17.7, 3.633, 17.7)
      ..cubicTo(2.546, 16.956, 3.717, 16.971, 3.717, 16.971)
      ..cubicTo(4.922, 17.055, 5.555, 18.207, 5.555, 18.207)
      ..cubicTo(6.625, 20.042, 8.364, 19.512, 9.05, 19.205)
      ..cubicTo(9.158, 18.429, 9.467, 17.9, 9.81, 17.6)
      ..cubicTo(7.145, 17.3, 4.343, 16.268, 4.343, 11.67)
      ..cubicTo(4.343, 10.36, 4.809, 9.29, 5.579, 8.45)
      ..cubicTo(5.444, 8.147, 5.039, 6.927, 5.684, 5.274)
      ..cubicTo(5.684, 5.274, 6.689, 4.952, 8.984, 6.504)
      ..cubicTo(9.944, 6.237, 10.964, 6.105, 11.984, 6.1)
      ..cubicTo(13.004, 6.105, 14.024, 6.237, 14.984, 6.504)
      ..cubicTo(17.264, 4.952, 18.269, 5.274, 18.269, 5.274)
      ..cubicTo(18.914, 6.927, 18.509, 8.147, 18.389, 8.45)
      ..cubicTo(19.154, 9.29, 19.619, 10.36, 19.619, 11.67)
      ..cubicTo(19.619, 16.28, 16.809, 17.295, 14.134, 17.59)
      ..cubicTo(14.564, 17.96, 14.949, 18.69, 14.949, 19.81)
      ..cubicTo(14.949, 21.415, 14.934, 22.71, 14.934, 23.105)
      ..cubicTo(14.934, 23.43, 15.149, 23.805, 15.759, 23.682)
      ..cubicTo(20.529, 22.092, 23.964, 17.595, 23.964, 12.297)
      ..cubicTo(23.964, 5.67, 18.629, 0.297, 12, 0.297)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GithubPainter oldDelegate) =>
      oldDelegate.color != color;
}


