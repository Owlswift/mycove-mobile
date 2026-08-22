import 'package:flutter/material.dart';

import '../theme/ch_colors.dart';
import '../theme/ch_responsive.dart';
import '../theme/ch_spacing.dart';
import '../theme/ch_text_styles.dart';

/// Bordered phone-number field (flag, +234 country code, divider, input,
/// call icon) — shared by every screen that asks for a Nigerian phone
/// number (login, forgot-password, join-household).
class ChPhoneField extends StatefulWidget {
  const ChPhoneField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<ChPhoneField> createState() => _ChPhoneFieldState();
}

class _ChPhoneFieldState extends State<ChPhoneField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant ChPhoneField oldWidget) {
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
      decoration: BoxDecoration(
        color: const Color(0xfffdfbf9),
        borderRadius: BorderRadius.circular(ChRadii.button),
        border: Border.all(color: ChColors.neutralN(300)),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇳🇬', style: TextStyle(fontSize: 20)),
                SizedBox(width: context.rs(6)),
                Text('+234', style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w500)),
                SizedBox(width: context.rs(2)),
                Icon(Icons.keyboard_arrow_down_rounded, size: context.rs(16), color: ChColors.neutralN(600)),
              ],
            ),
          ),
          Container(width: 1, height: context.rs(24), color: ChColors.neutralN(300)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.rs(10)),
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                keyboardType: TextInputType.phone,
                style: ChTextStyles.body(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'Enter phone number',
                  hintStyle: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: context.rs(12)),
            child: Icon(Icons.call_outlined, size: context.rs(22), color: ChColors.neutralN(600)),
          ),
        ],
      ),
    );
  }
}
