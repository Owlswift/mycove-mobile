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

class TvEnterSmartcardPage extends ConsumerStatefulWidget {
  const TvEnterSmartcardPage({super.key});

  @override
  ConsumerState<TvEnterSmartcardPage> createState() => _TvEnterSmartcardPageState();
}

class _TvEnterSmartcardPageState extends ConsumerState<TvEnterSmartcardPage> {
  late final _smartcardController = TextEditingController(text: ref.read(appStateProvider).tvSmartcardNumber);

  @override
  void dispose() {
    _smartcardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        const UtilityWizardStepper(currentStep: 2, labels: _tvStepLabels),
        SizedBox(height: context.rs(14)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Smartcard Details', style: McTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(14)),
                if (providerLabel.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rs(12)),
                    decoration: BoxDecoration(
                      color: McColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(McRadii.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.live_tv_rounded, color: McColors.accent2, size: context.rs(24)),
                        SizedBox(width: context.rs(10)),
                        Text(
                          providerLabel,
                          style: McTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: McColors.text),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: context.rs(20)),
                Text('Smartcard / IUC Number', style: McTextStyles.body(fontSize: 14, color: McColors.text, fontWeight: FontWeight.w700)),
                SizedBox(height: context.rs(5)),
                TextField(
                  controller: _smartcardController,
                  keyboardType: TextInputType.number,
                  onChanged: notifier.onTvSmartcardNumber,
                  style: McTextStyles.inputValue(),
                  decoration: InputDecoration(
                    hintText: 'Enter smartcard number',
                    hintStyle: McTextStyles.inputPlaceholder(),
                  ),
                ),
                SizedBox(height: context.rs(20)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Verify Smartcard',
                  isLoading: s.utilityLoading,
                  onPressed: (s.utilityLoading || s.tvSmartcardNumber.trim().isEmpty)
                      ? null
                      : () async {
                          final ok = await notifier.verifyTvSmartcard();
                          if (ok && context.mounted) {
                            context.push('/resident/tv/confirm');
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
