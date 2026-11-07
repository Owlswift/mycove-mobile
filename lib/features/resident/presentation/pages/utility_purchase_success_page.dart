import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

const _typeLabels = {
  'ELECTRICITY': 'Electricity purchased',
  'AIRTIME': 'Airtime purchased',
  'DATA': 'Data bundle purchased',
  'TV': 'TV subscription purchased',
  'EDUCATION': 'WAEC PIN purchased',
};

/// Shared by every utility purchase flow — the purchase itself (token/units
/// for electricity, PIN(s) for education, nothing extra for airtime/data/TV)
/// already sits in [AppState.lastUtilityPurchase] by the time any flow
/// pushes here.
class UtilityPurchaseSuccessPage extends ConsumerWidget {
  const UtilityPurchaseSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(appStateProvider).lastUtilityPurchase;
    final isElectricity = purchase?.type == 'ELECTRICITY';
    final isEducation = purchase?.type == 'EDUCATION';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(24),
        context.rs(60),
        context.rs(24),
        context.rs(24),
      ),
      child: Column(
        children: [
          Container(
            width: context.rs(64),
            height: context.rs(64),
            decoration: const BoxDecoration(color: McColors.accent2, shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.white, size: context.rs(30)),
          ),
          SizedBox(height: context.rs(18)),
          Text(
            _typeLabels[purchase?.type] ?? 'Purchase successful',
            style: McTextStyles.heading(fontSize: 18),
          ),
          SizedBox(height: context.rs(6)),
          Text(
            '${formatNaira(purchase?.amount ?? 0)} paid successfully',
            style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
          ),
          if (isElectricity && purchase?.token != null) ...[
            SizedBox(height: context.rs(22)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: McColors.surfaceSunken,
                borderRadius: BorderRadius.circular(McRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOKEN',
                    style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.bodyText)
                        .copyWith(letterSpacing: 1),
                  ),
                  SizedBox(height: context.rs(6)),
                  SelectableText(
                    purchase!.token!,
                    style: McTextStyles.heading(fontSize: 20, color: McColors.accent2),
                  ),
                  if (purchase.units != null) ...[
                    SizedBox(height: context.rs(10)),
                    Text(
                      '${purchase.units} · ${purchase.tariff ?? ''}',
                      style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (isEducation &&
              purchase?.purchasedCode != null &&
              purchase!.purchasedCode!.isNotEmpty) ...[
            SizedBox(height: context.rs(22)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: McColors.surfaceSunken,
                borderRadius: BorderRadius.circular(McRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN(S)',
                    style: McTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: McColors.bodyText)
                        .copyWith(letterSpacing: 1),
                  ),
                  SizedBox(height: context.rs(6)),
                  for (final line in purchase.purchasedCode!.split('||'))
                    Padding(
                      padding: EdgeInsets.only(bottom: context.rs(4)),
                      child: SelectableText(
                        line.trim(),
                        style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.accent2),
                      ),
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: context.rs(28)),
          McButton(
            label: 'View receipt',
            onPressed: purchase == null
                ? null
                : () =>
                      context.push('/resident/utility-history/${purchase.id}/receipt'),
          ),
          SizedBox(height: context.rs(10)),
          McButton(
            label: 'Done',
            onPressed: () => context.go('/resident'),
          ),
        ],
      ),
    );
  }
}
