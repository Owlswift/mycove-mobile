import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';

/// Shown whenever a session is being restored silently (cold start, or
/// resuming from the background) while biometric unlock is enabled — see
/// AppNotifier._enterApp/refreshOnResume. Logging in with a password is
/// never routed through here, since typing the password already was the
/// authentication event.
class BiometricUnlockPage extends ConsumerStatefulWidget {
  const BiometricUnlockPage({super.key});

  @override
  ConsumerState<BiometricUnlockPage> createState() =>
      _BiometricUnlockPageState();
}

class _BiometricUnlockPageState extends ConsumerState<BiometricUnlockPage> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    await ref.read(appStateProvider.notifier).unlockWithBiometrics();
    if (mounted) setState(() => _authenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: context.rs(84),
                height: context.rs(84),
                decoration: const BoxDecoration(
                  color: ChColors.accent2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: context.rs(44),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock CommunityHub',
                style: ChTextStyles.heading(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Use Face ID or Touch ID to continue.',
                textAlign: TextAlign.center,
                style: ChTextStyles.body(
                  fontSize: 14,
                  color: ChColors.bodyText,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _authenticating ? null : _unlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChColors.accent2,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ChRadii.button),
                    ),
                  ),
                  child: _authenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Try Again',
                          style: ChTextStyles.body(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(appStateProvider.notifier).logout(),
                child: Text(
                  'Log Out',
                  style: ChTextStyles.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ChColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
