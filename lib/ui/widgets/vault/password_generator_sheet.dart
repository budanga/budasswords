import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';

/// Bottom sheet: random password generator.
class PasswordGeneratorSheet extends StatefulWidget {
  final void Function(String password) onGenerated;
  const PasswordGeneratorSheet({super.key, required this.onGenerated});

  @override
  State<PasswordGeneratorSheet> createState() => _PasswordGeneratorSheetState();
}

class _PasswordGeneratorSheetState extends State<PasswordGeneratorSheet> {
  int _length  = 20;
  bool _upper  = true;
  bool _lower  = true;
  bool _digits = true;
  bool _symbols = true;

  String _generated = '';
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
    setState(() => _generated = result.join());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Password Generator',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(12),
          // Generated password display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _generated,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: AppColors.accentSoft,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: _generate,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.textSecondary),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _generated));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Gap(16),
          // Length slider
          Row(
            children: [
              const Text('Length', style: TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              Text('$_length',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _length.toDouble(),
            min: 8,
            max: 64,
            divisions: 56,
            activeColor: AppColors.accent,
            onChanged: (v) {
              setState(() => _length = v.toInt());
              _generate();
            },
          ),
          // Toggles
          Wrap(
            spacing: 8,
            children: [
              _Chip(label: 'A–Z', active: _upper,
                  onTap: () { setState(() => _upper = !_upper); _generate(); }),
              _Chip(label: 'a–z', active: _lower,
                  onTap: () { setState(() => _lower = !_lower); _generate(); }),
              _Chip(label: '0–9', active: _digits,
                  onTap: () { setState(() => _digits = !_digits); _generate(); }),
              _Chip(label: '!@#', active: _symbols,
                  onTap: () { setState(() => _symbols = !_symbols); _generate(); }),
            ],
          ),
          const Gap(20),
          ElevatedButton(
            onPressed: _generated.isEmpty
                ? null
                : () {
                    widget.onGenerated(_generated);
                    Navigator.pop(context);
                  },
            child: const Text('Use This Password'),
          ),
          const Gap(8),
        ],
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accentDim : AppColors.bg3,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accentSoft : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
