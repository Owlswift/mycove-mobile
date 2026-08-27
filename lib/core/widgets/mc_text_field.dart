import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_text_styles.dart';

class McTextField extends StatefulWidget {
  const McTextField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.fontSize = 14,
  });

  final String? label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextAlign textAlign;
  final double? letterSpacing;
  final double fontSize;

  @override
  State<McTextField> createState() => _ChTextFieldState();
}

class _ChTextFieldState extends State<McTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant McTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: McTextStyles.body(fontSize: 12, color: McColors.text.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 5),
        ],
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          textAlign: widget.textAlign,
          style: McTextStyles.body(fontSize: widget.fontSize).copyWith(letterSpacing: widget.letterSpacing),
          decoration: InputDecoration(hintText: widget.placeholder, counterText: ''),
        ),
      ],
    );
  }
}
