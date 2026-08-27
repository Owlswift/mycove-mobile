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

const _quickAmounts = [1000, 2000, 5000];

/// Nigerian residential electricity tariffs vary by DisCo and tariff band,
/// and VTpass/BuyPower don't expose a pre-purchase rate-lookup endpoint —
/// only a post-vend `units` figure. This is a rough flat approximation
/// (reverse-engineered from the design mockup's own example: ₦10,000 ≈
/// 61.20 kWh) purely for the "estimated units" preview; the real unit
/// count comes back from the provider after purchase.
const _approxNairaPerKwh = 163.4;
const _transactionFee = 100;

class ElectricityEnterAmountPage extends ConsumerStatefulWidget {
  const ElectricityEnterAmountPage({super.key});

  @override
  ConsumerState<ElectricityEnterAmountPage> createState() => _ElectricityEnterAmountPageState();
}

class _ElectricityEnterAmountPageState extends ConsumerState<ElectricityEnterAmountPage> {
  late final _amountController = TextEditingController(text: ref.read(appStateProvider).elecAmount);
  final _amountFocus = FocusNode();

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _setAmount(String value) {
    _amountController.text = value;
    ref.read(appStateProvider.notifier).onElecAmount(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final amount = int.tryParse(s.elecAmount.trim());
    final estimatedKwh = amount != null ? amount / _approxNairaPerKwh : null;
    final total = (amount ?? 0) + _transactionFee;

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
        const UtilityWizardStepper(currentStep: 4),
        SizedBox(height: context.rs(14)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Amount', style: McTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(16)),
                Text('Enter Amount (₦)', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                SizedBox(height: context.rs(6)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.rs(16), vertical: context.rs(6)),
                  decoration: BoxDecoration(
                    border: Border.all(color: McColors.divider),
                    borderRadius: BorderRadius.circular(McRadii.button),
                  ),
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: TextInputType.number,
                    onChanged: notifier.onElecAmount,
                    style: McTextStyles.heading(fontSize: 24),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                  ),
                ),
                SizedBox(height: context.rs(10)),
                Wrap(
                  spacing: context.rs(8),
                  runSpacing: context.rs(8),
                  children: [
                    for (final a in _quickAmounts)
                      _Chip(
                        label: formatNaira(a),
                        selected: s.elecAmount == a.toString(),
                        onTap: () => _setAmount(a.toString()),
                      ),
                    _Chip(
                      label: 'Other',
                      selected: false,
                      onTap: () => _amountFocus.requestFocus(),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(18)),
                if (estimatedKwh != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rs(14)),
                    decoration: BoxDecoration(
                      color: McColors.accent2N(100),
                      borderRadius: BorderRadius.circular(McRadii.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You will receive approximately',
                                style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                              ),
                              SizedBox(height: context.rs(4)),
                              Text(
                                '${estimatedKwh.toStringAsFixed(2)} kWh',
                                style: McTextStyles.heading(fontSize: 20, color: McColors.accent2),
                              ),
                              SizedBox(height: context.rs(2)),
                              Text(
                                'Estimated units',
                                style: McTextStyles.body(fontSize: 11.5, color: McColors.bodyText),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.bolt_rounded, color: McColors.accent, size: context.rs(24)),
                      ],
                    ),
                  ),
                SizedBox(height: context.rs(18)),
                _SummaryRow(label: 'Transaction Fee', value: formatNaira(_transactionFee)),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.rs(10)),
                  child: Divider(height: 1, color: McColors.divider),
                ),
                _SummaryRow(label: 'Total Payable', value: formatNaira(total), emphasize: true),
                SizedBox(height: context.rs(20)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                McButton(
                  label: 'Continue to Payment',
                  onPressed: (amount == null || amount < 500)
                      ? null
                      : () => context.push('/resident/electricity/payment'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: McTextStyles.body(
            fontSize: emphasize ? 14 : 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
            color: emphasize ? McColors.text : McColors.bodyText,
          ),
        ),
        Text(
          value,
          style: McTextStyles.body(
            fontSize: emphasize ? 14 : 13,
            fontWeight: FontWeight.w700,
            color: McColors.text,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(8)),
        decoration: BoxDecoration(
          color: selected ? McColors.accent2 : McColors.surfaceSunken,
          borderRadius: BorderRadius.circular(McRadii.pill),
        ),
        child: Text(
          label,
          style: McTextStyles.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : McColors.text,
          ),
        ),
      ),
    );
  }
}
