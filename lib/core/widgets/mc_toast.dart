import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

enum McToastKind { error, success, info }

OverlayEntry? _current;

/// A message that slides down from the top of the screen, sits over the page
/// for a few seconds and slides away again. Tap it or swipe it up to dismiss.
/// Used instead of red error text under a form.
void showMcToast(BuildContext context, String message, {McToastKind kind = McToastKind.error}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _McToast(
      message: message,
      kind: kind,
      onDone: () {
        if (entry.mounted) entry.remove();
        if (_current == entry) _current = null;
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _McToast extends StatefulWidget {
  const _McToast({required this.message, required this.kind, required this.onDone});

  final String message;
  final McToastKind kind;
  final VoidCallback onDone;

  @override
  State<_McToast> createState() => _McToastState();
}

class _McToastState extends State<_McToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 240),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 3600), _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, tint, fg) = switch (widget.kind) {
      McToastKind.error => (Icons.error_outline_rounded, McColors.danger.withValues(alpha: 0.12), McColors.danger),
      McToastKind.success => (Icons.check_circle_outline_rounded, McColors.accent2N(100), McColors.accent2),
      McToastKind.info => (Icons.info_outline_rounded, McColors.accent2N(100), McColors.accent2),
    };
    final slide = Tween<Offset>(begin: const Offset(0, -1.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic));

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              child: GestureDetector(
                onTap: _close,
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < 0) _close();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: McColors.surface,
                      borderRadius: BorderRadius.circular(McRadii.card),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                          child: Icon(icon, size: 18, color: fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w500, color: McColors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
