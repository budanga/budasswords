import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/providers/vault_provider.dart';

Future<bool?> showConnectCloudDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => const ConnectCloudDialog(),
  );
}

class ConnectCloudDialog extends ConsumerStatefulWidget {
  const ConnectCloudDialog({super.key});

  @override
  ConsumerState<ConnectCloudDialog> createState() => _ConnectCloudDialogState();
}

class _ConnectCloudDialogState extends ConsumerState<ConnectCloudDialog> {
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final currentEmail = ref.read(authProvider).session?.email ?? '';
    _emailCtrl = TextEditingController(text: currentEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final strings = ref.read(stringsProvider);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final result = await ref.read(authProvider.notifier).connectCloud(
          email: email,
          password: password,
        );

    if (!mounted) return;

    if (result == ConnectCloudResult.success) {
      ref.read(vaultNotifierProvider.notifier).syncNow();
      AppToast.success(context, strings.cloudAccountLinked);
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result == ConnectCloudResult.vaultMismatch
            ? strings.cloudVaultKeyMismatch
            : strings.cloudAccountLinkFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Dialog(
      backgroundColor: AppColors.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cloud_outlined,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        strings.connectCloudTitle,
                        style: GoogleFonts.newsreader(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Text(
                  strings.connectCloudDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const Gap(20),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: strings.emailLabel,
                    hintText: strings.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return strings.enterValidEmail;
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return strings.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const Gap(14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: strings.accountPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return strings.min8Chars;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleConnect(),
                ),
                if (_errorMessage != null) ...[
                  const Gap(12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const Gap(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        strings.cancel,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const Gap(10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(strings.connectCloudAction),
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
}
