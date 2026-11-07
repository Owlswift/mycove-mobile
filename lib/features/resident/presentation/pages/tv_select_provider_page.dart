import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/tv_smartcard.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/utility_wizard_stepper.dart';

const _tvStepLabels = ['Select Provider', 'Enter Smartcard', 'Confirm Details', 'Select Package'];

class TvSelectProviderPage extends ConsumerWidget {
  const TvSelectProviderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);

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
        const UtilityWizardStepper(currentStep: 1, labels: _tvStepLabels),
        SizedBox(height: context.rs(14)),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(14)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select TV Provider', style: McTextStyles.heading(fontSize: 16)),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            itemCount: tvProviders.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: McColors.divider),
            itemBuilder: (_, i) {
              final (code, label) = tvProviders[i];
              return _ProviderTile(
                label: label,
                onTap: () {
                  notifier.onTvProvider(code);
                  context.push('/resident/tv/smartcard');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(McRadii.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rs(10)),
        child: Row(
          children: [
            Container(
              width: context.rs(42),
              height: context.rs(42),
              decoration: BoxDecoration(color: McColors.accent2N(100), shape: BoxShape.circle),
              child: Icon(Icons.live_tv_rounded, color: McColors.accent2, size: context.rs(20)),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Text(
                label,
                style: McTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: McColors.text),
              ),
            ),
            Icon(Icons.chevron_right, color: McColors.bodyText, size: context.rs(20)),
          ],
        ),
      ),
    );
  }
}
