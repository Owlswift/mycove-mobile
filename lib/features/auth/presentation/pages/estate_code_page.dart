import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

/// Shown once, before login — this app is shared across estates, so a
/// fresh install needs to know which estate's backend data it's talking
/// to before a resident can even see a login form. Once validated, this
/// screen is skipped on every future launch (see AppNotifier._bootstrap).
class EstateCodePage extends ConsumerWidget {
  const EstateCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 40, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: ChColors.accentN(100), shape: BoxShape.circle),
                child: Icon(Icons.apartment_rounded, size: 26, color: ChColors.accentN(800)),
              ),
              const SizedBox(height: 20),
              Text('Find your estate', style: ChTextStyles.heading(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                "CommunityHub is used by multiple estates — enter the code your estate management shared with you to get started.",
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
              const SizedBox(height: 28),
              ChTextField(
                label: 'Estate code',
                value: s.estateCodeInput,
                onChanged: notifier.onEstateCodeChange,
                placeholder: 'e.g. PALM001',
              ),
              const SizedBox(height: 8),
              if (s.estateCodeError.isNotEmpty) ...[
                Text(s.estateCodeError, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                const SizedBox(height: 12),
              ],
              ChButton(
                label: 'Continue',
                onPressed: s.estateCodeLoading ? null : notifier.submitEstateCode,
                isLoading: s.estateCodeLoading,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: ChColors.surface, borderRadius: BorderRadius.circular(ChRadii.md)),
                child: Text(
                  "Don't have a code? Ask your estate administrator or management office — every estate on CommunityHub has one.",
                  style: ChTextStyles.body(fontSize: 12.5, color: ChColors.text.withValues(alpha: 0.65)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
