import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/core/utils/app_toast.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/locale_provider.dart';
import 'package:budasswords/ui/widgets/common/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _masterPwCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  final _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _biometricPassed = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        final available = await _localAuth.getAvailableBiometrics();
        if (available.isNotEmpty && mounted) {
          setState(() => _biometricAvailable = true);
          // Prompt right away; the button stays as a retry if it's dismissed.
          WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _masterPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (!_biometricAvailable) return;
    final strings = ref.read(stringsProvider);
    try {
      final auth = await _localAuth.authenticate(
        localizedReason: strings.biometricReason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (auth && mounted) {
        setState(() => _biometricPassed = true);
      }
    } catch (_) {}
  }

  Future<void> _unlock() async {
    if (_masterPwCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final strings = ref.read(stringsProvider);
    final ok = await ref.read(authProvider.notifier).unlock(_masterPwCtrl.text);
    if (!ok && mounted) {
      final authState = ref.read(authProvider);
      final err = authState.getLocalizedError(strings) ?? strings.incorrectPassword;
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
            // Top-right language toggle button
            Positioned(
              top: 14,
              right: 18,
              child: const _LanguageToggleButton().animate().fadeIn(duration: 250.ms),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      const AppLogo(
                        size: 50,
                        showContainer: true,
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const Gap(20),
                      Text(
                        strings.appTitle,
                        style: GoogleFonts.newsreader(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const Gap(6),
                      Text(
                        strings.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const Gap(36),
                      if (Platform.isAndroid && _biometricAvailable && !_biometricPassed) ...[
                        OutlinedButton.icon(
                          onPressed: _tryBiometric,
                          icon: const Icon(Icons.fingerprint, color: AppColors.accent, size: 24),
                          label: Text(
                            strings.unlockWithBiometrics,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: AppColors.accent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                        const Gap(20),
                      ],
                      // Password field
                      TextFormField(
                        controller: _masterPwCtrl,
                        enabled: !_biometricAvailable || _biometricPassed,
                        obscureText: _obscure,
                        onFieldSubmitted: (_) => _unlock(),
                        decoration: InputDecoration(
                          labelText: (_biometricAvailable && !_biometricPassed)
                              ? strings.validateBiometricsFirst
                              : strings.masterPasswordPrompt,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
                      const Gap(20),
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              _loading || (_biometricAvailable && !_biometricPassed)
                                  ? null
                                  : _unlock,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(strings.openVault),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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



