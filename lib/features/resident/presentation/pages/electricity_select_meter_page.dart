import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/utility_meter.dart';
import '../../../../state/app_notifier.dart';

/// Shown whenever a resident has more than one saved meter and needs to
/// pick which one to recharge — a saved meter is no longer assumed to be
/// "the" meter they always mean. Reached from the dashboard's Buy
/// Electricity tile (manual) and from the voice assistant asking "which
/// meter?" (see AppNotifier._resolveElectricityIntent).
class ElectricitySelectMeterPage extends ConsumerWidget {
  const ElectricitySelectMeterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        ChGenericHeader(title: 'Select Meter', centerTitle: true, onBack: () => context.pop()),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(10)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Which meter would you like to recharge?',
              style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            itemCount: s.utilityMeters.length,
            separatorBuilder: (_, _) => SizedBox(height: context.rs(10)),
            itemBuilder: (_, i) {
              final meter = s.utilityMeters[i];
              return _MeterTile(
                meter: meter,
                discoLabel: discoShortCode(s.discos, meter.discoCode),
                onTap: () {
                  notifier.useExistingMeter(meter);
                  context.push('/resident/electricity/confirm');
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
          child: ChButton(
            label: 'Add New Meter',
            variant: ChButtonVariant.secondary,
            onPressed: () {
              notifier.resetElectricityForm();
              context.push('/resident/electricity');
            },
          ),
        ),
      ],
    );
  }
}

class _MeterTile extends StatelessWidget {
  const _MeterTile({required this.meter, required this.discoLabel, required this.onTap});

  final UtilityMeter meter;
  final String discoLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(ChRadii.md),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.rs(14)),
        decoration: BoxDecoration(
          color: ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.md),
          boxShadow: ChColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: context.rs(36),
              height: context.rs(36),
              decoration: BoxDecoration(color: ChColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(Icons.bolt_rounded, color: ChColors.accent2, size: context.rs(18)),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMeterNumber(meter.meterNumber),
                    style: ChTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: ChColors.text),
                  ),
                  SizedBox(height: context.rs(3)),
                  Text(
                    '$discoLabel · ${meter.meterType == MeterType.postpaid ? 'Postpaid' : 'Prepaid'}'
                    '${meter.customerName != null && meter.customerName!.isNotEmpty ? ' · ${meter.customerName}' : ''}',
                    style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ChColors.bodyText, size: context.rs(20)),
          ],
        ),
      ),
    );
  }
}
