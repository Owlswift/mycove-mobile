import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_spacing.dart';
import '../theme/mc_text_styles.dart';

/// Shared "Wallet Balance" / "Pay via Paystack" row — used on the dues,
/// airtime and electricity payment screens so the three look and behave
/// the same.
class McPaymentMethodTile extends StatelessWidget {
  const McPaymentMethodTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = enabled ? McColors.accent2 : McColors.danger;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(12)),
          decoration: BoxDecoration(
            color: selected ? accentColor.withValues(alpha: 0.08) : McColors.surface,
            borderRadius: BorderRadius.circular(McRadii.md),
            border: Border.all(color: selected ? accentColor : McColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: McColors.bodyText, size: context.rs(20)),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w600, color: McColors.text)),
                    if (subtitle != null) ...[
                      SizedBox(height: context.rs(2)),
                      Text(
                        subtitle!,
                        style: McTextStyles.body(fontSize: 12, color: enabled ? McColors.bodyText : McColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? accentColor : McColors.divider,
                size: context.rs(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
