import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_pin_boxes.dart';
import '../../../../state/app_notifier.dart';

const _pinLength = 4;

/// Gates a purchase behind biometrics and/or a transaction PIN — the single
/// place both voice-driven and tap-driven purchases authorize through (see
/// ResidentShell's `pendingAuthorizationFor` listener), so the security-
/// critical path only needs testing once. Never accepts a spoken PIN.
Future<bool> showAuthorizationSheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AuthorizationSheet(),
  );
  return result ?? false;
}

class _AuthorizationSheet extends ConsumerStatefulWidget {
  const _AuthorizationSheet();

  @override
  ConsumerState<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends ConsumerState<_AuthorizationSheet> {
  String _pin = '';
  String _confirmPin = '';
  bool _busy = false;
  String? _error;
  bool _biometricAutoFired = false;

  Future<void> _authenticateBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(appStateProvider.notifier).authenticateForPurchase();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = "Authentication wasn't completed.";
    });
  }

  Future<void> _submitVerifyPin() async {
    if (_pin.length != _pinLength || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final valid = await ref.read(appStateProvider.notifier).verifyTransactionPin(_pin);
    if (!mounted) return;
    if (valid) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _pin = '';
      _error = 'Incorrect PIN. Please try again.';
    });
  }

  Future<void> _submitSetPin() async {
    if (_pin.length != _pinLength || _confirmPin.length != _pinLength || _busy) return;
    if (_pin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _error = "PINs don't match. Please try again.";
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(appStateProvider.notifier).setTransactionPin(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = "Couldn't set your PIN. Please try again.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final hasBiometric = s.biometricAvailable && s.biometricEnabled;
    final hasPin = s.currentUser?.hasPin ?? false;
    final settingUpPin = !hasBiometric && !hasPin;

    // Auto-fire biometrics once on open, but PIN entry (below) is shown
    // alongside it from the start rather than hidden behind a "use PIN
    // instead" tap — either path is available immediately.
    if (hasBiometric && !_biometricAutoFired) {
      _biometricAutoFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticateBiometric());
    }

    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        padding: EdgeInsets.fromLTRB(context.rs(24), context.rs(24), context.rs(24), context.rs(28)),
        decoration: BoxDecoration(
          color: McColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: McColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: context.rs(20)),
            Icon(
              hasBiometric ? Icons.fingerprint : Icons.pin_outlined,
              size: context.rs(40),
              color: McColors.accent2,
            ),
            SizedBox(height: context.rs(12)),
            Text(
              settingUpPin ? 'Set up a transaction PIN' : 'Confirm this purchase',
              style: McTextStyles.heading(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.rs(6)),
            Text(
              _subtitle(hasBiometric: hasBiometric, hasPin: hasPin, settingUpPin: settingUpPin),
              style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
              textAlign: TextAlign.center,
            ),
            if (hasBiometric) ...[
              SizedBox(height: context.rs(20)),
              McButton(label: 'Try Again', onPressed: _busy ? null : _authenticateBiometric, isLoading: _busy),
            ],
            if (hasPin) ...[
              if (hasBiometric) ...[
                SizedBox(height: context.rs(20)),
                Row(
                  children: [
                    Expanded(child: Divider(color: McColors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(10)),
                      child: Text(
                        'or enter your PIN',
                        style: McTextStyles.body(fontSize: 12, color: McColors.bodyText),
                      ),
                    ),
                    Expanded(child: Divider(color: McColors.divider)),
                  ],
                ),
              ],
              SizedBox(height: context.rs(16)),
              McPinBoxes(
                length: _pinLength,
                value: _pin,
                obscureText: true,
                onChanged: (v) {
                  setState(() => _pin = v);
                  if (v.length == _pinLength) _submitVerifyPin();
                },
              ),
            ],
            if (settingUpPin) ...[
              SizedBox(height: context.rs(20)),
              Text('Enter PIN', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
              SizedBox(height: context.rs(8)),
              McPinBoxes(
                length: _pinLength,
                value: _pin,
                obscureText: true,
                onChanged: (v) => setState(() => _pin = v),
              ),
              SizedBox(height: context.rs(16)),
              Text('Confirm PIN', style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
              SizedBox(height: context.rs(8)),
              McPinBoxes(
                length: _pinLength,
                value: _confirmPin,
                obscureText: true,
                onChanged: (v) {
                  setState(() => _confirmPin = v);
                  if (v.length == _pinLength) _submitSetPin();
                },
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: context.rs(14)),
              Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger), textAlign: TextAlign.center),
            ],
            SizedBox(height: context.rs(16)),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: Text('Cancel', style: McTextStyles.body(fontSize: 14, color: McColors.bodyText)),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle({required bool hasBiometric, required bool hasPin, required bool settingUpPin}) {
    if (settingUpPin) return 'Set a 4-digit PIN to authorize this and future purchases.';
    if (hasBiometric && hasPin) return 'Use Face ID or Touch ID, or enter your 4-digit PIN below.';
    if (hasBiometric) return 'Use Face ID or Touch ID to continue.';
    return 'Enter your 4-digit transaction PIN to continue.';
  }
}
