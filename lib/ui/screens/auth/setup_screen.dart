import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/providers/auth_provider.dart';

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
    setState(() => _loading = true);

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
      final err = ref.read(authProvider).error ?? 'Operation failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
      );
      ref.read(authProvider.notifier).clearError();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(40),
                _BudLogo(),
                const Gap(32),
                Text(_isLogin ? 'Welcome back' : 'Create your vault',
                    style: Theme.of(context).textTheme.displayLarge),
                const Gap(8),
                Text(
                    _isLogin
                        ? 'Sign in to access your vault'
                        : 'One account. All your secrets.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const Gap(36),
                _field(
                  ctrl: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const Gap(16),
                _field(
                  ctrl: _passwordCtrl,
                  label: 'Supabase account password',
                  icon: Icons.lock_outline,
                  obscure: _obscurePw,
                  toggleObscure: () => setState(() => _obscurePw = !_obscurePw),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
                ),
                if (!_isLogin) ...[
                  const Gap(16),
                  _field(
                    ctrl: _masterPwCtrl,
                    label: 'Master password (vault key)',
                    icon: Icons.vpn_key_outlined,
                    obscure: _obscureMaster,
                    toggleObscure: () =>
                        setState(() => _obscureMaster = !_obscureMaster),
                    validator: (v) => (v == null || v.length < 12)
                        ? 'Minimum 12 characters'
                        : null,
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _confirmPwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm master password',
                      prefixIcon: Icon(Icons.vpn_key_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (v) => v != _masterPwCtrl.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                ],
                const Gap(32),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(_isLogin ? 'Sign In' : 'Create Vault'),
                ).animate().fadeIn(delay: 200.ms),
                const Gap(16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin
                        ? "Don't have a vault? Create one"
                        : "Already have a vault? Sign in"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }
}

class _BudLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
    );
  }
}
