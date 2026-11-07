import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';
import '../widgets/utility_wizard_stepper.dart';

const _tvStepLabels = ['Select Provider', 'Enter Smartcard', 'Confirm Details', 'Select Package'];

class TvSelectPackagePage extends ConsumerStatefulWidget {
  const TvSelectPackagePage({super.key});

  @override
  ConsumerState<TvSelectPackagePage> createState() => _TvSelectPackagePageState();
}

class _TvSelectPackagePageState extends ConsumerState<TvSelectPackagePage> {
  late final _phoneController = TextEditingController(text: ref.read(appStateProvider).tvPhone);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(appStateProvider);
      if (s.tvPackages.isEmpty && s.tvProvider.isNotEmpty) {
        ref.read(appStateProvider.notifier).loadTvPackages(s.tvProvider);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
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
        const UtilityWizardStepper(currentStep: 4, labels: _tvStepLabels),
        SizedBox(height: context.rs(14)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a Bouquet', style: McTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(8)),
                Row(
                  children: [
                    Expanded(
                      child: _SubscriptionTypeOption(
                        label: 'New / Change',
                        selected: s.tvSubscriptionType == 'change',
                        onTap: () => notifier.onTvSubscriptionType('change'),
                      ),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: _SubscriptionTypeOption(
                        label: 'Renew',
                        selected: s.tvSubscriptionType == 'renew',
                        onTap: () => notifier.onTvSubscriptionType('renew'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(16)),
                if (s.utilityLoading && s.tvPackages.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.rs(20)),
                    child: const Center(child: CircularProgressIndicator(color: McColors.accent2)),
                  )
                else if (s.tvPackages.isEmpty)
                  Text(
                    'No packages available right now.',
                    style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
                  )
                else
                  Column(
                    children: [
                      for (final pkg in s.tvPackages)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(8)),
                          child: _PackageTile(
                            name: pkg.name,
                            price: formatNaira(pkg.amount),
                            selected: s.tvSelectedPackageCode == pkg.code,
                            onTap: () => notifier.selectTvPackage(pkg.code),
                          ),
                        ),
                    ],
                  ),
                SizedBox(height: context.rs(18)),
                Text('Phone Number', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                SizedBox(height: context.rs(5)),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.onTvPhone,
                  style: McTextStyles.inputValue(),
                  decoration: InputDecoration(
                    hintText: '08012345678',
                    hintStyle: McTextStyles.inputPlaceholder(),
                  ),
                ),
                SizedBox(height: context.rs(20)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Continue to Payment',
                  onPressed: s.tvSelectedPackageCode == null
                      ? null
                      : () => context.push('/resident/tv/payment'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionTypeOption extends StatelessWidget {
  const _SubscriptionTypeOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: context.rs(12)),
        decoration: BoxDecoration(
          color: selected ? McColors.accent2N(100) : McColors.inputFill,
          borderRadius: BorderRadius.circular(McRadii.button),
          border: Border.all(color: selected ? McColors.accent2 : McColors.divider),
        ),
        child: Text(
          label,
          style: McTextStyles.body(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? McColors.accent2 : McColors.text,
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.name,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(McRadii.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(12)),
        decoration: BoxDecoration(
          color: selected ? McColors.accent2N(100) : McColors.surfaceSunken,
          borderRadius: BorderRadius.circular(McRadii.md),
          border: Border.all(color: selected ? McColors.accent2 : Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: McTextStyles.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: McColors.text,
                ),
              ),
            ),
            Text(
              price,
              style: McTextStyles.body(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? McColors.accent2 : McColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
