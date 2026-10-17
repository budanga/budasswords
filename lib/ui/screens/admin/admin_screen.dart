import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/providers/admin_provider.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final authState = ref.watch(authProvider);
    final adminState = ref.watch(adminProvider);
    final adminNotifier = ref.read(adminProvider.notifier);

    // Guard: Only admins can view this screen
    final isCurrentAdmin = authState.session?.isAdmin ?? false;

    if (!isCurrentAdmin) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gpp_bad_outlined, color: AppColors.danger, size: 54),
                  const Gap(16),
                  Text(
                    strings.adminAccessDenied,
                    style: GoogleFonts.newsreader(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(strings.back),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: strings.back,
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentDim,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(Icons.admin_panel_settings_outlined,
                            color: AppColors.accent, size: 20),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.adminPanelTitle,
                              style: GoogleFonts.newsreader(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              strings.adminPanelSubtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: strings.adminRefresh,
                        icon: adminState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                              )
                            : const Icon(Icons.refresh, color: AppColors.textSecondary),
                        onPressed: adminState.isLoading ? null : () => adminNotifier.loadData(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Main Content
                Expanded(
                  child: adminState.isLoading && adminState.users.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.accent),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (adminState.error != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                                      const Gap(10),
                                      Expanded(
                                        child: Text(
                                          adminState.error!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // 1. Metric Cards
                              _MetricsGrid(stats: adminState.stats, strings: strings)
                                  .animate()
                                  .fadeIn(),
                              const Gap(24),

                              // 2. Diagnostics Tool
                              _DiagnosticsCard(
                                state: adminState,
                                strings: strings,
                                onRun: () => adminNotifier.runDiagnostics(),
                              ).animate().fadeIn(delay: 100.ms),
                              const Gap(28),

                              // 3. User Directory Header & Search
                              Row(
                                children: [
                                  Text(
                                    strings.adminUsersDirectory,
                                    style: GoogleFonts.newsreader(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Gap(8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg3,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${adminState.filteredUsers.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(12),
                              TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => adminNotifier.setSearchQuery(v),
                                decoration: InputDecoration(
                                  hintText: strings.adminSearchUsersPlaceholder,
                                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            adminNotifier.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const Gap(16),

                              // 4. Users List
                              if (adminState.filteredUsers.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.bg2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    strings.noEntriesFoundTitle,
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: adminState.filteredUsers.length,
                                  separatorBuilder: (_, __) => const Gap(10),
                                  itemBuilder: (context, idx) {
                                    final user = adminState.filteredUsers[idx];
                                    return _UserCard(
                                      user: user,
                                      strings: strings,
                                      onInspect: () => _showUserInspector(context, user, strings),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserInspector(BuildContext context, AdminUserItem user, AppStrings strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserInspectorSheet(user: user, strings: strings),
    );
  }
}

// ──────────────────────────────────────────────────
// Metrics Grid
// ──────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final AdminStats stats;
  final AppStrings strings;

  const _MetricsGrid({required this.stats, required this.strings});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 580;
      final crossAxisCount = isWide ? 4 : 2;

      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.45 : 1.35,
        children: [
          _StatBox(
            label: strings.adminTotalUsers,
            value: '${stats.totalUsers}',
            icon: Icons.people_outline,
            accentColor: AppColors.accent,
          ),
          _StatBox(
            label: strings.adminTotalEntries,
            value: '${stats.totalEntries}',
            icon: Icons.shield_outlined,
            accentColor: AppColors.success,
          ),
          _StatBox(
            label: strings.adminActive24h,
            value: '${stats.activeLast24h}',
            icon: Icons.bolt_outlined,
            accentColor: AppColors.warning,
          ),
          _StatBox(
            label: strings.adminActive7d,
            value: '${stats.activeLast7d}',
            icon: Icons.calendar_today_outlined,
            accentColor: AppColors.accentSoft,
          ),
        ],
      );
    });
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.newsreader(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Diagnostics Card
// ──────────────────────────────────────────────────

class _DiagnosticsCard extends StatelessWidget {
  final AdminState state;
  final AppStrings strings;
  final VoidCallback onRun;

  const _DiagnosticsCard({
    required this.state,
    required this.strings,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final latency = state.stats.pingLatencyMs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: state.stats.isOnline
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              state.stats.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: state.stats.isOnline ? AppColors.success : AppColors.danger,
              size: 20,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.adminDiagnostics,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(2),
                Text(
                  latency != null
                      ? '${strings.adminLatency}: ${latency}ms · ${strings.adminConnectionHealthy}'
                      : strings.adminConnectionHealthy,
                  style: TextStyle(
                    fontSize: 12,
                    color: latency != null ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: state.isDiagnosing ? null : onRun,
            icon: state.isDiagnosing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.accent),
                  )
                : const Icon(Icons.speed, size: 16),
            label: Text(strings.adminRunDiagnostics),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// User Item Card
// ──────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AdminUserItem user;
  final AppStrings strings;
  final VoidCallback onInspect;

  const _UserCard({
    required this.user,
    required this.strings,
    required this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final lastActiveStr = user.lastActiveAt != null
        ? dateFormat.format(user.lastActiveAt!)
        : strings.adminNever;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isAdmin ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Role icon avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: user.isAdmin ? AppColors.accentDim : AppColors.bg3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: user.isAdmin ? AppColors.accent.withValues(alpha: 0.35) : AppColors.border,
              ),
            ),
            child: Center(
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                size: 20,
                color: user.isAdmin ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
          const Gap(14),
          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.email.isNotEmpty ? user.email : user.uid,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          strings.adminRoleAdmin.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    Text(
                      '${strings.adminLastActive}: $lastActiveStr',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 12, color: AppColors.textDisabled),
                          const Gap(4),
                          Text(
                            '${user.entriesCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Inspect button
          IconButton(
            tooltip: strings.adminUserDetailsTitle,
            icon: const Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
            onPressed: onInspect,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// User Inspector Bottom Sheet
// ──────────────────────────────────────────────────

class _UserInspectorSheet extends StatelessWidget {
  final AdminUserItem user;
  final AppStrings strings;

  const _UserInspectorSheet({required this.user, required this.strings});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final createdStr = user.createdAt != null ? dateFormat.format(user.createdAt!) : strings.adminNever;
    final lastActiveStr =
        user.lastActiveAt != null ? dateFormat.format(user.lastActiveAt!) : strings.adminNever;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              const Icon(Icons.manage_accounts_outlined, color: AppColors.accent, size: 24),
              const Gap(10),
              Text(
                strings.adminUserDetailsTitle,
                style: GoogleFonts.newsreader(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Gap(16),
          _detailRow(strings.adminEmail, user.email),
          _detailRow(strings.adminUid, user.uid, canCopy: true, context: context),
          _detailRow(strings.adminRole, user.isAdmin ? strings.adminRoleAdmin : strings.adminRoleUser),
          _detailRow(strings.adminCreatedAt, createdStr),
          _detailRow(strings.adminLastActive, lastActiveStr),
          _detailRow(strings.adminTotalEntries, '${user.entriesCount} ${strings.adminEntries.toLowerCase()}'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool canCopy = false, Color? valueColor, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              if (canCopy && context != null) ...[
                const Gap(6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('UID copiado al portapapeles'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Icon(Icons.copy_outlined, size: 14, color: AppColors.textDisabled),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
