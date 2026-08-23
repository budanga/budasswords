import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/providers/vault_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/ui/widgets/vault/password_generator_sheet.dart';

class EntryFormScreen extends ConsumerStatefulWidget {
  final VaultEntry? existingEntry;
  const EntryFormScreen({super.key, this.existingEntry});

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _titleCtrl   = TextEditingController();
  final _urlCtrl     = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  EntryCategory _selectedCategory = EntryCategory.login;
  bool _loading   = false;
  bool _obscure   = true;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(vaultNotifierProvider.notifier);

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
          title:   _titleCtrl.text.trim(),
          url:     _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          content: finalContent,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.createEntry(
        title:   _titleCtrl.text.trim(),
        url:     _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        content: finalContent,
      );
    }

    if (!mounted) return;
    final state = ref.read(vaultNotifierProvider);
    if (state is AsyncError) {
      AppToast.error(context, state.error.toString());
    } else {
      context.pop();
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
                          _isEditing ? strings.editEntryTitle : strings.newEntryTitle,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selector
                          Text(
                            strings.entryType,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDisabled,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _categoryOption(
                        EntryCategory.login,
                        strings.loginAccount,
                        Icons.lock_outline,
                      ),
                      const Gap(8),
                      _categoryOption(
                        EntryCategory.note,
                        strings.privateNote,
                        Icons.edit_note_outlined,
                      ),
                      const Gap(8),
                      _categoryOption(
                        EntryCategory.card,
                        strings.paymentCard,
                        Icons.credit_card_outlined,
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Title field
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: strings.titleLabel,
                      hintText: _selectedCategory == EntryCategory.note
                          ? strings.titleHintNote
                          : (_selectedCategory == EntryCategory.card
                              ? strings.titleHintCard
                              : strings.titleHintLogin),
                      prefixIcon: const Icon(Icons.label_outline, color: AppColors.textSecondary, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? strings.titleRequired : null,
                  ).animate().fadeIn().slideY(begin: 0.04),
                  const Gap(16),

                  // URL field (shown for logins, optional for others)
                  if (_selectedCategory == EntryCategory.login) ...[
                    TextFormField(
                      controller: _urlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: strings.urlLabel,
                        hintText: strings.urlHint,
                        prefixIcon: const Icon(Icons.link, color: AppColors.textSecondary, size: 20),
                      ),
                    ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.04),
                    const Gap(16),
                  ],

                  // Content field
                  TextFormField(
                    controller: _contentCtrl,
                    maxLines: _selectedCategory == EntryCategory.note
                        ? 8
                        : (_obscure ? 1 : 4),
                    obscureText: _selectedCategory == EntryCategory.note ? false : _obscure,
                    decoration: InputDecoration(
                      labelText: _selectedCategory == EntryCategory.note
                          ? strings.noteContentLabel
                          : (_selectedCategory == EntryCategory.card
                              ? strings.cardContentLabel
                              : strings.passwordContentLabel),
                      hintText: _selectedCategory == EntryCategory.note
                          ? strings.noteContentHint
                          : strings.passwordContentHint,
                      prefixIcon: Icon(
                        _selectedCategory == EntryCategory.note
                            ? Icons.notes_outlined
                            : Icons.vpn_key_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _selectedCategory == EntryCategory.login
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: _obscure ? strings.show : strings.hide,
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.auto_awesome,
                                      color: AppColors.accent, size: 20),
                                  tooltip: strings.generateSecurePassword,
                                  onPressed: _openGenerator,
                                ),
                              ],
                            )
                          : null,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? strings.contentRequired : null,
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04),
                  const Gap(28),

                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(_isEditing ? strings.saveChanges : strings.saveEntry),
                  ).animate(delay: 150.ms).fadeIn(),
                ],
              ),
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

  Widget _categoryOption(EntryCategory cat, String label, IconData icon) {
    final isSelected = _selectedCategory == cat;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = cat;
            if (cat == EntryCategory.note) {
              _obscure = false;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentDim : AppColors.bg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



