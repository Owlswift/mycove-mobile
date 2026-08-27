import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/utility_meter.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/utility_wizard_stepper.dart';

class ElectricityConfirmMeterPage extends ConsumerWidget {
  const ElectricityConfirmMeterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        McGenericHeader(
          title: 'Buy Electricity',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
          trailing: const UtilityHistoryButton(type: 'ELECTRICITY'),
        ),
        SizedBox(height: context.rs(14)),
        const UtilityWizardStepper(currentStep: 3),
        SizedBox(height: context.rs(14)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm Meter Details', style: McTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(16)),
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
                      _DetailRow(label: 'Customer Name', value: s.elecVerifiedName ?? ''),
                      _DetailRow(label: 'Address', value: s.elecVerifiedAddress ?? ''),
                      _DetailRow(label: 'Meter Number', value: formatMeterNumber(s.elecMeterNumber)),
                      _DetailRow(
                        label: 'Meter Type',
                        value: s.elecMeterType == 'POSTPAID' ? 'Postpaid' : 'Prepaid',
                      ),
                      _DetailRow(
                        label: 'DisCo',
                        value: discoShortCode(s.discos, s.elecDiscoCode),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.rs(14)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(12)),
                  decoration: BoxDecoration(
                    color: McColors.accent2N(100),
                    borderRadius: BorderRadius.circular(McRadii.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: McColors.accent2, size: context.rs(18)),
                      SizedBox(width: context.rs(8)),
                      Text(
                        'Meter verified successfully',
                        style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.accent2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.rs(14)),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      notifier.resetElectricityForm();
                      // go(), not push() — this screen is often reached by
                      // *pushing* straight here from the dashboard's saved-
                      // meter shortcut (skipping steps 1-2 entirely), so a
                      // push here would leave this now-reset Confirm page
                      // buried in the stack — tapping back on step 1 would
                      // land on it showing blank fields instead of on the
                      // dashboard. go() replaces the branch's stack with
                      // the correct dashboard-then-step-1 hierarchy instead.
                      context.go('/resident/electricity');
                    },
                    child: Text(
                      'Not this meter? Change provider or meter number',
                      style: McTextStyles.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: McColors.accent2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.rs(20)),
                McButton(
                  label: 'Proceed',
                  onPressed: () {
                    final amount = int.tryParse(s.elecAmount.trim()) ?? 0;
                    if (s.elecAmountPrefilled && amount >= 500) {
                      context.push('/resident/electricity/payment');
                    } else {
                      context.push('/resident/electricity/amount');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : context.rs(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
          SizedBox(height: context.rs(2)),
          Text(value, style: McTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: McColors.text)),
        ],
      ),
    );
  }
}
