import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

/// Boxed digit entry with auto-advance/auto-retreat focus, kept in sync
/// with a single [value] string — same mechanics as the OTP screen's
/// digit boxes, generalized to any [length] and with an optional
/// [obscureText] for PIN entry.
class McPinBoxes extends StatefulWidget {
  const McPinBoxes({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    this.obscureText = false,
  });

  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final bool obscureText;

  @override
  State<McPinBoxes> createState() => _ChPinBoxesState();
}

class _ChPinBoxesState extends State<McPinBoxes> {
  late final List<TextEditingController> _controllers = List.generate(
    widget.length,
    (i) => TextEditingController(text: i < widget.value.length ? widget.value[i] : ''),
  );
  late final List<FocusNode> _focusNodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void didUpdateWidget(covariant McPinBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _controllers.map((c) => c.text).join();
    if (widget.value != current) {
      for (var i = 0; i < widget.length; i++) {
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
    if (v.isNotEmpty && index < widget.length - 1) {
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
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) SizedBox(width: context.rs(8)),
          _PinBox(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            obscureText: widget.obscureText,
            onChanged: (v) => _onBoxChanged(i, v),
            onBackspace: () => _onBackspace(i),
          ),
        ],
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.rs(46),
      height: context.rs(54),
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
              // Filled, same as every other text field in the app — a
              // near-page-color box with only a faint border (as this used
              // to be) is invisible enough that it reads as empty space
              // rather than a field to tap into.
              color: McColors.inputFill,
              borderRadius: BorderRadius.circular(McRadii.button),
              border: Border.all(
                color: focusNode.hasFocus ? McColors.accent2 : Colors.transparent,
                width: 2,
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
            obscureText: obscureText,
            style: McTextStyles.heading(fontSize: 20),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
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
