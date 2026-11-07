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
import '../widgets/utility_wizard_stepper.dart';

const _tvStepLabels = ['Select Provider', 'Enter Smartcard', 'Confirm Details', 'Select Package'];

class TvConfirmSmartcardPage extends ConsumerWidget {
  const TvConfirmSmartcardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final providerLabel = tvProviders.firstWhere((p) => p.$1 == s.tvProvider, orElse: () => ('', '')).$2;

    return Column(
      children: [
        McGenericHeader(
          title: 'TV Subscription',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
          trailing: const UtilityHistoryButton(type: 'TV'),
        ),
        SizedBox(height: context.rs(14)),
        const UtilityWizardStepper(currentStep: 3, labels: _tvStepLabels),
        SizedBox(height: context.rs(14)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm Smartcard Details', style: McTextStyles.heading(fontSize: 16)),
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
                      _DetailRow(label: 'Customer Name', value: s.tvVerifiedCustomerName ?? ''),
                      _DetailRow(label: 'Smartcard Number', value: s.tvSmartcardNumber),
                      if ((s.tvVerifiedCurrentBouquet ?? '').isNotEmpty)
                        _DetailRow(label: 'Current Bouquet', value: s.tvVerifiedCurrentBouquet!),
                      _DetailRow(
                        label: 'Provider',
                        value: providerLabel,
                        isLast: (s.tvVerifiedDueDate ?? '').isEmpty,
                      ),
                      if ((s.tvVerifiedDueDate ?? '').isNotEmpty)
                        _DetailRow(label: 'Due Date', value: s.tvVerifiedDueDate!, isLast: true),
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
                        'Smartcard verified successfully',
                        style: McTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600, color: McColors.accent2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.rs(14)),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      notifier.resetTvForm();
                      context.go('/resident/tv');
                    },
                    child: Text(
                      'Not this card? Change provider or smartcard number',
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
                  onPressed: () => context.push('/resident/tv/package'),
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
