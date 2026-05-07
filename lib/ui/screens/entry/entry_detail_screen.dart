import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/ui/widgets/entry/secret_field.dart';

class EntryDetailScreen extends ConsumerWidget {
  final VaultEntry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/entry-form', extra: entry),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title card
            _DetailCard(
              label: 'Title',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05),
            const Gap(12),

            // URL
            if (entry.url != null && entry.url!.isNotEmpty)
              _DetailCard(
                label: 'URL',
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.url!,
                        style: const TextStyle(
                          color: AppColors.accentSoft,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.accentSoft,
                        ),
                      ),
                    ),
                    _CopyIconButton(text: entry.url!),
                  ],
                ),
              )
                  .animate(delay: 80.ms)
                  .fadeIn()
                  .slideY(begin: 0.05),

            if (entry.url != null && entry.url!.isNotEmpty) const Gap(12),

            // Secret content
            _DetailCard(
              label: 'Secret',
              child: SecretField(text: entry.content),
            )
                .animate(delay: 160.ms)
                .fadeIn()
                .slideY(begin: 0.05),

            const Gap(24),

            // Metadata
            Text(
              'Created  ${_fmt(entry.createdAt)}\nUpdated  ${_fmt(entry.updatedAt)}',
              style: const TextStyle(
                  color: AppColors.textDisabled, fontSize: 12),
            ).animate(delay: 240.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
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
  const _CopyIconButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        }
      },
    );
  }
}
