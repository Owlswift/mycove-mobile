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
import '../widgets/utility_wizard_stepper.dart';

class ElectricityEnterMeterPage extends ConsumerStatefulWidget {
  const ElectricityEnterMeterPage({super.key});

  @override
  ConsumerState<ElectricityEnterMeterPage> createState() => _ElectricityEnterMeterPageState();
}

class _ElectricityEnterMeterPageState extends ConsumerState<ElectricityEnterMeterPage> {
  late final _meterController = TextEditingController(text: ref.read(appStateProvider).elecMeterNumber);

  @override
  void dispose() {
    _meterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    // A spoken meter number is written straight into AppState by the voice
    // pipeline (see AppNotifier._handleVoiceTranscript) so it can
    // auto-verify — keep the visible field in sync while on this page.
    ref.listen<String>(appStateProvider.select((s) => s.elecMeterNumber), (prev, next) {
      if (_meterController.text != next) _meterController.text = next;
    });

    return Column(
      children: [
        ChGenericHeader(
          title: 'Buy Electricity',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
          trailing: const UtilityHistoryButton(type: 'ELECTRICITY'),
        ),
        SizedBox(height: context.rs(14)),
        const UtilityWizardStepper(currentStep: 2),
        SizedBox(height: context.rs(14)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Meter Details', style: ChTextStyles.heading(fontSize: 16)),
                SizedBox(height: context.rs(14)),
                if (s.elecDiscoCode.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.rs(12)),
                    decoration: BoxDecoration(
                      color: ChColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(ChRadii.md),
                    ),
                    child: Row(
                      children: [
                        DiscoLogo(
                          disco: Disco(s.elecDiscoCode, discoShortCode(s.discos, s.elecDiscoCode), s.elecDiscoName),
                          size: context.rs(32),
                        ),
                        SizedBox(width: context.rs(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                discoShortCode(s.discos, s.elecDiscoCode),
                                style: ChTextStyles.body(fontSize: 13.5, fontWeight: FontWeight.w700, color: ChColors.text),
                              ),
                              Text(
                                s.elecDiscoName,
                                style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: context.rs(20)),
                Text('Meter Type', style: ChTextStyles.body(fontSize: 14, color: ChColors.text, fontWeight: FontWeight.w700)),
                SizedBox(height: context.rs(8)),
                Row(
                  children: [
                    Expanded(
                      child: _MeterTypeOption(
                        label: 'Prepaid',
                        selected: s.elecMeterType == 'PREPAID',
                        onTap: () => notifier.onElecMeterType('PREPAID'),
                      ),
                    ),
                    SizedBox(width: context.rs(10)),
                    Expanded(
                      child: _MeterTypeOption(
                        label: 'Postpaid',
                        selected: s.elecMeterType == 'POSTPAID',
                        onTap: () => notifier.onElecMeterType('POSTPAID'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(20)),
                Text('Meter Number', style: ChTextStyles.body(fontSize: 14, color: ChColors.text, fontWeight: FontWeight.w700)),
                SizedBox(height: context.rs(5)),
                TextField(
                  controller: _meterController,
                  keyboardType: TextInputType.number,
                  onChanged: notifier.onElecMeterNumber,
                  decoration: InputDecoration(
                    hintText: 'Enter meter number',
                    suffixIcon: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meter scanning is coming soon.')),
                      ),
                      child: Icon(Icons.qr_code_scanner_rounded, color: ChColors.bodyText, size: context.rs(20)),
                    ),
                  ),
                ),
                SizedBox(height: context.rs(20)),
                if (s.utilityError.isNotEmpty) ...[
                  Text(s.utilityError, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                  SizedBox(height: context.rs(12)),
                ],
                SizedBox(height: context.rs(20)),

                ChButton(
                  label: 'Verify Meter',
                  isLoading: s.utilityLoading,
                  onPressed: (s.utilityLoading || s.elecMeterNumber.trim().isEmpty)
                      ? null
                      : () async {
                          final ok = await notifier.verifyElecMeter();
                          if (ok && context.mounted) {
                            context.push('/resident/electricity/confirm');
                          }
                        },
                ),
                SizedBox(height: context.rs(16)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.rs(14)),
                  decoration: BoxDecoration(
                    color: ChColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(ChRadii.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: ChColors.bodyText, size: context.rs(20)),
                      SizedBox(width: context.rs(20)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your details are secure',
                              style: ChTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700, color: ChColors.text),
                            ),
                            SizedBox(height: context.rs(4)),
                            Padding(
                              padding: EdgeInsets.only(right: context.rs(80)),
                              child: Text(
                                'We use bank-level security to protect your information.',
                                style: ChTextStyles.body(fontSize: 12, color: ChColors.text, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MeterTypeOption extends StatelessWidget {
  const _MeterTypeOption({required this.label, required this.selected, required this.onTap});

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
          color: selected ? ChColors.accent2N(100) : ChColors.inputFill,
          borderRadius: BorderRadius.circular(ChRadii.button),
          border: Border.all(color: selected ? ChColors.accent2 : ChColors.divider),
        ),
        child: Text(
          label,
          style: ChTextStyles.body(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? ChColors.accent2 : ChColors.text,
          ),
        ),
      ),
    );
  }
}
