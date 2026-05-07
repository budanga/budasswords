import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:local_auth/local_auth.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/auth_provider.dart';

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
    try {
      final auth = await _localAuth.authenticate(
        localizedReason: 'Unlock Budasswords',
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
    final ok = await ref.read(authProvider.notifier).unlock(_masterPwCtrl.text);
    if (!ok && mounted) {
      final err = ref.read(authProvider).error ?? 'Incorrect password';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.danger,
        ),
      );
      ref.read(authProvider.notifier).clearError();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accentGlow, Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Gap(48),
                  // Logo
                  Image.asset('assets/logo.png', width: 80, height: 80)
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const Gap(16),
                  const Text(
                    'Budasswords',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const Gap(8),
                  Text(
                    'Enter master password to unlock',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 300.ms),
                  const Gap(48),
                  if (Platform.isAndroid && _biometricAvailable && !_biometricPassed) ...[
                    OutlinedButton.icon(
                      onPressed: _tryBiometric,
                      icon: const Icon(Icons.fingerprint,
                          color: AppColors.accentSoft, size: 28),
                      label: const Text(
                        'Unlock with Biometrics',
                        style: TextStyle(
                            color: AppColors.accentSoft,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(
                            color: AppColors.accent, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                    const Gap(24),
                  ],
                  // Password field
                  TextFormField(
                    controller: _masterPwCtrl,
                    enabled: !_biometricAvailable || _biometricPassed,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _unlock(),
                    decoration: InputDecoration(
                      labelText: (_biometricAvailable && !_biometricPassed)
                          ? 'Validate biometrics first...'
                          : 'Master password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const Gap(20),
                  ElevatedButton(
                    onPressed:
                        _loading || (_biometricAvailable && !_biometricPassed)
                            ? null
                            : _unlock,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Unlock Vault'),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
