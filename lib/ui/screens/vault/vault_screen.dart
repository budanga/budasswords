import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/core/utils/clipboard_helper.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/ui/widgets/vault/entry_card.dart';
import 'package:budasswords/ui/widgets/vault/sync_status_badge.dart';
import 'package:budasswords/providers/selection_provider.dart';
import 'package:budasswords/providers/pinned_provider.dart';
import 'package:budasswords/ui/widgets/vault/password_generator_sheet.dart';
import 'package:budasswords/ui/widgets/vault/entry_form_modal.dart';
import 'package:budasswords/ui/widgets/common/app_logo.dart';

enum VaultCategory { all, logins, notes, cards, favorites }

final selectedCategoryProvider = StateProvider<VaultCategory>((ref) => VaultCategory.all);

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _searchCtrl = TextEditingController();
  VaultEntry? _selectedEntry;
  bool _isSidebarCollapsed = false;

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

  List<VaultEntry> _filterByCategory(List<VaultEntry> entries, VaultCategory category, Map<String, int> pinned) {
    switch (category) {
      case VaultCategory.all:
        return entries;
      case VaultCategory.logins:
        return entries.where((e) => e.category == EntryCategory.login).toList();
      case VaultCategory.notes:
        return entries.where((e) => e.category == EntryCategory.note).toList();
      case VaultCategory.cards:
        return entries.where((e) => e.category == EntryCategory.card).toList();
      case VaultCategory.favorites:
        return entries.where((e) => pinned.containsKey(e.id)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final entriesAsync = ref.watch(filteredEntriesProvider);
    final selection = ref.watch(selectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final category = ref.watch(selectedCategoryProvider);
    final pinned = ref.watch(pinnedProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        return Scaffold(
          backgroundColor: AppColors.bg0,
          appBar: _buildAppBar(context, isSelectionMode, selection, isDesktop, strings),
          body: isDesktop
              ? _buildDesktopLayout(entriesAsync, category, pinned, strings)
              : _buildMobileLayout(entriesAsync, category, pinned, strings),
          floatingActionButton: (!isDesktop && !isSelectionMode)
              ? FloatingActionButton.extended(
                  onPressed: () => EntryFormModal.show(context),
                  icon: const Icon(Icons.add),
                  label: Text(strings.newEntry),
                ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack)
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isSelectionMode,
    Set<String> selection,
    bool isDesktop,
    AppStrings strings,
  ) {
    if (isSelectionMode) {
      return AppBar(
        backgroundColor: AppColors.accentDim,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => ref.read(selectionProvider.notifier).clear(),
        ),
        title: Text(
          '${selection.length}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline_rounded, color: AppColors.textPrimary),
            tooltip: strings.addToFavorites,
            onPressed: () {
              ref.read(pinnedProvider.notifier).toggleMultiple(selection.toList());
              ref.read(selectionProvider.notifier).clear();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: strings.delete,
            onPressed: () async {
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
                for (var id in selection) {
                  ref.read(vaultNotifierProvider.notifier).deleteEntry(id);
                }
                ref.read(selectionProvider.notifier).clear();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppBar(
      title: Row(
        children: [
          const AppLogo(size: 24),
          const Gap(10),
          Text(
            strings.appTitle,
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        const SyncStatusBadge(),
        IconButton(
          tooltip: strings.lockNowTitle,
          icon: const Icon(Icons.lock_outline, size: 20),
          onPressed: () {
            ref.read(authProvider.notifier).lock();
            context.go('/login');
          },
        ),
        IconButton(
          tooltip: strings.settingsTitle,
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopLayout(
    AsyncValue<List<VaultEntry>> entriesAsync,
    VaultCategory currentCat,
    Map<String, int> pinned,
    AppStrings strings,
  ) {
    return Row(
      children: [
        // ── Left Sidebar (290px) ──
        Container(
          width: 290,
          decoration: const BoxDecoration(
            color: AppColors.bg1,
            border: Border(right: BorderSide(color: AppColors.border, width: 1)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // + New Entry Action
              ElevatedButton.icon(
                onPressed: () => EntryFormModal.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.newEntry),
              ),
              const Gap(16),
              // Category Navigation
              Text(
                strings.entryType,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDisabled,
                  letterSpacing: 1.0,
                ),
              ),
              const Gap(8),
              _categoryNavItem(VaultCategory.all, strings.allEntries, Icons.folder_open_outlined, entriesAsync.value?.length ?? 0),
              _categoryNavItem(VaultCategory.logins, strings.loginsAndAccounts, Icons.lock_outline, _countCat(entriesAsync.value, VaultCategory.logins)),
              _categoryNavItem(VaultCategory.notes, strings.privateNotes, Icons.edit_note_outlined, _countCat(entriesAsync.value, VaultCategory.notes)),
              _categoryNavItem(VaultCategory.cards, strings.paymentCards, Icons.credit_card_outlined, _countCat(entriesAsync.value, VaultCategory.cards)),
              _categoryNavItem(VaultCategory.favorites, strings.favorites, Icons.star_border, pinned.length),
              const Spacer(),
              // Quick Password Generator Widget
              // Quick Password Generator Action
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => PasswordGeneratorSheet.show(context),
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                label: Text(
                  strings.generatePassword,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // ── Center List View ──
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  // Search Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: strings.searchPlaceholder,
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(searchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const Divider(),
                  // Entry List
                  Expanded(
                    child: entriesAsync.when(
                      data: (rawEntries) {
                        final entries = _filterByCategory(rawEntries, currentCat, pinned);
                        if (entries.isEmpty) {
                          return _EmptyState(
                            title: _searchCtrl.text.isNotEmpty ? strings.noEntriesFoundTitle : strings.emptyVaultTitle,
                            subtitle: _searchCtrl.text.isNotEmpty ? strings.noEntriesFoundSubtitle : strings.emptyVaultSubtitle,
                          );
                        }

                        // Keep selected entry updated if edited or deleted
                        if (_selectedEntry != null) {
                          final updated = entries.where((e) => e.id == _selectedEntry!.id).firstOrNull;
                          _selectedEntry = updated;
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: entries.length,
                          itemBuilder: (context, i) {
                            final entry = entries[i];
                            final isSelected = _selectedEntry?.id == entry.id;

                            return EntryCard(
                              entry: entry,
                              isDesktopSelected: isSelected,
                              onSelectForDetail: () {
                                setState(() {
                                  if (_selectedEntry?.id == entry.id && !_isSidebarCollapsed) {
                                    _selectedEntry = null;
                                  } else {
                                    _selectedEntry = entry;
                                    _isSidebarCollapsed = false;
                                  }
                                });
                              },
                            )
                            .animate(key: ValueKey('desktop_entry_${entry.id}'))
                            .fadeIn(
                              duration: 180.ms,
                              delay: (i * 20).clamp(0, 240).ms,
                              curve: Curves.easeOutQuad,
                            )
                            .slideY(
                              begin: 0.05,
                              end: 0,
                              duration: 180.ms,
                              delay: (i * 20).clamp(0, 240).ms,
                              curve: Curves.easeOutQuad,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.accent)),
                      ),
                      error: (e, _) => Center(
                        child: Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Right Detail Panel (Collapsible & Expandable with Persistent Toggle Button) ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _selectedEntry != null ? (_isSidebarCollapsed ? 48.0 : 640.0) : 0.0,
          decoration: const BoxDecoration(
            color: AppColors.bg1,
            border: Border(left: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: _selectedEntry != null
              ? ClipRect(
                  child: Stack(
                    children: [
                      // Layer 1: Detail Content (fades gracefully when minimized)
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        width: 640,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isSidebarCollapsed ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: _isSidebarCollapsed,
                            child: _buildRightDetailSidebar(_selectedEntry!, strings),
                          ),
                        ),
                      ),

                      // Layer 2: Bottom Close Button for Collapsed Strip
                      if (_isSidebarCollapsed)
                        Positioned(
                          bottom: 12,
                          right: 8,
                          child: IconButton(
                            tooltip: strings.close,
                            splashRadius: 18,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textDisabled,
                            ),
                            onPressed: () => setState(() {
                              _selectedEntry = null;
                              _isSidebarCollapsed = false;
                            }),
                          ),
                        ),

                      // Layer 3: PERSISTENT Toggle Button (ALWAYS present, never flickers or disappears during transitions)
                      Positioned(
                        top: 14,
                        right: 8,
                        child: IconButton(
                          tooltip: _isSidebarCollapsed ? strings.expandPanel : strings.collapsePanel,
                          splashRadius: 18,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(
                            Icons.view_sidebar_outlined,
                            size: 20,
                            color: _isSidebarCollapsed ? AppColors.accent : AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    AsyncValue<List<VaultEntry>> entriesAsync,
    VaultCategory currentCat,
    Map<String, int> pinned,
    AppStrings strings,
  ) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: strings.searchPlaceholder,
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),
        ),
        // Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              _filterChip(VaultCategory.all, strings.allEntries),
              _filterChip(VaultCategory.logins, strings.loginsAndAccounts),
              _filterChip(VaultCategory.notes, strings.privateNotes),
              _filterChip(VaultCategory.cards, strings.paymentCards),
              _filterChip(VaultCategory.favorites, strings.favorites),
            ],
          ),
        ),
        const Gap(4),
        // List
        Expanded(
          child: entriesAsync.when(
            data: (rawEntries) {
              final entries = _filterByCategory(rawEntries, currentCat, pinned);
              if (entries.isEmpty) {
                return _EmptyState(
                  title: _searchCtrl.text.isNotEmpty ? strings.noEntriesFoundTitle : strings.emptyVaultTitle,
                  subtitle: _searchCtrl.text.isNotEmpty ? strings.noEntriesFoundSubtitle : strings.emptyVaultSubtitle,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  return EntryCard(entry: entries[i])
                      .animate(key: ValueKey('mobile_entry_${entries[i].id}'))
                      .fadeIn(
                        duration: 180.ms,
                        delay: (i * 20).clamp(0, 240).ms,
                        curve: Curves.easeOutQuad,
                      )
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 180.ms,
                        delay: (i * 20).clamp(0, 240).ms,
                        curve: Curves.easeOutQuad,
                      );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.accent)),
            ),
            error: (e, _) => Center(
              child: Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryNavItem(VaultCategory cat, String label, IconData icon, int count) {
    final current = ref.watch(selectedCategoryProvider);
    final isSelected = current == cat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentDim : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.accent : AppColors.textSecondary),
              const Gap(10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.bg3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(VaultCategory cat, String label) {
    final current = ref.watch(selectedCategoryProvider);
    final isSelected = current == cat;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.accentDim,
        backgroundColor: AppColors.bg2,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 12.5,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = cat,
      ),
    );
  }

  int _countCat(List<VaultEntry>? entries, VaultCategory cat) {
    if (entries == null) return 0;
    return _filterByCategory(entries, cat, {}).length;
  }

  Widget _buildRightDetailSidebar(VaultEntry entry, AppStrings strings) {
    final isPinned = ref.watch(pinnedProvider).containsKey(entry.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(entry.category),
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: GoogleFonts.newsreader(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(
                      _getCategoryLabel(entry.category, strings),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(6),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite Star Button
                  IconButton(
                    tooltip: isPinned ? strings.removeFromFavorites : strings.addToFavorites,
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      isPinned ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 22,
                      color: isPinned ? const Color(0xFFFFB300) : AppColors.textSecondary,
                    ),
                    onPressed: () => ref.read(pinnedProvider.notifier).togglePin(entry.id),
                  ),
                  // Edit Button
                  IconButton(
                    tooltip: strings.edit,
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                    onPressed: () => EntryFormModal.show(context, existingEntry: entry),
                  ),
                  // Delete Button
                  IconButton(
                    tooltip: strings.delete,
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                    onPressed: () => _confirmDeleteEntry(entry, strings),
                  ),
                  // Close Panel button
                  IconButton(
                    tooltip: strings.close,
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textDisabled),
                    onPressed: () => setState(() {
                      _selectedEntry = null;
                      _isSidebarCollapsed = false;
                    }),
                  ),
                ],
              ),
              // Reserved 48px slot for persistent toggle button
              const SizedBox(width: 48),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(18),
                const Divider(color: AppColors.border, height: 1),
                const Gap(16),

                // Website URL (if available)
                if (entry.url != null && entry.url!.isNotEmpty) ...[
                  _detailFieldBox(
                    strings.websiteUrl,
                    SelectableText(
                      entry.url!,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    headerTrailing: IconButton(
                      tooltip: strings.copy,
                      splashRadius: 16,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.copy_outlined, size: 16, color: AppColors.textSecondary),
                      onPressed: () => ClipboardHelper.copyPlain(
                        context,
                        entry.url!,
                        successMessage: strings.copiedToClipboard,
                      ),
                    ),
                  ),
                  const Gap(14),
                ],

                // Secret / Content with aligned buttons in header
                _SecretDetailBox(
                  label: strings.passwordOrSecret,
                  text: entry.cleanContent,
                ),

                const Gap(18),

                // Timestamps Footer
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: AppColors.textDisabled),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        '${strings.createdOn} ${_fmtDate(entry.createdAt)} · ${strings.updatedOn} ${_fmtDate(entry.updatedAt)}',
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(EntryCategory cat) {
    switch (cat) {
      case EntryCategory.card: return Icons.credit_card_outlined;
      case EntryCategory.note: return Icons.edit_note_outlined;
      case EntryCategory.login: return Icons.lock_outline;
    }
  }

  String _getCategoryLabel(EntryCategory cat, AppStrings strings) {
    switch (cat) {
      case EntryCategory.card: return strings.paymentCard;
      case EntryCategory.note: return strings.privateNote;
      case EntryCategory.login: return strings.loginAccount;
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmDeleteEntry(VaultEntry entry, AppStrings strings) async {
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

    if (confirmed == true && mounted) {
      await ref.read(vaultNotifierProvider.notifier).deleteEntry(entry.id);
      if (mounted) {
        setState(() => _selectedEntry = null);
        AppToast.success(context, strings.delete);
      }
    }
  }

  Widget _detailFieldBox(String label, Widget content, {Widget? headerTrailing}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          const Gap(8),
          content,
        ],
      ),
    );
  }
}

/// Secret/Password content box with header-aligned visibility toggle and copy checkmark feedback.
class _SecretDetailBox extends ConsumerStatefulWidget {
  final String label;
  final String text;

  const _SecretDetailBox({
    required this.label,
    required this.text,
  });

  @override
  ConsumerState<_SecretDetailBox> createState() => _SecretDetailBoxState();
}

class _SecretDetailBoxState extends ConsumerState<_SecretDetailBox> {
  bool _revealed = false;
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final strings = ref.read(stringsProvider);
    await ClipboardHelper.copySensitive(
      context,
      widget.text,
      strings: strings,
    );
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Label aligned with Eye and Copy buttons
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              // Reveal / Hide Button
              IconButton(
                tooltip: _revealed ? strings.hide : strings.reveal,
                splashRadius: 16,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _revealed = !_revealed),
              ),
              const Gap(4),
              // Copy Button with Animated Checkmark Feedback
              IconButton(
                tooltip: _copied ? strings.passwordCopied : strings.copy,
                splashRadius: 16,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_outlined,
                    key: ValueKey<bool>(_copied),
                    size: 17,
                    color: _copied ? const Color(0xFF4CAF50) : AppColors.textSecondary,
                  ),
                ),
                onPressed: _copy,
              ),
            ],
          ),
          const Gap(8),
          // Content Text
          GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _revealed
                  ? SelectableText(
                      widget.text,
                      key: const ValueKey('revealed'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        height: 1.5,
                      ),
                    )
                  : ClipRect(
                      key: const ValueKey('hidden'),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Icon(Icons.auto_stories_outlined, size: 36, color: AppColors.accent),
          ),
          const Gap(16),
          Text(
            title,
            style: GoogleFonts.newsreader(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}


