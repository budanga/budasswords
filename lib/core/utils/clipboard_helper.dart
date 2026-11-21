import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../localization/app_strings.dart';
import 'app_toast.dart';

/// Helper for copying sensitive text to the clipboard with auto-clear.
class ClipboardHelper {
  static Timer? _clearTimer;
  static String? _lastCopiedText;

  /// Copies sensitive text to the clipboard and schedules auto-clearing.
  static Future<void> copySensitive(
    BuildContext context,
    String text, {
    String? successMessage,
    AppStrings? strings,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    _lastCopiedText = text;

    if (context.mounted) {
      if (successMessage != null) {
        AppToast.success(context, successMessage);
      } else {
        // Count down the auto-clear so the user can see when the clipboard empties.
        AppToast.countdown(
          context,
          message: (s) => strings?.copiedClearsIn(s) ?? 'Copiado (se borra en ${s}s)',
          duration: const Duration(seconds: AppConstants.clipboardClearSeconds),
        );
      }
    }

    _clearTimer?.cancel();
    _clearTimer = Timer(
      const Duration(seconds: AppConstants.clipboardClearSeconds),
      () async {
        try {
          final current = await Clipboard.getData(Clipboard.kTextPlain);
          // Only clear if the user hasn't copied something else in the meantime
          if (current?.text == _lastCopiedText) {
            await Clipboard.setData(const ClipboardData(text: ''));
            _lastCopiedText = null;
          }
        } catch (_) {}
      },
    );
  }

  /// Copies normal (non-secret) text to clipboard without scheduling auto-clear.
  static Future<void> copyPlain(
    BuildContext context,
    String text, {
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted && successMessage != null) {
      AppToast.success(context, successMessage);
    }
  }
}
