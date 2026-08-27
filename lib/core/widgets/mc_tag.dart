import 'package:flutter/material.dart';

import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

class McTag extends StatelessWidget {
  const McTag({
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
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10),
        vertical: context.rs(3),
      ),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(McRadii.pill)),
      child: Text(
        uppercase ? label.toUpperCase() : label,
        style: McTextStyles.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: foreground)
            .copyWith(letterSpacing: 0.3),
      ),
    );
  }
}
