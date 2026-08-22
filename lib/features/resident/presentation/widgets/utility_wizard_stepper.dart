import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../data/models/utility_meter.dart';

/// Real logo asset if one's been added for this DISCO yet (matched by
/// [disco.shortCode] lowercased, see [discoLogoAsset]); falls back to a
/// generic bolt icon otherwise, since logos are added incrementally.
/// Standalone — no background box — so each logo's own art shows as-is.
class DiscoLogo extends StatelessWidget {
  const DiscoLogo({super.key, required this.disco, required this.size});

  final Disco disco;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        discoLogoAsset(disco),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.bolt_rounded, color: ChColors.accent2, size: size * 0.7),
      ),
    );
  }
}

/// Trailing header icon on every step of the electricity wizard — pushes to
/// the purchase history list.
class UtilityHistoryButton extends StatelessWidget {
  const UtilityHistoryButton({super.key, required this.type});

  final String type; // 'ELECTRICITY' | 'AIRTIME'

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/resident/utility-history', extra: type),
      child: Icon(Icons.history_rounded, color: ChColors.text, size: context.rs(22)),
    );
  }
}

const _stepLabels = ['Select Provider', 'Enter Meter', 'Confirm Details', 'Enter Amount'];

/// 4-step progress indicator shared by the electricity purchase wizard —
/// only the active step shows its label, matching the mockups.
class UtilityWizardStepper extends StatelessWidget {
  const UtilityWizardStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(22)),
      child: Row(
        children: [
          for (var step = 1; step <= 4; step++) ...[
            _StepCircle(step: step, currentStep: currentStep),
            if (step == currentStep)
              Padding(
                padding: EdgeInsets.only(left: context.rs(6)),
                child: Text(
                  _stepLabels[step - 1],
                  style: ChTextStyles.body(fontSize: 12.5, fontWeight: FontWeight.w700, color: ChColors.accent2),
                ),
              ),
            if (step < 4)
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: EdgeInsets.symmetric(horizontal: context.rs(6)),
                  color: step < currentStep ? ChColors.accent2 : ChColors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.step, required this.currentStep});

  final int step;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final done = step < currentStep;
    final active = step == currentStep;
    return Container(
      width: context.rs(26),
      height: context.rs(26),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? ChColors.accent2
            : done
            ? ChColors.accent2N(100)
            : ChColors.surfaceSunken,
      ),
      child: done
          ? Icon(Icons.check, color: ChColors.accent2, size: context.rs(14))
          : Text(
              '$step',
              style: ChTextStyles.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : ChColors.bodyText,
              ),
            ),
    );
  }
}
