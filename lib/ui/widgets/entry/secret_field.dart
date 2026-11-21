import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../../../providers/locale_provider.dart';
import '../motion/decrypt_text.dart';
import '../motion/motion_kit.dart';

/// Displays secret text masked by default.
/// Tap to reveal (it decrypts in place). Provides clipboard copy with auto-clear.
class SecretField extends ConsumerStatefulWidget {
  final String text;
  const SecretField({super.key, required this.text});

  @override
  ConsumerState<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends ConsumerState<SecretField> {
  bool _revealed = false;
  bool _copied = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final strings = ref.read(stringsProvider);
    await ClipboardHelper.copySensitive(
      context,
      widget.text,
      strings: strings,
    );
    setState(() => _copied = true);

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: DecryptText(
              text: widget.text,
              revealed: _revealed,
              selectable: true,
              style: Motion.mono(fontSize: 14, height: 1.6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            IconButton(
              tooltip: _revealed ? strings.hide : strings.reveal,
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
            IconButton(
              tooltip: _copied
                  ? strings.copiedClearsIn(AppConstants.clipboardClearSeconds)
                  : strings.copy,
              icon: Icon(
                _copied ? Icons.check : Icons.copy,
                size: 18,
                color: _copied ? AppColors.success : AppColors.textSecondary,
              ),
              onPressed: _copy,
            ),
          ],
        ),
      ],
    );
  }
}

