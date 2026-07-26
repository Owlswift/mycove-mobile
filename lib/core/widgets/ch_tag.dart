import 'package:flutter/material.dart';

import '../theme/ch_spacing.dart';
import '../theme/ch_text_styles.dart';

class ChTag extends StatelessWidget {
  const ChTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.uppercase = true,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ChRadii.pill)),
      child: Text(
        uppercase ? label.toUpperCase() : label,
        style: ChTextStyles.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: foreground)
            .copyWith(letterSpacing: 0.3),
      ),
    );
  }
}
