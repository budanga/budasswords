import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../../../providers/locale_provider.dart';

/// Modal dialog: random password generator matching EntryDetailModal styling.
class PasswordGeneratorSheet extends ConsumerStatefulWidget {
  final void Function(String password)? onGenerated;
  const PasswordGeneratorSheet({super.key, this.onGenerated});

  static Future<void> show(BuildContext context, {void Function(String password)? onGenerated}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => PasswordGeneratorSheet(onGenerated: onGenerated),
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
  ConsumerState<PasswordGeneratorSheet> createState() => _PasswordGeneratorSheetState();
}

class _PasswordGeneratorSheetState extends ConsumerState<PasswordGeneratorSheet> {
  int _length  = 16;
  bool _upper  = true;
  bool _lower  = true;
  bool _digits = true;
  bool _symbols = true;

  String _generated = '';
  bool _copied = false;
  Timer? _copyTimer;
  final _rng = Random.secure();

  static const _upperChars  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lowerChars  = 'abcdefghijklmnopqrstuvwxyz';
  static const _digitChars  = '0123456789';
  static const _symbolChars = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _generate() {
    final pool = StringBuffer();
    if (_upper)   pool.write(_upperChars);
    if (_lower)   pool.write(_lowerChars);
    if (_digits)  pool.write(_digitChars);
    if (_symbols) pool.write(_symbolChars);

    if (pool.isEmpty) {
      setState(() => _generated = '');
      return;
    }
    final chars = pool.toString();
    final result = List.generate(_length, (_) => chars[_rng.nextInt(chars.length)]);
    final password = result.join();
    setState(() => _generated = password);
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
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      strings.passwordGeneratorTitle,
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

              // Generated password display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _generated,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings.generateNew,
                      icon: const Icon(Icons.refresh, color: AppColors.accent, size: 20),
                      onPressed: _generate,
                    ),
                    IconButton(
                      tooltip: _copied ? strings.passwordCopied : strings.copy,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _copied ? Icons.check_rounded : Icons.copy_outlined,
                          key: ValueKey<bool>(_copied),
                          color: _copied ? const Color(0xFF4CAF50) : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      onPressed: () async {
                        final strings = ref.read(stringsProvider);
                        await ClipboardHelper.copySensitive(
                          context,
                          _generated,
                          strings: strings,
                        );
                        widget.onGenerated?.call(_generated);
                        setState(() => _copied = true);
                        _copyTimer?.cancel();
                        _copyTimer = Timer(const Duration(milliseconds: 2000), () {
                          if (mounted) {
                            setState(() => _copied = false);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Length slider
              Row(
                children: [
                  Text('${strings.length}:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                  const Spacer(),
                  Text(
                    '$_length',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _length.toDouble(),
                min: 8,
                max: 48,
                divisions: 40,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.border,
                onChanged: (v) {
                  setState(() => _length = v.toInt());
                  _generate();
                },
              ),
              const Gap(8),

              // Toggles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: '${strings.uppercase} (A–Z)', active: _upper,
                      onTap: () { setState(() => _upper = !_upper); _generate(); }),
                  _Chip(label: '${strings.lowercase} (a–z)', active: _lower,
                      onTap: () { setState(() => _lower = !_lower); _generate(); }),
                  _Chip(label: '${strings.numbers} (0–9)', active: _digits,
                      onTap: () { setState(() => _digits = !_digits); _generate(); }),
                  _Chip(label: '${strings.symbols} (!@#)', active: _symbols,
                      onTap: () { setState(() => _symbols = !_symbols); _generate(); }),
                ],
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.accentDim : AppColors.bg3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}



