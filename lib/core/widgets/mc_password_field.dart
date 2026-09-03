import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

/// Bordered password field with a lock icon and a show/hide toggle — used
/// on the login and (first-login) password-reset screens.
class McPasswordField extends StatefulWidget {
  const McPasswordField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = 'Enter your password',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<McPasswordField> createState() => _ChPasswordFieldState();
}

class _ChPasswordFieldState extends State<McPasswordField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  bool _obscure = true;

  @override
  void didUpdateWidget(covariant McPasswordField oldWidget) {
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
    return Container(
      height: context.rs(52),
      padding: EdgeInsets.symmetric(horizontal: context.rs(12)),
      decoration: BoxDecoration(
        color: const Color(0xfffdfbf9),
        borderRadius: BorderRadius.circular(McRadii.button),
        border: Border.all(color: McColors.neutralN(300)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: context.rs(22),
            color: McColors.neutralN(600),
          ),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              obscureText: _obscure,
              style: McTextStyles.inputValue(),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                // The global InputDecorationTheme's focusedBorder (a visible
                // green outline) otherwise takes over on focus, since this
                // Container's own border never changes color — leaving just
                // `border` set draws a second outline on top of it.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: McTextStyles.inputPlaceholder(),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: context.rs(22),
              color: McColors.neutralN(600),
            ),
          ),
        ],
      ),
    );
  }
}
