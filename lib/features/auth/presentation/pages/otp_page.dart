import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

class OtpPage extends ConsumerWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(12), context.rs(20), context.rs(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChSquareIconButton(icon: Icons.arrow_back, onTap: notifier.backToLogin),
              const _OtpIllustration(),
              SizedBox(height: context.rs(12)),
              Center(
                child: Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: ChTextStyles.heading(fontSize: 24, color: ChColors.accent2),
                ),
              ),
              SizedBox(height: context.rs(8)),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(16)),
                  child: Text(
                    "We've sent a 6-digit code to +234 ${s.forgotPhone}",
                    textAlign: TextAlign.center,
                    style: ChTextStyles.body(fontSize: 13.5, color: ChColors.text, height: 1.4),
                  ),
                ),
              ),
              if (s.devOtp != null) ...[
                SizedBox(height: context.rs(4)),
                Center(
                  child: Text(
                    'No SMS provider wired up — demo code: ${s.devOtp}',
                    textAlign: TextAlign.center,
                    style: ChTextStyles.body(fontSize: 11.5, color: ChColors.accent2N(700)),
                  ),
                ),
              ],
              SizedBox(height: context.rs(28)),
              Center(
                child: _OtpBoxes(value: s.otpCode, onChanged: notifier.onOtpChange),
              ),
              if (s.resetMsg.isNotEmpty) ...[
                SizedBox(height: context.rs(14)),
                Center(
                  child: Text(s.resetMsg, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                ),
              ],
              SizedBox(height: context.rs(20)),
              Center(child: _ResendRow(onResend: notifier.sendOtp)),
              SizedBox(height: context.rs(24)),
              ChButton(label: 'Verify Code', onPressed: s.isLoading ? null : notifier.verifyOtp, isLoading: s.isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same asset family as the reset-request screen's illustration — its
/// background (~254,249,244) is close enough to [ChColors.bg] to blend in
/// without masking.
class _OtpIllustration extends StatelessWidget {
  const _OtpIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: AspectRatio(
          aspectRatio: 1402 / 1122,
          child: Image.asset('assets/images/otp_illustration.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Six single-digit boxes with auto-advance/auto-retreat focus, kept in
/// sync with the notifier's single [value] string (the same 6-char
/// otpCode the rest of the reset flow already reads and validates).
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  static const _length = 6;
  late final List<TextEditingController> _controllers = List.generate(
    _length,
    (i) => TextEditingController(text: i < widget.value.length ? widget.value[i] : ''),
  );
  late final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void didUpdateWidget(covariant _OtpBoxes oldWidget) {
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
              borderRadius: BorderRadius.circular(ChRadii.button),
              border: Border.all(
                color: focusNode.hasFocus ? ChColors.accent2 : ChColors.neutralN(300),
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
            style: ChTextStyles.heading(fontSize: 20),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              // The global InputDecorationTheme sets a visible focusedBorder
              // (see ch_theme.dart) — that takes precedence over the generic
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

class _ResendRow extends StatefulWidget {
  const _ResendRow({required this.onResend});

  final VoidCallback onResend;

  @override
  State<_ResendRow> createState() => _ResendRowState();
}

class _ResendRowState extends State<_ResendRow> {
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
        style: ChTextStyles.body(fontSize: 13, color: ChColors.text),
      );
    }
    return GestureDetector(
      onTap: _resend,
      child: RichText(
        text: TextSpan(
          style: ChTextStyles.body(fontSize: 13, color: ChColors.text),
          children: [
            const TextSpan(text: "Didn't receive the code? "),
            TextSpan(
              text: 'Resend',
              style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: ChColors.accent2),
            ),
          ],
        ),
      ),
    );
  }
}
