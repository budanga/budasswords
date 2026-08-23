import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/clipboard_helper.dart';
import '../../../providers/locale_provider.dart';

/// Displays secret text blurred by default.
/// Tap to reveal. Provides clipboard copy with auto-clear.
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _revealed
                  ? SelectableText(
                      widget.text,
                      key: const ValueKey('revealed'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 14,
                        height: 1.6,
                      ),
                    )
                  : ClipRect(
                      key: const ValueKey('hidden'),
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'JetBrainsMono',
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
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

