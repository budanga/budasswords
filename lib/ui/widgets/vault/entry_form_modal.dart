import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/models/vault_entry.dart';
import '../../../providers/vault_provider.dart';
import '../../../providers/locale_provider.dart';
import 'password_generator_sheet.dart';

/// Modal dialog: Create or Edit a vault entry without navigating away.
class EntryFormModal extends ConsumerStatefulWidget {
  final VaultEntry? existingEntry;
  const EntryFormModal({super.key, this.existingEntry});

  static Future<void> show(BuildContext context, {VaultEntry? existingEntry}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => EntryFormModal(existingEntry: existingEntry),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curve = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.045),
              end: Offset.zero,
            ).animate(curve),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<EntryFormModal> createState() => _EntryFormModalState();
}

class _EntryFormModalState extends ConsumerState<EntryFormModal> {
  final _titleCtrl   = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  EntryCategory _selectedCategory = EntryCategory.login;
  bool _loading = false;
  bool _obscure = true;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final entry = widget.existingEntry!;
      _titleCtrl.text   = entry.title;
      _urlCtrl.text     = entry.url ?? '';
      _contentCtrl.text = entry.cleanContent;
      _selectedCategory = entry.category;
      _obscure = _selectedCategory == EntryCategory.login;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon() {
    switch (_selectedCategory) {
      case EntryCategory.card:
        return Icons.credit_card_outlined;
      case EntryCategory.note:
        return Icons.edit_note_outlined;
      case EntryCategory.login:
        return Icons.lock_outline;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(vaultNotifierProvider.notifier);
    final strings = ref.read(stringsProvider);

    // Format content with explicit category prefix
    String finalContent = _contentCtrl.text.trim();
    if (_selectedCategory == EntryCategory.note) {
      finalContent = '[type:note]\n$finalContent';
    } else if (_selectedCategory == EntryCategory.card) {
      finalContent = '[type:card]\n$finalContent';
    } else if (_selectedCategory == EntryCategory.login) {
      finalContent = '[type:login]\n$finalContent';
    }

    if (_isEditing) {
      await notifier.updateEntry(
        widget.existingEntry!.copyWith(
          title: _titleCtrl.text.trim(),
          url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          content: finalContent,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.createEntry(
        title: _titleCtrl.text.trim(),
        url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        content: finalContent,
      );
    }

    if (!mounted) return;
    final state = ref.read(vaultNotifierProvider);
    if (state is AsyncError) {
      AppToast.error(context, state.error.toString());
    } else {
      Navigator.pop(context);
      AppToast.success(context, _isEditing ? strings.saveChanges : strings.saveEntry);
    }

    setState(() => _loading = false);
  }

  void _openGenerator() {
    PasswordGeneratorSheet.show(
      context,
      onGenerated: (pw) {
        setState(() => _contentCtrl.text = pw);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Dialog(
      backgroundColor: AppColors.bg1,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(),
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        _isEditing ? strings.editEntryTitle : strings.newEntryTitle,
                        style: GoogleFonts.newsreader(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.close,
                      splashRadius: 18,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textDisabled),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(18),
                const Divider(color: AppColors.border, height: 1),
                const Gap(16),

                // Category Selector Chips
                Text(
                  strings.entryType,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.8,
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    _categoryChip(EntryCategory.login, strings.loginAccount, Icons.lock_outline),
                    const Gap(8),
                    _categoryChip(EntryCategory.note, strings.privateNote, Icons.edit_note_outlined),
                    const Gap(8),
                    _categoryChip(EntryCategory.card, strings.paymentCard, Icons.credit_card_outlined),
                  ],
                ),
                const Gap(18),

                // Title field
                Text(
                  strings.titleLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.8,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _titleHint(strings),
                    prefixIcon: const Icon(Icons.label_outline, color: AppColors.textSecondary, size: 18),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? strings.titleRequired : null,
                ),
                const Gap(16),

                // URL field (only for logins and cards)
                if (_selectedCategory != EntryCategory.note) ...[
                  Text(
                    strings.urlLabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDisabled,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Gap(6),
                  TextFormField(
                    controller: _urlCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: strings.urlHint,
                      prefixIcon: const Icon(Icons.link, color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const Gap(16),
                ],

                // Secret / Content field
                Text(
                  _contentLabel(strings),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.8,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: _contentCtrl,
                  style: TextStyle(
                    fontFamily: _selectedCategory == EntryCategory.login ? 'monospace' : null,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  obscureText: _selectedCategory == EntryCategory.login && _obscure,
                  maxLines: _selectedCategory == EntryCategory.note ? 5 : 1,
                  decoration: InputDecoration(
                    hintText: _contentHint(strings),
                    prefixIcon: Icon(
                      _selectedCategory == EntryCategory.note ? Icons.notes : Icons.key_outlined,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedCategory == EntryCategory.login) ...[
                          IconButton(
                            tooltip: strings.generateSecurePassword,
                            icon: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
                            onPressed: _openGenerator,
                          ),
                          IconButton(
                            tooltip: _obscure ? strings.show : strings.hide,
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ],
                      ],
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? strings.contentRequired : null,
                ),
                const Gap(24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.cancel, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Gap(12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.black),
                              ),
                            )
                          : Text(_isEditing ? strings.saveChanges : strings.saveEntry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(EntryCategory cat, String label, IconData icon) {
    final selected = _selectedCategory == cat;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedCategory = cat;
          _obscure = cat == EntryCategory.login;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentDim : AppColors.bg3,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? AppColors.accent : AppColors.textSecondary),
              const Gap(6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleHint(AppStrings strings) {
    switch (_selectedCategory) {
      case EntryCategory.login: return strings.titleHintLogin;
      case EntryCategory.note:  return strings.titleHintNote;
      case EntryCategory.card:  return strings.titleHintCard;
    }
  }

  String _contentLabel(AppStrings strings) {
    switch (_selectedCategory) {
      case EntryCategory.login: return strings.passwordContentLabel;
      case EntryCategory.note:  return strings.noteContentLabel;
      case EntryCategory.card:  return strings.cardContentLabel;
    }
  }

  String _contentHint(AppStrings strings) {
    switch (_selectedCategory) {
      case EntryCategory.login: return strings.passwordContentHint;
      case EntryCategory.note:  return strings.noteContentHint;
      case EntryCategory.card:  return '4532 •••• •••• 8901 | 12/28 | 123';
    }
  }
}
