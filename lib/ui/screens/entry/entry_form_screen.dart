import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/providers/vault_provider.dart';
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

  bool _loading   = false;
  bool _obscure   = true;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text   = widget.existingEntry!.title;
      _urlCtrl.text     = widget.existingEntry!.url ?? '';
      _contentCtrl.text = widget.existingEntry!.content;
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

    if (_isEditing) {
      await notifier.updateEntry(
        widget.existingEntry!.copyWith(
          title:   _titleCtrl.text.trim(),
          url:     _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          content: _contentCtrl.text,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.createEntry(
        title:   _titleCtrl.text.trim(),
        url:     _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
        content: _contentCtrl.text,
      );
    }

    final state = ref.read(vaultNotifierProvider);
    if (state is AsyncError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } else if (context.mounted) {
      context.pop();
    }

    setState(() => _loading = false);
  }

  void _openGenerator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PasswordGeneratorSheet(
        onGenerated: (pw) {
          setState(() => _contentCtrl.text = pw);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon:
                      Icon(Icons.label_outline, color: AppColors.textSecondary),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ).animate().fadeIn().slideY(begin: 0.06),
              const Gap(16),
              TextFormField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL (optional)',
                  prefixIcon:
                      Icon(Icons.link, color: AppColors.textSecondary),
                ),
              ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.06),
              const Gap(16),
              TextFormField(
                controller: _contentCtrl,
                maxLines: _obscure ? 1 : 5,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Secret / Content',
                  prefixIcon: const Icon(Icons.vpn_key_outlined,
                      color: AppColors.textSecondary),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome,
                            color: AppColors.accentSoft, size: 20),
                        tooltip: 'Generate password',
                        onPressed: _openGenerator,
                      ),
                    ],
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Content is required' : null,
              ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.06),
              const Gap(32),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Entry'),
              ).animate(delay: 180.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
