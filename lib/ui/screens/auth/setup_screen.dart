import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/ui/widgets/common/app_logo.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _masterPwCtrl    = TextEditingController();
  final _confirmPwCtrl   = TextEditingController();
  final _formKey         = GlobalKey<FormState>();

  bool _obscurePw      = true;
  bool _obscureMaster  = true;
  bool _loading        = false;
  bool _isLogin        = false; // Toggle between Setup and Login

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _masterPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final strings = ref.read(stringsProvider);
    bool ok;
    if (_isLogin) {
      ok = await ref.read(authProvider.notifier).signIn(
            email:    _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
    } else {
      ok = await ref.read(authProvider.notifier).setup(
            email:          _emailCtrl.text.trim(),
            password:       _passwordCtrl.text,
            masterPassword: _masterPwCtrl.text,
          );
    }

    if (!ok && mounted) {
      final authState = ref.read(authProvider);
      final err = authState.getLocalizedError(strings) ?? strings.operationFailed;
      AppToast.error(context, err);
      ref.read(authProvider.notifier).clearError();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 14,
              right: 18,
              child: const _LanguageToggleButton().animate().fadeIn(duration: 250.ms),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _BudLogo()),
                        const Gap(24),
                        Text(
                          _isLogin ? strings.welcomeBack : strings.createYourVault,
                          style: GoogleFonts.newsreader(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          _isLogin
                              ? strings.setupSubtitleSignIn
                              : strings.setupSubtitleCreate,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Gap(28),
                        _field(
                          ctrl: _emailCtrl,
                          label: strings.emailLabel,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? strings.enterValidEmail : null,
                        ),
                        const Gap(14),
                        _field(
                          ctrl: _passwordCtrl,
                          label: strings.accountPasswordLabel,
                          helperText: !_isLogin ? strings.accountPasswordHelper : null,
                          icon: Icons.lock_outline,
                          obscure: _obscurePw,
                          toggleObscure: () => setState(() => _obscurePw = !_obscurePw),
                          validator: (v) =>
                              (v == null || v.length < 8) ? strings.min8Chars : null,
                        ),
                        if (!_isLogin) ...[
                          const Gap(14),
                          _field(
                            ctrl: _masterPwCtrl,
                            label: strings.masterPasswordLabel,
                            helperText: strings.masterPasswordHelper,
                            icon: Icons.vpn_key_outlined,
                            obscure: _obscureMaster,
                            toggleObscure: () =>
                                setState(() => _obscureMaster = !_obscureMaster),
                            validator: (v) => (v == null || v.length < 12)
                                ? strings.min12Chars
                                : null,
                          ),
                          const Gap(14),
                          TextFormField(
                            controller: _confirmPwCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: strings.confirmMasterPasswordLabel,
                              prefixIcon: const Icon(Icons.vpn_key_outlined,
                                  color: AppColors.textSecondary, size: 20),
                            ),
                            validator: (v) => v != _masterPwCtrl.text
                                ? strings.passwordsDoNotMatch
                                : null,
                          ),
                        ],
                        const Gap(28),
                        Center(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Text(_isLogin ? strings.signInButton : strings.createVaultButton),
                          ),
                        ).animate().fadeIn(delay: 150.ms),
                        const Gap(14),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin
                                  ? strings.dontHaveVaultLink
                                  : strings.alreadyHaveVaultLink,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? helperText,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final field = TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );

    if (helperText == null || helperText.isEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        const Gap(5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            helperText,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageToggleButton extends ConsumerWidget {
  const _LanguageToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isSpanish = locale == AppLocale.es;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final next = isSpanish ? AppLocale.en : AppLocale.es;
          ref.read(localeProvider.notifier).setLocale(next);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 15, color: AppColors.textSecondary),
              const Gap(5),
              Text(
                isSpanish ? 'ES' : 'EN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      size: 44,
      showContainer: true,
    ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack);
  }
}



