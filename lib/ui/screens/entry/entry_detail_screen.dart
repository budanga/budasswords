import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/core/utils/clipboard_helper.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/pinned_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/ui/widgets/entry/secret_field.dart';
import 'package:budasswords/ui/widgets/vault/entry_form_modal.dart';

class EntryDetailScreen extends ConsumerWidget {
  final VaultEntry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isPinned = ref.watch(pinnedProvider).containsKey(entry.id);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                // Centered Header aligned with content
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
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
                          entry.title,
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: isPinned ? strings.removeFromFavorites : strings.addToFavorites,
                        icon: Icon(
                          isPinned ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isPinned ? const Color(0xFFFFB300) : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: () => ref.read(pinnedProvider.notifier).togglePin(entry.id),
                      ),
                      IconButton(
                        tooltip: strings.edit,
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        onPressed: () => EntryFormModal.show(context, existingEntry: entry),
                      ),
                      IconButton(
                        tooltip: strings.delete,
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _confirmDelete(context, ref, strings),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title card
                        _DetailCard(
                  label: strings.titleLabel,
                  child: Text(
                    entry.title,
                    style: GoogleFonts.newsreader(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.04),
                const Gap(12),

                // URL
                if (entry.url != null && entry.url!.isNotEmpty) ...[
                  _DetailCard(
                    label: strings.website,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.url!,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        _CopyIconButton(text: entry.url!, copiedMessage: strings.copiedToClipboard),
                      ],
                    ),
                  ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.04),
                  const Gap(12),
                ],

                // Secret content
                _DetailCard(
                  label: strings.secret,
                  child: SecretField(text: entry.cleanContent),
                ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.04),

                const Gap(24),

                // Metadata
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          '${strings.createdOn} ${_fmt(entry.createdAt)} · ${strings.updatedOn} ${_fmt(entry.updatedAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 180.ms).fadeIn(),
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

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AppStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(strings.deleteEntryConfirmTitle),
        content: Text(strings.deleteEntryConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vaultNotifierProvider.notifier).deleteEntry(entry.id);
      if (context.mounted) context.pop();
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const Gap(8),
          child,
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatelessWidget {
  final String text;
  final String copiedMessage;
  const _CopyIconButton({required this.text, required this.copiedMessage});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.textSecondary),
      onPressed: () => ClipboardHelper.copyPlain(
        context,
        text,
        successMessage: copiedMessage,
      ),
    );
  }
}


