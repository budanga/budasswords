import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/vault_entry.dart';
import '../../../providers/vault_provider.dart';
import '../../../providers/pinned_provider.dart';
import '../../../providers/selection_provider.dart';
import '../../../providers/locale_provider.dart';

/// Compact card for a vault entry in the list.
class EntryCard extends ConsumerWidget {
  final VaultEntry entry;
  final bool isDesktopSelected;
  final VoidCallback? onSelectForDetail;

  const EntryCard({
    super.key,
    required this.entry,
    this.isDesktopSelected = false,
    this.onSelectForDetail,
  });

  void _showOptions(BuildContext context, WidgetRef ref) {
    final strings = ref.read(stringsProvider);
    final pinned = ref.read(pinnedProvider).containsKey(entry.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    pinned ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: pinned ? const Color(0xFFFFB300) : AppColors.textSecondary,
                  ),
                  title: Text(pinned ? strings.removeFromFavorites : strings.addToFavorites),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(pinnedProvider.notifier).togglePin(entry.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: Text(strings.delete, style: const TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.bg2,
                        title: Text(strings.deleteEntryConfirmTitle),
                        content: Text(strings.deleteEntryConfirmContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(strings.delete, style: const TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(vaultNotifierProvider.notifier).deleteEntry(entry.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon() {
    switch (entry.category) {
      case EntryCategory.card:
        return Icons.credit_card_outlined;
      case EntryCategory.note:
        return Icons.edit_note_outlined;
      case EntryCategory.login:
        return Icons.lock_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final isSelected = selection.contains(entry.id);
    final isPinned = ref.watch(pinnedProvider).containsKey(entry.id);
    final isSelectionMode = selection.isNotEmpty;

    final isHighlighted = isSelected || isDesktopSelected;

    return Card(
      color: isHighlighted ? AppColors.accentDim : AppColors.bg2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isHighlighted ? AppColors.accent : AppColors.border,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(10),
        onLongPress: () {
          if (isSelectionMode) {
            ref.read(selectionProvider.notifier).toggle(entry.id);
          } else {
            _showOptions(context, ref);
          }
        },
        onSecondaryTap: () {
          if (isSelectionMode) {
            ref.read(selectionProvider.notifier).toggle(entry.id);
          } else {
            _showOptions(context, ref);
          }
        },
        onTap: () {
          if (isSelectionMode) {
            ref.read(selectionProvider.notifier).toggle(entry.id);
          } else if (onSelectForDetail != null) {
            onSelectForDetail!();
          } else {
            context.push('/entry/${entry.id}', extra: entry);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon / Checkbox
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : (isDesktopSelected ? AppColors.accent : AppColors.bg3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHighlighted ? AppColors.accent : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Icon(
                          _getCategoryIcon(),
                          color: isDesktopSelected ? Colors.white : AppColors.accent,
                          size: 18,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Title + URL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.url != null && entry.url!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.url!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Favorite Star Button
              IconButton(
                icon: Icon(
                  isPinned ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isPinned ? const Color(0xFFFFB300) : AppColors.textDisabled,
                  size: 22,
                ),
                tooltip: isPinned ? ref.read(stringsProvider).removeFromFavorites : ref.read(stringsProvider).addToFavorites,
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  ref.read(pinnedProvider.notifier).togglePin(entry.id);
                },
              ),
              if (!isSelectionMode && onSelectForDetail == null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textDisabled,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

