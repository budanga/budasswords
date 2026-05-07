import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/ui/widgets/vault/entry_card.dart';
import 'package:budasswords/ui/widgets/vault/sync_status_badge.dart';

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

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentSoft],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 18),
            ),
            const Gap(10),
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
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn()
                        .slideX(begin: 0.05);
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
      floatingActionButton: FloatingActionButton.extended(
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
