import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/tv_smartcard.dart';
import '../../../../state/app_notifier.dart';

/// Shown whenever a resident has more than one saved smartcard and needs to
/// pick which one to pay for — the TV equivalent of
/// `ElectricitySelectMeterPage`.
class TvSelectSmartcardPage extends ConsumerWidget {
  const TvSelectSmartcardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        McGenericHeader(title: 'Select Smartcard', centerTitle: true, onBack: () => context.pop()),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(10)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Which decoder would you like to pay for?',
              style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            itemCount: s.tvSmartcards.length,
            separatorBuilder: (_, _) => SizedBox(height: context.rs(10)),
            itemBuilder: (_, i) {
              final card = s.tvSmartcards[i];
              return _SmartcardTile(
                card: card,
                onTap: () {
                  notifier.useExistingSmartcard(card);
                  context.push('/resident/tv/confirm');
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
          child: McButton(
            label: 'Add New Smartcard',
            variant: ChButtonVariant.secondary,
            onPressed: () {
              notifier.resetTvForm();
              context.push('/resident/tv');
            },
          ),
        ),
      ],
    );
  }
}

class _SmartcardTile extends StatelessWidget {
  const _SmartcardTile({required this.card, required this.onTap});

  final TvSmartcard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(McRadii.md),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.rs(14)),
        decoration: BoxDecoration(
          color: McColors.surface,
          borderRadius: BorderRadius.circular(McRadii.md),
          boxShadow: McColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: context.rs(36),
              height: context.rs(36),
              decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(Icons.live_tv_rounded, color: McColors.accent2, size: context.rs(18)),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.smartcardNumber,
                    style: McTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: McColors.text),
                  ),
                  SizedBox(height: context.rs(3)),
                  Text(
                    '${card.providerName}'
                    '${card.customerName != null && card.customerName!.isNotEmpty ? ' · ${card.customerName}' : ''}',
                    style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: McColors.bodyText, size: context.rs(20)),
          ],
        ),
      ),
    );
  }
}
