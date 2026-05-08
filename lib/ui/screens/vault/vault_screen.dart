import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/ui/widgets/vault/entry_card.dart';
import 'package:budasswords/ui/widgets/vault/sync_status_badge.dart';
import 'package:budasswords/providers/selection_provider.dart';
import 'package:budasswords/providers/pinned_provider.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(filteredEntriesProvider);
    final selection = ref.watch(selectionProvider);
    final isSelectionMode = selection.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: isSelectionMode
          ? AppBar(
              backgroundColor: AppColors.accentDim.withOpacity(0.3),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(selectionProvider.notifier).clear(),
              ),
              title: Text('${selection.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.push_pin_outlined),
                  tooltip: 'Toggle pin selected',
                  onPressed: () {
                    ref.read(pinnedProvider.notifier).toggleMultiple(selection.toList());
                    ref.read(selectionProvider.notifier).clear();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  tooltip: 'Delete selected',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.bg2,
                        title: const Text('Delete Entries?'),
                        content: Text('Are you sure you want to delete ${selection.length} entries?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete All', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      for (var id in selection) {
                        ref.read(vaultNotifierProvider.notifier).deleteEntry(id);
                      }
                      ref.read(selectionProvider.notifier).clear();
                    }
                  },
                ),
              ],
            )
          : AppBar(
              title: Row(
                children: [
                  Image.asset('assets/logo.png', width: 24, height: 24),
                  const Gap(8),
                  const Text('Budasswords'),
                ],
              ),
              actions: [
                const SyncStatusBadge(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search entries…',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          const Gap(8),

          // ── Entry list ──
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) return _EmptyState();
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    return EntryCard(entry: entries[i])
                        .animate(delay: Duration(milliseconds: i * 20))
                        .fadeIn(duration: 150.ms)
                        .slideX(
                            begin: 0.05,
                            duration: 200.ms,
                            curve: Curves.easeOut);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/entry-form'),
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_open_outlined,
              size: 64, color: AppColors.textDisabled),
          const Gap(16),
          Text(
            'Your vault is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Gap(8),
          Text(
            'Tap + to add your first entry',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}
