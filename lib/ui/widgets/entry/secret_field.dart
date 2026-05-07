import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Displays secret text blurred by default.
/// Tap to reveal. Provides clipboard copy with auto-clear.
class SecretField extends StatefulWidget {
  final String text;
  const SecretField({super.key, required this.text});

  @override
  State<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<SecretField> {
  bool _revealed = false;
  bool _copied   = false;
  Timer? _clearTimer;

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);

    // Schedule clipboard clear after configured timeout
    _clearTimer?.cancel();
    _clearTimer = Timer(
      Duration(seconds: AppConstants.clipboardClearSeconds),
      () async {
        await Clipboard.setData(const ClipboardData(text: ''));
        if (mounted) setState(() => _copied = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              tooltip: _revealed ? 'Hide' : 'Reveal',
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
                  ? 'Copied! Clears in ${AppConstants.clipboardClearSeconds}s'
                  : 'Copy',
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
