import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_button.dart';
import '../../../../core/widgets/ch_text_field.dart';
import '../../../../state/app_notifier.dart';

class ForceResetPage extends ConsumerWidget {
  const ForceResetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: ChColors.accent2, borderRadius: BorderRadius.circular(ChRadii.md)),
              ),
              const SizedBox(height: 16),
              Text('Welcome, ${s.currentUser?.first ?? ''}', style: ChTextStyles.heading(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                'This is your first login. Set a permanent password and complete your profile to continue.',
                style: ChTextStyles.body(fontSize: 14, color: ChColors.neutralN(600)),
              ),
              const SizedBox(height: 22),
              ChTextField(
                label: 'New password',
                value: s.newPass1,
                onChanged: notifier.onNewPass1,
                placeholder: 'New password',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ChTextField(
                label: 'Confirm password',
                value: s.newPass2,
                onChanged: notifier.onNewPass2,
                placeholder: 'Confirm password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Text(
                'YOUR PROFILE',
                style: ChTextStyles.body(fontSize: 11, fontWeight: FontWeight.w700, color: ChColors.neutralN(600))
                    .copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              ChTextField(
                label: 'Full name',
                value: s.setupFullName,
                onChanged: notifier.onSetupFullName,
                placeholder: 'Full name',
              ),
              const SizedBox(height: 12),
              ChTextField(
                label: 'House address',
                value: s.setupHouse,
                onChanged: notifier.onSetupHouse,
                placeholder: 'e.g. Block C, Flat 4',
              ),
              const SizedBox(height: 12),
              ChTextField(
                label: 'Email (optional)',
                value: s.setupEmail,
                onChanged: notifier.onSetupEmail,
                placeholder: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              ChTextField(
                label: 'Emergency contact name (optional)',
                value: s.setupEmergencyContactName,
                onChanged: notifier.onSetupEmergencyContactName,
                placeholder: 'Full name',
              ),
              const SizedBox(height: 12),
              ChTextField(
                label: 'Emergency contact phone (optional)',
                value: s.setupEmergencyContactPhone,
                onChanged: notifier.onSetupEmergencyContactPhone,
                placeholder: '0800 000 0000',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              ChTextField(
                label: 'Vehicle plate number(s) (optional)',
                value: s.setupVehiclePlates,
                onChanged: notifier.onSetupVehiclePlates,
                placeholder: 'e.g. LND 442 KJ, ABC 123 XY',
              ),
              const SizedBox(height: 18),
              if (s.resetMsg.isNotEmpty) ...[
                Text(s.resetMsg, style: ChTextStyles.body(fontSize: 13, color: ChColors.danger)),
                const SizedBox(height: 12),
              ],
              ChButton(
                label: 'Save & Continue',
                onPressed: s.isLoading ? null : notifier.completeForceReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
