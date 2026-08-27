import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

/// Six single-digit boxes with auto-advance/auto-retreat focus, kept in
/// sync with a single [value] string — shared by every "enter the 6-digit
/// code we just sent you" screen (forgot-password OTP, household-invite
/// acceptance) rather than each keeping its own copy.
class McOtpBoxes extends StatefulWidget {
  const McOtpBoxes({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<McOtpBoxes> createState() => _ChOtpBoxesState();
}

class _ChOtpBoxesState extends State<McOtpBoxes> {
  static const _length = 6;
  late final List<TextEditingController> _controllers = List.generate(
    _length,
    (i) => TextEditingController(text: i < widget.value.length ? widget.value[i] : ''),
  );
  late final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void didUpdateWidget(covariant McOtpBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _controllers.map((c) => c.text).join();
    if (widget.value != current) {
      for (var i = 0; i < _length; i++) {
        _controllers[i].text = i < widget.value.length ? widget.value[i] : '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onBoxChanged(int index, String v) {
    if (v.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      widget.onChanged(_controllers.map((c) => c.text).join());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _length; i++) ...[
          if (i > 0) SizedBox(width: context.rs(8)),
          _OtpBox(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            onChanged: (v) => _onBoxChanged(i, v),
            onBackspace: () => _onBackspace(i),
          ),
        ],
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.rs(46),
      height: context.rs(54),
      // Focus here gets its own auto-created node (never passed explicitly)
      // and just wraps the TextField as an ancestor in the focus tree —
      // sharing the TextField's own focusNode with a second focus widget
      // crashes ("tried to make a child into a parent of itself"). Backspace
      // on an empty field isn't consumed by the TextField, so it bubbles up
      // to this ancestor's onKeyEvent regardless of which box is focused.
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && controller.text.isEmpty) {
            onBackspace();
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: focusNode,
          builder: (context, child) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xfffdfbf9),
              borderRadius: BorderRadius.circular(McRadii.button),
              border: Border.all(
                color: focusNode.hasFocus ? McColors.accent2 : McColors.neutralN(300),
                width: focusNode.hasFocus ? 2 : 1,
              ),
            ),
            child: child,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: McTextStyles.heading(fontSize: 20),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              // The global InputDecorationTheme sets a visible focusedBorder
              // (see mc_theme.dart) — that takes precedence over the generic
              // `border` below once a box is focused, unless every specific
              // border state is also nulled out here. Left as just `border`,
              // each box grew a second green outline hugging the digit,
              // inside this box's own Container border.
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Didn't receive the code? Resend in 00:45" — shared 45-second cooldown
/// countdown between the same set of OTP screens as [McOtpBoxes].
class McResendRow extends StatefulWidget {
  const McResendRow({super.key, required this.onResend});

  final VoidCallback onResend;

  @override
  State<McResendRow> createState() => _ChResendRowState();
}

class _ChResendRowState extends State<McResendRow> {
  static const _cooldown = 45;
  int _secondsLeft = _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _resend() {
    widget.onResend();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft > 0) {
      final label = _secondsLeft.toString().padLeft(2, '0');
      return Text(
        "Didn't receive the code? Resend in 00:$label",
        style: McTextStyles.body(fontSize: 13, color: McColors.text),
      );
    }
    return GestureDetector(
      onTap: _resend,
      child: RichText(
        text: TextSpan(
          style: McTextStyles.body(fontSize: 13, color: McColors.text),
          children: [
            const TextSpan(text: "Didn't receive the code? "),
            TextSpan(
              text: 'Resend',
              style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: McColors.accent2),
            ),
          ],
        ),
      ),
    );
  }
}
