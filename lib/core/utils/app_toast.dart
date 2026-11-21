import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:budasswords/core/constants/app_colors.dart';
import 'package:budasswords/ui/widgets/motion/dither_bar.dart';

/// Lightweight overlay-based toast notification with symmetrical enter and exit animations.
class AppToast {
  static OverlayEntry? _currentEntry;
  static GlobalKey<_ToastWidgetState>? _currentKey;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 2600),
  }) =>
      _show(context, (_) => message, isError: isError, duration: duration);

  /// A toast that counts down [duration]: the text is rebuilt every second
  /// from [message] and a dither bar erodes until it disappears.
  /// Tapping it dismisses it early.
  static void countdown(
    BuildContext context, {
    required String Function(int secondsLeft) message,
    required Duration duration,
  }) =>
      _show(context, message, duration: duration, countdown: true);

  static void _show(
    BuildContext context,
    String Function(int secondsLeft) message, {
    bool isError = false,
    required Duration duration,
    bool countdown = false,
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
        countdown: countdown ? duration : null,
        onTap: countdown ? hide : null,
      ),
    );

    _currentEntry = entry;
    _currentKey = key;
    overlay.insert(entry);

    _timer = Timer(duration, hide);
  }

  /// Plays the exit animation of the current toast and removes it.
  static Future<void> hide() async {
    _timer?.cancel();
    final entry = _currentEntry, key = _currentKey;
    if (entry == null) return;
    await key?.currentState?.dismiss();
    if (entry.mounted) entry.remove();
    if (_currentEntry == entry) {
      _currentEntry = null;
      _currentKey = null;
    }
  }

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);

  static void success(BuildContext context, String message) =>
      show(context, message, isError: false);
}

class _ToastWidget extends StatefulWidget {
  final String Function(int secondsLeft) message;
  final bool isError;
  final Duration? countdown;
  final VoidCallback? onTap;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.isError,
    this.countdown,
    this.onTap,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  AnimationController? _countdown;

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
    if (widget.countdown != null) {
      _countdown = AnimationController(vsync: this, duration: widget.countdown)..forward();
    }
  }

  Future<void> dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdown?.dispose();
    super.dispose();
  }

  int get _secondsLeft {
    final total = widget.countdown;
    if (total == null) return 0;
    return (total.inMilliseconds * (1 - _countdown!.value) / 1000).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final countdown = _countdown;

    Widget messageRow() => Row(
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
                widget.message(_secondsLeft),
                style: GoogleFonts.plusJakartaSans(
                  color: widget.isError ? AppColors.danger : AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  fontFeatures: countdown != null ? const [FontFeature.tabularFigures()] : null,
                ),
              ),
            ),
          ],
        );

    // A countdown toast shows the time left as a dither bar that erodes.
    final content = countdown == null
        ? messageRow()
        : AnimatedBuilder(
            animation: countdown,
            builder: (context, _) => IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  messageRow(),
                  const Gap(10),
                  DitherBar(value: 1 - countdown.value),
                ],
              ),
            ),
          );

    // Follow the keyboard: sit above it while open, back to the base offset when closed.
    return Positioned(
      bottom: 36 + MediaQuery.viewInsetsOf(context).bottom,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: widget.onTap,
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
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
