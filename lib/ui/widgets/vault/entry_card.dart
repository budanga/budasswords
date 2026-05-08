import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/vault_entry.dart';
import '../../../providers/vault_provider.dart';
import '../../../providers/pinned_provider.dart';
import '../../../providers/selection_provider.dart';

/// Compact card for a vault entry in the list.
class EntryCard extends ConsumerWidget {
  final VaultEntry entry;
  const EntryCard({super.key, required this.entry});

  void _showOptions(BuildContext context, WidgetRef ref) {
    final pinned = ref.read(pinnedProvider).containsKey(entry.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(pinned ? 'Unpin' : 'Pin to top'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(pinnedProvider.notifier).togglePin(entry.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box_outlined),
                title: const Text('Select multiple'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(selectionProvider.notifier).toggle(entry.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.bg2,
                      title: const Text('Delete Entry?'),
                      content: Text('Are you sure you want to delete "${entry.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final isSelected = selection.contains(entry.id);
    final isPinned = ref.watch(pinnedProvider).containsKey(entry.id);
    final isSelectionMode = selection.isNotEmpty;

    return Card(
      color: isSelected ? AppColors.accentDim.withOpacity(0.2) : AppColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
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
          } else {
            context.push('/entry/${entry.id}', extra: entry);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon / Checkbox
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.accentDim.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : Text(
                    entry.title.isNotEmpty
                        ? entry.title[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.accentSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.url != null && entry.url!.isNotEmpty) ...[
                      const SizedBox(height: 3),
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
              if (isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.push_pin, color: AppColors.accent, size: 18),
                ),
              if (!isSelectionMode)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
