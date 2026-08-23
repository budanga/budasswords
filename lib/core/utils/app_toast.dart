import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:budasswords/core/constants/app_colors.dart';

/// Lightweight overlay-based toast notification with symmetrical enter and exit animations.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    _timer?.cancel();
    if (_currentEntry != null && _currentEntry!.mounted) {
      _currentEntry!.remove();
    }
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final key = GlobalKey<_ToastWidgetState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        key: key,
        message: message,
        isError: isError,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () async {
      final state = key.currentState;
      if (state != null) {
        await state.dismiss();
      }
      if (entry.mounted) {
        entry.remove();
      }
      if (_currentEntry == entry) {
        _currentEntry = null;
      }
    });
  }

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);

  static void success(BuildContext context, String message) =>
      show(context, message, isError: false);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.isError,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();
  }

  Future<void> dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isError
                        ? AppColors.danger.withValues(alpha: 0.6)
                        : AppColors.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                      size: 18,
                      color: widget.isError ? AppColors.danger : AppColors.accent,
                    ),
                    const Gap(10),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.plusJakartaSans(
                          color: widget.isError ? AppColors.danger : AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
