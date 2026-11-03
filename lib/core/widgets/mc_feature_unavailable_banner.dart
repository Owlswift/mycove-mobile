import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';
import '../theme/mc_text_styles.dart';

/// Shown above a gated feature's action button when a super admin has
/// switched it off platform-wide (see AppState.featureEnabled). The real
/// enforcement is server-side — this is just so residents see a clear
/// reason instead of a submit that silently 403s.
class McFeatureUnavailableBanner extends StatelessWidget {
  const McFeatureUnavailableBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.rs(16)),
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: McColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.rs(12)),
        border: Border.all(color: McColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: context.rs(18), color: McColors.warning),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: Text(
              message ?? 'Your estate is not subscribed to this feature.',
              style: McTextStyles.body(fontSize: 13, color: McColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
